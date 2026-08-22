import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'models.dart';
import 'storage_service.dart';
import 'services/routing_service.dart';
import 'services/bus_api_service.dart';
import 'services/kakao_routing_service.dart';
import 'services/kakao_local_service.dart';
import 'services/tmap_service.dart';

enum WidgetBarMode { main, stopDetail }

class AppProvider extends ChangeNotifier {
  final StorageService _storageService;
  final RoutingService _routingService = RoutingService();
  final BusApiService _busApiService = BusApiService();
  final KakaoRoutingService _kakaoRoutingService = KakaoRoutingService();
  final KakaoLocalService _kakaoLocalService = KakaoLocalService();
  final TmapService _tmapService = TmapService();

  AppProvider(this._storageService);

  // ── UI 상태 ──
  WidgetBarMode _barMode = WidgetBarMode.main;
  String? _selectedStopName;
  bool _isAnalyzing = false;
  bool _isServiceEnded = false;
  bool _shouldFitBounds = false;
  bool _isSearching = false;
  bool _isLoadingArrivals = false;
  int _selectedRouteIndex = 0;
  String? _errorMessage; // 💡 추가

  WidgetBarMode get barMode => _barMode;
  String? get selectedStopName => _selectedStopName;
  bool get isAnalyzing => _isAnalyzing;
  bool get isServiceEnded => _isServiceEnded;
  bool get shouldFitBounds => _shouldFitBounds;
  bool get isSearching => _isSearching;
  bool get isLoadingArrivals => _isLoadingArrivals;
  int get selectedRouteIndex => _selectedRouteIndex;
  String? get errorMessage => _errorMessage; // 💡 추가

  void setBarMode(WidgetBarMode mode) {
    _barMode = mode;
    notifyListeners();
  }

  // ── 지도 및 검색 상태 ──
  String _departLabel = '현재 위치';
  String _arriveLabel = '';
  List<MapPin> _pins = [MapPin(x: 162, y: 240, type: PinType.depart)];
  PinType? _mapPending;

  String get departLabel => _departLabel;
  String get arriveLabel => _arriveLabel;
  List<MapPin> get pins => _pins;
  PinType? get mapPending => _mapPending;

  // ── 데이터 리스트 ──
  List<BusRouteInfo> _recommendedRoutes = [];
  List<BusRouteInfo> _stopArrivals = [];
  List<Place> _favoritePlaces = [];
  List<RouteSegment> _routeSegments = [];
  List<BusStop> _allGwangjuStations = [];
  List<dynamic> _rawItineraries = [];
  List<Map<String, dynamic>> _searchResults = [];

  List<BusRouteInfo> get recommendedRoutes => _recommendedRoutes;
  List<BusRouteInfo> get stopArrivals => _stopArrivals;
  List<Place> get favoritePlaces => _favoritePlaces;
  List<RouteSegment> get routeSegments => _routeSegments;
  List<Map<String, dynamic>> get searchResults => _searchResults;

  // ── 메서드 ──

  void setDepartLabel(String label, {double? lat, double? lng}) {
    _departLabel = label;
    if (lat != null && lng != null) {
      _pins = [
        ..._pins.where((p) => p.type != PinType.depart),
        MapPin(x: lat, y: lng, type: PinType.depart)
      ];
    }
    if (_arriveLabel.isNotEmpty) {
      _triggerAnalysis();
    }
    notifyListeners();
  }

  Future<void> _triggerAnalysis() async {
    final arrivePin = _pins.firstWhere((p) => p.type == PinType.arrive, orElse: () => MapPin(x: 0, y: 0, type: PinType.arrive));
    if (arrivePin.x == 0) return;
    
    final departPin = _pins.firstWhere((p) => p.type == PinType.depart);
    _isAnalyzing = true;
    _isServiceEnded = false;
    _errorMessage = null; // 초기화
    notifyListeners();

    final tmapData = await _tmapService.getTransitRoute(
      LatLng(departPin.x, departPin.y), 
      LatLng(arrivePin.x, arrivePin.y)
    );

    if (tmapData != null) {
      final Map<String, dynamic> parsed = _tmapService.parseTmapData(tmapData);
      
      _errorMessage = parsed['errorMessage']; // 💡 에러 메시지 획득
      _rawItineraries = parsed['rawItineraries'] ?? [];
      _recommendedRoutes = List<BusRouteInfo>.from(parsed['busRoutes'] ?? []);
      
      if (_rawItineraries.isNotEmpty) {
        selectRoute(0, notify: false);
      }
      
      if (_recommendedRoutes.isEmpty) {
        _isServiceEnded = true;
      }
      _shouldFitBounds = true;
    } else {
      _errorMessage = '데이터를 불러올 수 없습니다.';
      _recommendedRoutes = [];
      _routeSegments = [];
      _isServiceEnded = true;
    }
    _isAnalyzing = false;
    notifyListeners();
  }

