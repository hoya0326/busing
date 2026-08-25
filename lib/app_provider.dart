import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart'; // 💡 거리 계산을 위해 추가
import 'models.dart';
import 'data/bus_schedules.dart'; // 💡 추가
import 'storage_service.dart';
import 'services/routing_service.dart';
import 'services/bus_api_service.dart';
import 'services/kakao_routing_service.dart';
import 'services/kakao_local_service.dart';
import 'services/tmap_service.dart';
import 'usecases/register_alarm_usecase.dart'; // 💡 추가
import 'services/toast_service.dart'; // 💡 추가

enum WidgetBarMode { main, stopDetail }

// 💡 Atcha의 HomeViewModel.State 포팅
class HomeState {
  final bool isAnalyzing;
  final List<BusRouteInfo> routes;
  final List<MapPin> pins;
  final List<RouteSegment> routeSegments;
  final String? errorMessage;
  final bool isNearDestination;
  final WidgetBarMode barMode;
  final String? activeScheduleBusName; 
  final List<MapPin>? backupPins; // 💡 원래 핀 백업
  final List<RouteSegment>? backupSegments; // 💡 원래 경로 백업

  HomeState({
    this.isAnalyzing = false,
    this.routes = const [],
    this.pins = const [],
    this.routeSegments = const [],
    this.errorMessage,
    this.isNearDestination = false,
    this.barMode = WidgetBarMode.main,
    this.activeScheduleBusName,
    this.backupPins,
    this.backupSegments,
  });

  HomeState copyWith({
    bool? isAnalyzing,
    List<BusRouteInfo>? routes,
    List<MapPin>? pins,
    List<RouteSegment>? routeSegments,
    String? errorMessage,
    bool? isNearDestination,
    WidgetBarMode? barMode,
    String? activeScheduleBusName,
    List<MapPin>? backupPins,
    List<RouteSegment>? backupSegments,
    bool clearBackup = false,
  }) {
    return HomeState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      routes: routes ?? this.routes,
      pins: pins ?? this.pins,
      routeSegments: routeSegments ?? this.routeSegments,
      errorMessage: errorMessage ?? this.errorMessage,
      isNearDestination: isNearDestination ?? this.isNearDestination,
      barMode: barMode ?? this.barMode,
      // 💡 [수석 개발자] null 전달 시 실제 null로 세팅될 수 있도록 로직 보정
      activeScheduleBusName: clearBackup ? null : (activeScheduleBusName ?? this.activeScheduleBusName),
      backupPins: clearBackup ? null : (backupPins ?? this.backupPins),
      backupSegments: clearBackup ? null : (backupSegments ?? this.backupSegments),
    );
  }
}

class AppProvider extends ChangeNotifier {
  final StorageService _storageService;
  final RoutingService _routingService = RoutingService();
  final BusApiService _busApiService = BusApiService();
  final KakaoRoutingService _kakaoRoutingService = KakaoRoutingService();
  final KakaoLocalService _kakaoLocalService = KakaoLocalService();
  final TmapService _tmapService = TmapService();
  final RegisterAlarmUseCase _registerAlarmUseCase = RegisterAlarmUseCase(); // 💡 추가

  BusApiService get busApiService => _busApiService; // 💡 서비스 접근을 위해 추가

  AppProvider(this._storageService) {
    // 💡 초기 상태 설정
    _state = HomeState(
      pins: [MapPin(x: 35.1601, y: 126.8515, type: PinType.depart)]
    );
  }

  HomeState _state = HomeState();
  HomeState get state => _state;

  List<Place> _favoritePlaces = [];
  List<BusRouteInfo> _stopArrivals = [];
  List<dynamic> _rawItineraries = [];
  List<BusStop> _allGwangjuStations = [];
  List<Map<String, dynamic>> _searchResults = [];

  String _departLabel = '현재 위치';
  String _arriveLabel = '';
  String? _selectedStopName;
  bool _isServiceEnded = false;
  bool _shouldFitBounds = false;
  bool _isSearching = false;
  bool _isLoadingArrivals = false;
  int _selectedRouteIndex = 0;
  int _analysisCount = 0; 
  LatLng? _currentSelectedStopLatLng;

  // 헬퍼 게터들
  WidgetBarMode get barMode => _state.barMode;
  bool get isAnalyzing => _state.isAnalyzing;
  bool get isNearDestination => _state.isNearDestination;
  List<BusRouteInfo> get recommendedRoutes => _state.routes;
  List<MapPin> get pins => _state.pins;
  List<RouteSegment> get routeSegments => _state.routeSegments; // 💡 게터 수정
  String? get errorMessage => _state.errorMessage;

