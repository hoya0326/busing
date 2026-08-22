import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart'; // 💡 추가
import 'models.dart';
import 'storage_service.dart';
import 'services/routing_service.dart';
import 'services/bus_api_service.dart';
import 'services/kakao_routing_service.dart';
import 'services/kakao_local_service.dart';
import 'services/tmap_service.dart'; // 💡 추가

class AppProvider extends ChangeNotifier {
  final StorageService _storageService;
  final RoutingService _routingService = RoutingService();
  final BusApiService _busApiService = BusApiService();
  final KakaoRoutingService _kakaoRoutingService = KakaoRoutingService();
  final KakaoLocalService _kakaoLocalService = KakaoLocalService();
  final TmapService _tmapService = TmapService(); // 💡 추가

  AppProvider(this._storageService);

  // ── 지도 및 검색 상태 ──
  String _departLabel = '현재 위치';
  String _arriveLabel = '';
  List<MapPin> _pins = [MapPin(x: 162, y: 240, type: PinType.depart)];
  PinType? _mapPending;

  String get departLabel => _departLabel;
  String get arriveLabel => _arriveLabel;
  List<MapPin> get pins => _pins;
  PinType? get mapPending => _mapPending;

  // ── 실시간 경로 분석 데이터 ──
  List<BusRouteInfo> _recommendedRoutes = [];
  bool _isAnalyzing = false;
  bool _isServiceEnded = false;
  List<Place> _favoritePlaces = []; // 💡 추가 (누락됨)
  List<RouteSegment> _routeSegments = [];
  List<BusStop> _allGwangjuStations = [];
  bool _shouldFitBounds = false;

  List<BusRouteInfo> get recommendedRoutes => _recommendedRoutes;
  bool get isAnalyzing => _isAnalyzing;
  bool get isServiceEnded => _isServiceEnded;
  List<Place> get favoritePlaces => _favoritePlaces;
  List<RouteSegment> get routeSegments => _routeSegments;
  bool get shouldFitBounds => _shouldFitBounds; // Getter

  // 자동 줌 완료 후 상태 초기화
  void resetFitBounds() {
    _shouldFitBounds = false;
  }

  // 장소 데이터 로드 및 정류소 DB 초기화
  Future<void> loadFavoritePlaces() async {
    _favoritePlaces = await _storageService.getFavoritePlaces();
    
    // 💡 수석 개발자: 정류소 마스터 DB 로드 및 분석
    _allGwangjuStations = await _storageService.getAllStations();
    if (_allGwangjuStations.isEmpty) {
      debugPrint('📂 [Init] 광주 정류소 데이터를 최초 분석합니다 (네트워크 필요)...');
      _allGwangjuStations = await _busApiService.fetchAllGwangjuStations();
      await _storageService.saveAllStations(_allGwangjuStations);
      debugPrint('📂 [Init] 광주 정류소 ${_allGwangjuStations.length}개 분석 완료 및 캐싱됨.');
    } else {
      debugPrint('📂 [Init] 로컬 캐시에서 ${_allGwangjuStations.length}개의 정류소를 불러왔습니다.');
    }
    
    // 💡 '학교' 버튼 좌표 보정 (기존 로직 유지)
    const double schoolLat = 35.1403165;
    const double schoolLng = 126.9355550;
    final index = _favoritePlaces.indexWhere((p) => p.name == '학교');
    if (index != -1) {
      _favoritePlaces[index] = Place(id: _favoritePlaces[index].id, name: '학교', lat: schoolLat, lng: schoolLng, address: '광주광역시 동구 필문대로 309');
    }
    
    notifyListeners();
  }

  // 💡 수석 개발자 핵심 알고리즘: 특정 좌표에서 가장 가까운 실제 정류소 찾기
  BusStop _findClosestRealStop(double lat, double lng) {
    if (_allGwangjuStations.isEmpty) {
      return BusStop(id: '2106', name: '조선대 정문', lat: 35.1430, lng: 126.9341);
    }
    
    BusStop closest = _allGwangjuStations[0];
    double minDistance = double.infinity;
    
    for (var stop in _allGwangjuStations) {
      // 위경도 차이의 제곱합으로 단순 거리 비교 (성능 최우선)
      double dist = (stop.lat - lat) * (stop.lat - lat) + (stop.lng - lng) * (stop.lng - lng);
      if (dist < minDistance) {
        minDistance = dist;
        closest = stop;
      }
    }
    return closest;
  }