  void setArriveLabel(String label, {double? lat, double? lng}) async {
    _arriveLabel = label;
    double targetLat = lat ?? 0;
    double targetLng = lng ?? 0;

    if (targetLat == 0) {
      final selectedPlace = _favoritePlaces.firstWhere((p) => p.name == label, 
        orElse: () => Place(id: '0', name: '', lat: 0, lng: 0, address: ''));
      targetLat = selectedPlace.lat;
      targetLng = selectedPlace.lng;
    }
      
    if (targetLat != 0) {
      _pins = [
        ..._pins.where((p) => p.type != PinType.arrive),
        MapPin(x: targetLat, y: targetLng, type: PinType.arrive)
      ];
      _triggerAnalysis();
    }
    notifyListeners();
  }

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    try {
      _searchResults = await _kakaoLocalService.searchKeywords(query);
    } catch (e) {
      debugPrint('❌ [Search] 검색 실패: $e');
    }
    _isSearching = false;
    notifyListeners();
  }

  Future<void> fetchStopArrivalInfo(double lat, double lng) async {
    _isLoadingArrivals = true;
    _stopArrivals = [];
    _barMode = WidgetBarMode.stopDetail;
    notifyListeners();

    try {
      final stop = _findClosestRealStop(lat, lng);
      _selectedStopName = stop.name;
      final arrivals = await _busApiService.getArrivalInfo(stop.id);
      _stopArrivals = List<BusRouteInfo>.from(arrivals);
    } catch (e) {
      debugPrint('❌ [StopInfo] 정보 조회 실패: $e');
    }

    _isLoadingArrivals = false;
    notifyListeners();
  }

  void resetFitBounds() {
    _shouldFitBounds = false;
  }

  Future<void> loadFavoritePlaces() async {
    _favoritePlaces = await _storageService.getFavoritePlaces();
    _allGwangjuStations = await _storageService.getAllStations();
    if (_allGwangjuStations.isEmpty) {
      _allGwangjuStations = await _busApiService.fetchAllGwangjuStations();
      await _storageService.saveAllStations(_allGwangjuStations);
    }
    const double schoolLat = 35.1403165;
    const double schoolLng = 126.9355550;
    final index = _favoritePlaces.indexWhere((p) => p.name == '학교');
    if (index != -1) {
      _favoritePlaces[index] = Place(id: _favoritePlaces[index].id, name: '학교', lat: schoolLat, lng: schoolLng, address: '광주광역시 동구 필문대로 309');
    }
    notifyListeners();
  }

  BusStop _findClosestRealStop(double lat, double lng) {
    if (_allGwangjuStations.isEmpty) {
      return BusStop(id: '2106', name: '조선대 정문', lat: 35.1430, lng: 126.9341);
    }
    BusStop closest = _allGwangjuStations[0];
    double minDistance = double.infinity;
    for (var stop in _allGwangjuStations) {
      double dist = (stop.lat - lat) * (stop.lat - lat) + (stop.lng - lng) * (stop.lng - lng);
      if (dist < minDistance) {
        minDistance = dist;
        closest = stop;
      }
    }
    return closest;
  }

  void updateDepartLocation(double lat, double lng) {
    _pins = [
      ..._pins.where((p) => p.type != PinType.depart),
      MapPin(x: lat, y: lng, type: PinType.depart)
    ];
    _departLabel = '현재 위치';
    notifyListeners();
  }

  Future<void> updateDefaultPlacesWithLocation(double lat, double lng) async {
    bool changed = false;
    for (int i = 0; i < _favoritePlaces.length; i++) {
      if (_favoritePlaces[i].name != '학교') {
        _favoritePlaces[i] = Place(
          id: _favoritePlaces[i].id,
          name: _favoritePlaces[i].name,
          lat: lat,
          lng: lng,
          address: '현재 위치 주변',
        );
        changed = true;
      }
    }
    if (changed) {
      await _storageService.saveFavoritePlaces(_favoritePlaces);
      notifyListeners();
    }
  }

  void selectRoute(int index, {bool notify = true}) {
    if (index < 0 || index >= _rawItineraries.length) return;
    _selectedRouteIndex = index;
    final pathData = _tmapService.parseItineraryPath(_rawItineraries[index]);
    _routeSegments = pathData['segments'];
    final List<Map<String, dynamic>> stops = pathData['stops'];
    _pins = [
      ..._pins.where((p) => p.type != PinType.busStop),
      ...stops.map((s) {
        final LatLng ll = s['latlng'];
        return MapPin(x: ll.latitude, y: ll.longitude, type: PinType.busStop, address: s['type']);
      }),
    ];
    _shouldFitBounds = true;
    if (notify) notifyListeners();
  }

  // ── 루틴 및 프로필 (기존 유지) ──
  List<Routine> _routines = [];
  bool _isLoadingRoutines = true;
  String _selectedDay = '화';
  List<Routine> get routines => _routines;
  bool get isLoadingRoutines => _isLoadingRoutines;
  String get selectedDay => _selectedDay;

  Future<void> loadRoutines() async {
    _isLoadingRoutines = true;
    notifyListeners();
    _routines = await _storageService.getRoutines();
    _isLoadingRoutines = false;
    notifyListeners();
  }

  void toggleRoutine(int id) {
    final index = _routines.indexWhere((r) => r.id == id);
    if (index != -1) {
      _routines[index].enabled = !_routines[index].enabled;
      _storageService.saveRoutines(_routines);
      notifyListeners();
    }
  }

  void setSelectedDay(String day) {
    _selectedDay = day;
    notifyListeners();
  }

  String _userName = '루틴버스 사용자';
  bool _darkMode = false;
  bool _notifOn = true;
  String get userName => _userName;
  bool get darkMode => _darkMode;
  bool get notifOn => _notifOn;

  Future<void> loadProfile() async {
    _userName = await _storageService.getUserName();
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    _storageService.setUserName(name);
    notifyListeners();
  }

  void setDarkMode(bool val) {
    _darkMode = val;
    notifyListeners();
  }

  void setNotifOn(bool val) {
    _notifOn = val;
    notifyListeners();
  }
}