  // 💡 [추가] HomeScreen에서 사용하는 나머지 게터들 복구
  String get departLabel => _departLabel;
  String get arriveLabel => _arriveLabel;
  List<Place> get favoritePlaces => _favoritePlaces;
  bool get shouldFitBounds => _shouldFitBounds;
  int get selectedRouteIndex => _selectedRouteIndex;
  String? get selectedStopName => _selectedStopName;
  bool get isLoadingArrivals => _isLoadingArrivals;
  List<BusRouteInfo> get stopArrivals => _stopArrivals;
  bool get isSearching => _isSearching;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  bool get isServiceEnded => _isServiceEnded;
  
  // 상태 변경 및 알림 최적화
  void _updateState(HomeState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void setBarMode(WidgetBarMode mode) {
    _updateState(_state.copyWith(barMode: mode));
  }

  /// 💡 [Request] 실시간 정보 새로고침
  Future<void> refreshCurrentView() async {
    if (_state.barMode == WidgetBarMode.stopDetail && _currentSelectedStopLatLng != null) {
      // 정류장 상세 화면이면 해당 정류장 정보 다시 불러오기
      await fetchStopArrivalInfo(_currentSelectedStopLatLng!.latitude, _currentSelectedStopLatLng!.longitude);
    } else if (_arriveLabel.isNotEmpty) {
      // 메인 화면이면 전체 경로 다시 분석
      await _triggerAnalysis();
    }
  }

  /// 💡 [Request] 현재 활성화된 경로 검색 취소 및 상태 초기화
  void clearCurrentRoute() {
    debugPrint('🧹 [Provider] 모든 경로 데이터 및 마커 청소');
    
    _arriveLabel = '';
    _departLabel = '현재 위치'; // 💡 출발지 라벨도 현재 위치로 초기화
    _selectedRouteIndex = 0;
    _isServiceEnded = false;
    _analysisCount++; // 이전 분석 세션 무효화
    
    // 상태 초기화: 분석 중 아님, 경로 없음, 마커 청소 (현재 위치 핀만 유지)
    final currentDepartPin = _state.pins.firstWhere(
      (p) => p.type == PinType.depart, 
      orElse: () => MapPin(x: 35.1601, y: 126.8515, type: PinType.depart)
    );

    _updateState(HomeState(
      isAnalyzing: false,
      routes: [],
      routeSegments: [],
      pins: [currentDepartPin], 
      errorMessage: null,
      barMode: WidgetBarMode.main,
      // 💡 [수정] HomeState 생성 시 백업 필드를 비워둠으로써 청소 효과를 냄
    ));
    
    notifyListeners();
  }

  // ── 메서드 ──

  void setDepartLabel(String label, {double? lat, double? lng}) {
    _departLabel = label;
    if (lat != null && lng != null) {
      final newPins = [
        ..._state.pins.where((p) => p.type != PinType.depart),
        MapPin(x: lat, y: lng, type: PinType.depart)
      ];
      _updateState(_state.copyWith(pins: newPins));
    }
    if (_arriveLabel.isNotEmpty) {
      _triggerAnalysis();
    }
  }

  Future<void> _triggerAnalysis() async {
    final arrivePin = _state.pins.firstWhere((p) => p.type == PinType.arrive, orElse: () => MapPin(x: 0, y: 0, type: PinType.arrive));
    if (arrivePin.x == 0) return;
    
    final departPin = _state.pins.firstWhere((p) => p.type == PinType.depart);
    final currentSession = ++_analysisCount;
    
    // 💡 분석 시작 시 이전 버스 정류장들만 제거 (출발/도착지는 유지)
    final currentPins = List<MapPin>.from(_state.pins);
    currentPins.removeWhere((p) => p.type == PinType.busStop);

    _updateState(_state.copyWith(
      isAnalyzing: true,
      errorMessage: null,
      routes: [],
      routeSegments: [], // 💡 추가됨
      pins: currentPins,
    ));

    final tmapData = await _tmapService.getTransitRoute(
      LatLng(departPin.x, departPin.y), 
      LatLng(arrivePin.x, arrivePin.y)
    );

    if (currentSession != _analysisCount) return;

    if (tmapData != null) {
      final Map<String, dynamic> parsed = _tmapService.parseTmapData(tmapData);
      final List<BusRouteInfo> newRoutes = List<BusRouteInfo>.from(parsed['busRoutes'] ?? []);
      _rawItineraries = parsed['rawItineraries'] ?? [];
      
      _updateState(_state.copyWith(
        routes: newRoutes,
        errorMessage: parsed['errorMessage'],
      ));

      await _enrichRecommendedRoutes(currentSession);
      
      if (currentSession != _analysisCount) return;

      if (_rawItineraries.isNotEmpty) {
        unawaited(selectRoute(0, notify: false)); // 💡 비동기 호출로 변경
      }
      
      _shouldFitBounds = true;
    } else {
      _updateState(_state.copyWith(
        errorMessage: '데이터를 불러올 수 없습니다.',
        routes: [],
        isAnalyzing: false,
      ));
    }
    _updateState(_state.copyWith(isAnalyzing: false));
  }

  Future<void> _enrichRecommendedRoutes(int session) async {
    if (_state.routes.isEmpty) return;

    // 1. 중복 요청 방지를 위해 고유한 정류장 세트 추출
    final Map<String, List<BusRouteInfo>> stopGroups = {};
    for (var route in _state.routes) {
      if (route.busName == '도보' || route.startStopName == null) continue;
      stopGroups.putIfAbsent(route.startStopName!, () => []).add(route);
    }

    debugPrint('⚡ [Enrich] 보정 프로세스 시작 (그룹: ${stopGroups.length}개)');

    // 2. 모든 정류장의 정보를 병렬(Parallel)로 가져오기
    await Future.wait(stopGroups.entries.map((entry) async {
      // 💡 [최적화] 각 비동기 단계마다 세션 유효성 즉시 체크
      if (session != _analysisCount) return; 

      final stopName = entry.key;
      final routesInStop = entry.value;
      
      try {
        final firstRoute = routesInStop.first;
        final stopInfo = await _busApiService.getStationByNameOrCoords(
          name: stopName,
          lat: firstRoute.startStopLatLng?.latitude,
          lng: firstRoute.startStopLatLng?.longitude,
        );

        if (session != _analysisCount) return;

        if (stopInfo != null) {
          final currentDepartPin = _state.pins.firstWhere((p) => p.type == PinType.depart);
          // 💡 [수석 개발자] 도보 시간 정밀 보정 추가 (Pedestrian API 활용)
          int realWalkTime = firstRoute.walkTimeRemaining;
          try {
            realWalkTime = await _tmapService.getWalkingDuration(
              LatLng(currentDepartPin.x, currentDepartPin.y),
              firstRoute.startStopLatLng ?? LatLng(0,0),
            );
          } catch (e) {
            debugPrint('⚠️ [Enrich] 도보 시간 보정 실패: $e');
          }

          // 💡 [개선] 특정 노선(예: 30번) 정보를 우선적으로 가져오기 위해 targetBusName 전달
          final arrivals = await _busApiService.getArrivalInfo(
            stopInfo['id'], 
            stopName: stopName,
            targetBusName: firstRoute.busName, 
          );
          
          if (session != _analysisCount) return;

          for (var route in routesInStop) {
            // 💡 [수석 개발자] 실시간 도착 정보와 관계없이 도보 시간은 항상 정밀 보정치 적용
            route.walkTimeRemaining = realWalkTime;

            final cleanBusName = route.busName.replaceAll(RegExp(r'[^0-9]'), '');
            final match = arrivals.firstWhere(
              (a) {
                final aClean = a.busName.replaceAll(RegExp(r'[^0-9]'), '');
                return aClean == cleanBusName || a.busName.contains(route.busName) || route.busName.contains(a.busName);
              },
              orElse: () => BusRouteInfo(
                busName: '', busArrivalRemaining: -1, walkTimeRemaining: 0, travelDuration: 0, totalDuration: 0, routeDescription: ''
              )
            );

            if (match.busArrivalRemaining != -1) {
              route.busArrivalRemaining = match.busArrivalRemaining;
            } else if (arrivals.any((a) => a.busArrivalRemaining == -2)) {
              // 💡 만약 API에서 '운행 종료(-2)'를 반환했다면 해당 상태 반영
              route.busArrivalRemaining = -2;
            }
            route.updateCalculatedFields();
          }
        }
      } catch (e) {
        debugPrint('⚠️ [Enrich] 정류장 보정 실패: $e');
      }
    }));
    
    if (session == _analysisCount) {
      debugPrint('✅ [Enrich] 세션($session) 보정 완료 및 UI 갱신');
      _updateState(_state.copyWith()); 
    }
  }

  void setArriveLabel(String label, {double? lat, double? lng}) async {
    _arriveLabel = label;
    double targetLat = lat ?? 0;
    double targetLng = lng ?? 0;

    // 💡 [수석 개발자] 기존 목적지 및 정류장 핀들을 선제적으로 제거하여 잔상 방지
    final cleanedPins = _state.pins.where((p) => p.type != PinType.arrive && p.type != PinType.busStop).toList();

    late Place selectedPlace;
    if (targetLat == 0) {
      selectedPlace = _favoritePlaces.firstWhere((p) => p.name == label, 
        orElse: () => Place(id: '0', name: '', lat: 0, lng: 0, address: ''));
      targetLat = selectedPlace.lat;
      targetLng = selectedPlace.lng;
    } else {
      selectedPlace = Place(id: 'temp', name: label, lat: targetLat, lng: targetLng, address: '');
    }
      
    if (targetLat != 0) {
      // 💡 [Request 8] 최근 검색어 저장 (Atcha 자가 치유 로직 포함)
      unawaited(_storageService.saveRecentSearch(selectedPlace));

      cleanedPins.add(MapPin(x: targetLat, y: targetLng, type: PinType.arrive));
      _updateState(_state.copyWith(pins: cleanedPins));
      _triggerAnalysis();
    }
  }

  void resetFitBounds() {
    _shouldFitBounds = false;
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
    debugPrint('📡 [Provider] fetchStopArrivalInfo 시작: $lat, $lng');
    _currentSelectedStopLatLng = LatLng(lat, lng); 
    _isLoadingArrivals = true;
    _stopArrivals = [];
    _updateState(_state.copyWith(barMode: WidgetBarMode.stopDetail));

    try {
      final stop = _findClosestRealStop(lat, lng);
      debugPrint('📍 [Provider] 정류장 매핑 시도: ${stop.name} (${stop.id})');
      _selectedStopName = stop.name;
      
      // 💡 [개선] 현재 선택된 경로의 버스 번호를 타겟으로 전달하여 실시간 정보 우선 확보
      String? targetBus;
      if (_state.routes.isNotEmpty && _selectedRouteIndex < _state.routes.length) {
        targetBus = _state.routes[_selectedRouteIndex].busName;
      }

      final arrivals = await _busApiService.getArrivalInfo(
        stop.id, 
        stopName: stop.name,
        targetBusName: targetBus,
      );
      
      // 💡 [수석 개발자] 환승 노선 인지형 소팅 알고리즘 적용
      // 현재 선택된 경로의 '구간별 버스'를 분석하여 클릭한 정류장에 맞는 버스를 최상단으로 올립니다.
      if (_state.routes.isNotEmpty && _selectedRouteIndex < _state.routes.length) {
        final currentRoute = _state.routes[_selectedRouteIndex];
        String? targetBusName;
        
        for (var leg in currentRoute.legs) {
          if (leg.mode == TransportMode.bus && leg.startStopName != null) {
            // 정류장 명칭 매칭 (환승 정류장 인지)
            if (stop.name.contains(leg.startStopName!) || leg.startStopName!.contains(stop.name)) {
              targetBusName = leg.routeName;
              break;
            }
          }
        }

        targetBusName ??= currentRoute.busName;
        final cleanTarget = targetBusName.replaceAll(RegExp(r'[^0-9]'), '');
        
        arrivals.sort((a, b) {
          final aClean = a.busName.replaceAll(RegExp(r'[^0-9]'), '');
          final bClean = b.busName.replaceAll(RegExp(r'[^0-9]'), '');
          
          bool aMatch = aClean == cleanTarget || a.busName.contains(targetBusName!);
          bool bMatch = bClean == cleanTarget || b.busName.contains(targetBusName!);
          
          if (aMatch && !bMatch) return -1;
          if (!aMatch && bMatch) return 1;
          return 0;
        });
      }
      
      debugPrint('🚌 [Provider] 도착 정보 수신 완료: ${arrivals.length}개 노선');
      _stopArrivals = List<BusRouteInfo>.from(arrivals);
    } catch (e) {
      debugPrint('❌ [StopInfo] 정보 조회 실패: $e');
    }

    _isLoadingArrivals = false;
    _updateState(_state.copyWith()); 
  }

  /// 💡 [Request] 임시 목적지 강조 표시 및 노선 미리보기 (원래 경로 백업)
  Future<void> setHighlightMarker(double lat, double lng, String label, {String? busName}) async {
    // 💡 [수석 개발자] 이미 미리보기 모드라면 추가 백업을 하지 않음 (중요)
    final bool alreadyPreviewing = _state.backupPins != null;
    
    final List<MapPin> originalPins = alreadyPreviewing ? _state.backupPins! : List<MapPin>.from(_state.pins);
    final List<RouteSegment> originalSegments = alreadyPreviewing ? _state.backupSegments! : List<RouteSegment>.from(_state.routeSegments);
    
    final highlightPin = MapPin(x: lat, y: lng, type: PinType.passStop, label: label, address: 'highlight');

    // 1. UI 즉시 업데이트 (기존 경로 숨김 + 강조 마커 표시)
    _updateState(_state.copyWith(
      pins: [highlightPin], 
      routeSegments: [],    
      activeScheduleBusName: busName,
      backupPins: originalPins,
      backupSegments: originalSegments,
    ));

    // 2. 노선 경로(Full Line Path) 비동기 조회
    if (busName != null) {
      debugPrint('📡 [Preview] $busName 노선 경로 조회 시작 (Tmap)...');
      // 💡 [수석 개발자] 광주 BIS 대신 더 정밀하고 안정적인 Tmap 데이터 엔진으로 교체
      final pathPoints = await _tmapService.getBusLinePath(busName);
      
      // 아직 미리보기 모드인지 확인 후 업데이트
      if (_state.activeScheduleBusName == busName) {
        if (pathPoints.isNotEmpty) {
          final lineSegment = RouteSegment(
            id: 'line_preview_${busName}_${DateTime.now().millisecondsSinceEpoch}',
            points: pathPoints,
            color: const Color(0xFF2563EB),
            width: 7.0,
          );
          
          _updateState(_state.copyWith(routeSegments: [lineSegment]));
          debugPrint('✅ [Preview] $busName 노선 경로 표시 완료 (${pathPoints.length}개 좌표)');
        } else {
          debugPrint('⚠️ [Preview] 노선 경로 데이터를 가져오지 못했습니다.');
        }
      }
    }
    
    _shouldFitBounds = true;
    notifyListeners();
  }

  /// 💡 [Request] 강조 표시 제거 및 원래 경로 복구
  void clearHighlightMarker() {
    debugPrint('🧹 [Preview] 미리보기 모드 해제 및 원래 경로 복구 가동');
    
    // 💡 [수석 개발자] 상태를 명시적으로 재설정하여 사이드 이펙트 방지
    if (_state.backupPins != null) {
      _updateState(HomeState(
        isAnalyzing: _state.isAnalyzing,
        routes: _state.routes,
        pins: List<MapPin>.from(_state.backupPins!),
        routeSegments: List<RouteSegment>.from(_state.backupSegments ?? []),
        errorMessage: _state.errorMessage,
        isNearDestination: _state.isNearDestination,
        barMode: _state.barMode,
        activeScheduleBusName: null, // 💡 미리보기 바 확실히 제거
        backupPins: null,
        backupSegments: null,
      ));
    } else {
      // 백업이 없는 경우 (드문 케이스) 단순히 하이라이트만 제거
      _updateState(_state.copyWith(
        pins: _state.pins.where((p) => p.address != 'highlight').toList(),
        activeScheduleBusName: null,
        clearBackup: true,
      ));
    }
    
    _shouldFitBounds = true;
    notifyListeners(); // 💡 확실한 UI 갱신
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
    // 💡 [수석 개발자] 수동 검색 모드 보호: 라벨이 '현재 위치'일 때만 GPS 자동 갱신 허용
    if (_departLabel != '현재 위치') return;

    final newPins = [
      ..._state.pins.where((p) => p.type != PinType.depart),
      MapPin(x: lat, y: lng, type: PinType.depart)
    ];
    _updateState(_state.copyWith(pins: newPins));
    
    // 💡 [수석 개발자] 하차 알림 체크 (Atcha Geofencing 벤치마킹)
    _checkAlighting(lat, lng);
  }

  bool _alightingAlertSent = false;
  
  void _checkAlighting(double lat, double lng) {
    final arrivePin = _state.pins.firstWhere((p) => p.type == PinType.arrive, orElse: () => MapPin(x: 0, y: 0, type: PinType.arrive));
    if (arrivePin.x == 0) {
      _updateState(_state.copyWith(isNearDestination: false));
      _alightingAlertSent = false;
      return;
    }

    final double distance = Geolocator.distanceBetween(lat, lng, arrivePin.x, arrivePin.y);
    
    // 목적지 300m 이내 진입 시
    if (distance < 300) {
      if (!_state.isNearDestination) {
        _updateState(_state.copyWith(isNearDestination: true));
      }
      if (!_alightingAlertSent) {
        debugPrint('🔔 [System] 목적지 근처입니다! 하차를 준비하세요. (거리: ${distance.round()}m)');
        _alightingAlertSent = true;
      }
    } else {
      if (_state.isNearDestination) {
        _updateState(_state.copyWith(isNearDestination: false));
      }
      if (distance > 500) _alightingAlertSent = false;
    }
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

  Future<void> selectRoute(int index, {bool notify = true}) async {
    if (index < 0 || index >= _rawItineraries.length) return;
    final int currentSession = _analysisCount; // 💡 세션 보호
    _selectedRouteIndex = index;
    
    final itinerary = _rawItineraries[index];
    final pathData = _tmapService.parseItineraryPath(itinerary);
    
    // 💡 새로운 리스트 객체 생성으로 불변성 확보
    List<RouteSegment> segments = List<RouteSegment>.from(pathData['segments']);
    final List<MapPin> stops = List<MapPin>.from(pathData['stops']);
    
    debugPrint('🛤️ [SelectRoute] 경로($index) 선택됨. 도보 보정 시작...');

    final List<Future<void>> enrichmentTasks = [];
    for (int i = 0; i < segments.length; i++) {
      final leg = itinerary['legs'][i];
      if (leg['mode'] == 'WALK') {
        enrichmentTasks.add(() async {
          if (currentSession != _analysisCount) return;
          try {
            if (leg['start'] != null && leg['end'] != null) {
              final start = LatLng(double.parse(leg['start']['lat'].toString()), double.parse(leg['start']['lon'].toString()));
              final end = LatLng(double.parse(leg['end']['lat'].toString()), double.parse(leg['end']['lon'].toString()));
              
              final walkPoints = await _tmapService.getWalkingPath(start, end);
              
              if (currentSession == _analysisCount && walkPoints.length > 2) {
                // 💡 [수석 개발자] 지도의 경로선 떨림(이탈) 현상 해결
                // 고정된 ID 체계를 사용하여 지도가 불필요하게 선을 지우고 다시 그리는 것을 방지
                segments[i] = RouteSegment(
                  id: 'path_${index}_seg_$i', // 💡 세션/시간 무관하게 고정된 ID 부여
                  points: List<LatLng>.from(walkPoints),
                  color: segments[i].color,
                  width: segments[i].width,
                  strokeStyle: StrokeStyle.dot,
                );
              }
            }
          } catch (e) {
            debugPrint('⚠️ [SelectRoute] 보정 실패: $e');
          }
        }());
      }
    }

    await Future.wait(enrichmentTasks);
    if (currentSession != _analysisCount) return;

    final newPins = [
      ..._state.pins.where((p) => p.type != PinType.busStop && p.type != PinType.passStop),
      ...stops,
    ];
    
    _shouldFitBounds = true;
    _updateState(_state.copyWith(
      pins: newPins, 
      routeSegments: List<RouteSegment>.from(segments) // 💡 명시적 리스트 교체로 지도 갱신 유도
    ));
  }

  /// 💡 [Request] 특정 노선의 모든 시간표 데이터 조회 (상행/하행 모두)
  List<BusSchedule> getBusSchedules(String busName) {
    final cleanBusName = busName.replaceAll(RegExp(r'[^0-9가-힣]'), '');
    return gwangjuBusSchedules.where(
      (s) => s.routeName == cleanBusName || busName.contains(s.routeName),
    ).toList();
  }

  // ── 💡 Atcha 스타일: 알람 등록 액션 ──
  Future<void> registerDepartureAlarm(BuildContext context, BusRouteInfo route) async {
    try {
      await _registerAlarmUseCase.execute(route);
      if (context.mounted) {
        ToastService().show(context, '⏰ 출발 5분 전 알림이 등록되었습니다!');
      }
    } catch (e) {
      if (context.mounted) {
        ToastService().show(context, '⚠️ $e');
      }
    }
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