  // 💡 수석 개발자 수정: '학교' 좌표를 보호하면서 나머지 장소만 현재 위치로 보정
  Future<void> updateDefaultPlacesWithLocation(double lat, double lng) async {
    bool changed = false;
    for (int i = 0; i < _favoritePlaces.length; i++) {
      // '학교'가 아닌 경우에만 현재 위치로 보정합니다.
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

  // 장소 추가 (시연용)
  Future<void> addFavoritePlace(Place place) async {
    _favoritePlaces.add(place);
    await _storageService.saveFavoritePlaces(_favoritePlaces);
    notifyListeners();
  }

  void setDepartLabel(String label) {
    _departLabel = label;
    _runRouteAnalysis();
    notifyListeners();
  }

  void setArriveLabel(String label) async {
    _arriveLabel = label;
    
    final selectedPlace = _favoritePlaces.firstWhere((p) => p.name == label, 
      orElse: () => Place(id: '0', name: '', lat: 0, lng: 0, address: ''));
      
    if (selectedPlace.name.isNotEmpty) {
      final departPin = _pins.firstWhere((p) => p.type == PinType.depart);
      
      _pins = [
        ..._pins.where((p) => p.type != PinType.arrive),
        MapPin(x: selectedPlace.lat, y: selectedPlace.lng, type: PinType.arrive)
      ];

      _isAnalyzing = true;
      _isServiceEnded = false;
      notifyListeners();

      // 💡 수석 개발자: Tmap API 단일 호출로 모든 데이터 획득
      final tmapData = await _tmapService.getTransitRoute(
        LatLng(departPin.x, departPin.y), 
        LatLng(selectedPlace.lat, selectedPlace.lng)
      );

      if (tmapData != null) {
        final Map<String, dynamic> parsed = _tmapService.parseTmapData(tmapData);
        
        // 1. 지도 경로 및 정류소 마커 업데이트
        _routeSegments = parsed['segments'];
        final List<LatLng> stops = parsed['stops'];
        _pins = [
          ..._pins.where((p) => p.type != PinType.busStop),
          ...stops.map((s) => MapPin(x: s.latitude, y: s.longitude, type: PinType.busStop)),
        ];

        // 2. 버스 노선 정보 리스트 업데이트
        _recommendedRoutes = parsed['busRoutes'];
        
        if (_recommendedRoutes.isEmpty) {
          _isServiceEnded = true;
        }

        debugPrint('🎯 [Tmap] 엔진으로부터 ${_recommendedRoutes.length}개의 버스 정보 획득 완료');
        _shouldFitBounds = true; // 💡 줌 조절 트리거 활성화
      } else {
        // Tmap API 실패 시 시뮬레이션
        _createSimulatedPath(departPin, selectedPlace);
        _recommendedRoutes = await _routingService.analyzeRoutes(departLabel: _departLabel, arriveLabel: _arriveLabel);
      }
      
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void _createSimulatedPath(MapPin depart, Place dest) {
    const double stationLat = 35.1430;
    const double stationLng = 126.9341;
    final boardingStop = LatLng(stationLat, stationLng);
    
    _routeSegments = [
      RouteSegment(points: [LatLng(depart.x, depart.y), boardingStop], color: const Color(0xFF10B981), width: 8.0),
      RouteSegment(points: [boardingStop, LatLng(35.1415, 126.9350), LatLng(35.1408, 126.9355), LatLng(dest.lat, dest.lng)], color: const Color(0xFF2563EB), width: 10.0),
    ];
    _pins = [
      ..._pins.where((p) => p.type != PinType.busStop),
      MapPin(x: stationLat, y: stationLng, type: PinType.busStop),
    ];
  }

  void setMapPending(PinType? type) {
    _mapPending = type;
    notifyListeners();
  }

  void updateDepartLocation(double lat, double lng) {
    _pins = [
      ..._pins.where((p) => p.type != PinType.depart),
      MapPin(x: lat, y: lng, type: PinType.depart)
    ];
    _departLabel = '현재 위치';
    notifyListeners();
  }

  void handleMapTap(double x, double y) {
    if (_mapPending == null) return;
    _pins = [..._pins.where((p) => p.type != _mapPending), MapPin(x: x, y: y, type: _mapPending!)];
    if (_mapPending == PinType.depart) {
      _departLabel = '지도에서 선택한 위치';
    } else {
      _arriveLabel = '지도에서 선택한 위치';
    }
    _mapPending = null;
    notifyListeners();
  }

  void clearArrival() {
    _arriveLabel = '';
    _pins = _pins.where((p) => p.type != PinType.arrive).toList();
    _recommendedRoutes = [];
    notifyListeners();
  }

  Future<void> _runRouteAnalysis() async {}

  // ── 루틴 관리 상태 ──
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

  // ── 프로필 관리 상태 ──
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
