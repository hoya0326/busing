import 'dart:async';
import 'dart:math' as math; // 💡 Math 대신 math로 규격화
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart'; // 💡 거리 계산을 위해 추가
import 'models.dart';
import 'data/bus_schedules.dart'; 
import 'data/bus_line_data.dart'; // 💡 추가: 하드코딩 데이터 접근을 위해 필요
import 'storage_service.dart';
import 'services/routing_service.dart';
import 'services/bus_api_service.dart';
import 'services/kakao_routing_service.dart';
import 'services/kakao_local_service.dart';
import 'services/tmap_service.dart';
import 'usecases/register_alarm_usecase.dart'; // 💡 추가
import 'services/toast_service.dart'; // 💡 추가
import 'services/notification_service.dart'; // 💡 추가
import 'package:shared_preferences/shared_preferences.dart'; // 💡 추가

enum WidgetBarMode { main, stopDetail, lineInfo, lineSchedule, lineDetails }

// 💡 Atcha의 HomeViewModel.State 포팅
class HomeState {
  final bool isAnalyzing;
  final List<BusRouteInfo> routes;
  final List<MapPin> pins;
  final List<RouteSegment> routeSegments;
  final String? errorMessage;
  final String? alarmMessage; // 💡 추가: 막차 알림 메시지
  final bool isNearDestination;
  final WidgetBarMode barMode;
  final String? activeBusName; 
  final List<BusLineStation> activeLineStations;
  final Map<String, dynamic>? activeBusDetails; 
  final String activeDirection; 
  final int updateTrigger; 
  final List<Place> extraDestinations; 
  final bool isGuidanceActive; 
  final bool isStopsExpanded; 
  final List<int> segmentDurations; 
  final List<double> segmentDistances; 
  final double fontScaleDelta; 
  final String soundMode; // 💡 추가: 음성, 진동, 무음
  final String walkSpeed; // 💡 추가: 느리게, 보통, 빠르게
  final bool realTimeRefresh; // 💡 추가: 실시간 데이터 새로고침 여부

  HomeState({
    this.isAnalyzing = false,
    this.routes = const [],
    this.pins = const [],
    this.routeSegments = const [],
    this.errorMessage,
    this.alarmMessage, // 💡 추가
    this.isNearDestination = false,
    this.barMode = WidgetBarMode.main,
    this.activeBusName,
    this.activeLineStations = const [],
    this.activeBusDetails,
    this.activeDirection = 'UP',
    this.updateTrigger = 0,
    this.extraDestinations = const [],
    this.isGuidanceActive = false,
    this.isStopsExpanded = false,
    this.segmentDurations = const [],
    this.segmentDistances = const [],
    this.fontScaleDelta = 0,
    this.soundMode = '음성',
    this.walkSpeed = '보통',
    this.realTimeRefresh = true,
  });

  HomeState copyWith({
    bool? isAnalyzing,
    List<BusRouteInfo>? routes,
    List<MapPin>? pins,
    List<RouteSegment>? routeSegments,
    String? errorMessage,
    String? alarmMessage, // 💡 추가
    bool? isNearDestination,
    WidgetBarMode? barMode,
    String? activeBusName,
    List<BusLineStation>? activeLineStations,
    Map<String, dynamic>? activeBusDetails,
    String? activeDirection,
    int? updateTrigger,
    List<Place>? extraDestinations,
    bool? isGuidanceActive,
    bool? isStopsExpanded,
    List<int>? segmentDurations,
    List<double>? segmentDistances,
    double? fontScaleDelta,
    String? soundMode,
    String? walkSpeed,
    bool? realTimeRefresh,
  }) {
    return HomeState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      routes: routes ?? this.routes,
      pins: pins ?? this.pins,
      routeSegments: routeSegments ?? this.routeSegments,
      errorMessage: errorMessage ?? this.errorMessage,
      alarmMessage: alarmMessage ?? this.alarmMessage, // 💡 추가
      isNearDestination: isNearDestination ?? this.isNearDestination,
      barMode: barMode ?? this.barMode,
      activeBusName: activeBusName ?? this.activeBusName,
      activeLineStations: activeLineStations ?? this.activeLineStations,
      activeBusDetails: activeBusDetails ?? this.activeBusDetails,
      activeDirection: activeDirection ?? this.activeDirection,
      updateTrigger: updateTrigger ?? this.updateTrigger,
      extraDestinations: extraDestinations ?? this.extraDestinations,
      isGuidanceActive: isGuidanceActive ?? this.isGuidanceActive,
      isStopsExpanded: isStopsExpanded ?? this.isStopsExpanded,
      segmentDurations: segmentDurations ?? this.segmentDurations,
      segmentDistances: segmentDistances ?? this.segmentDistances,
      fontScaleDelta: fontScaleDelta ?? this.fontScaleDelta,
      soundMode: soundMode ?? this.soundMode,
      walkSpeed: walkSpeed ?? this.walkSpeed,
      realTimeRefresh: realTimeRefresh ?? this.realTimeRefresh,
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
  final RegisterAlarmUseCase _registerAlarmUseCase = RegisterAlarmUseCase(); 

  Timer? _searchDebounce; // 💡 검색 디바운싱용
  int _currentSearchId = 0; // 💡 검색 레이스 컨디션 방지용

  BusApiService get busApiService => _busApiService; 

  AppProvider(this._storageService) {
    _state = HomeState(
      pins: [MapPin(x: 35.1601, y: 126.8515, type: PinType.depart)]
    );
    _startRefreshTimer(); // 💡 30초마다 UI 갱신 트리거
  }

  void _startRefreshTimer() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkLastBusForAlarms(); // 💡 1분마다 목적지별 막차 체크
      notifyListeners();
    });
  }

  /// 💡 [수석 개발자] 백그라운드 막차 자동 탐색 로직
  /// 등록된 목적지 및 요일별 루틴에 대해 현재 위치에서의 경로를 분석하여 실시간 정보를 위젯에 동기화합니다.
  Future<void> _checkLastBusForAlarms() async {
    if (_destinationAlarms.isEmpty && _routines.isEmpty) {
      await _updateWidgetData("정보 없음", "도착정보없음", "설정된 목적지 없음");
      return;
    }
    
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    
    // 요일 매핑
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final currentDayStr = weekdays[now.weekday - 1];
    final todayRoutines = _routines.where((r) => r.enabled && r.day == currentDayStr).toList();

    // 💡 [수석 개발자] 막차 트래킹 가동 시간대(18:00~00:00) 또는 오늘 활성화된 루틴이 있는 경우 가동
    final isLastBusTrackingTime = (hour >= 18);
    final hasActiveRoutineToday = todayRoutines.isNotEmpty;

    if (!isLastBusTrackingTime && !hasActiveRoutineToday) {
      await _updateWidgetData("대기 중", "도착정보없음", "설정된 목적지 없음");
      return;
    }
    
    final currentPos = _state.pins.firstWhere((p) => p.type == PinType.depart, 
      orElse: () => MapPin(x: 35.1601, y: 126.8515, type: PinType.depart));
    
    final origin = LatLng(currentPos.x, currentPos.y);

    // 1. 목적지별 막차 알림 체크 우선 수행
    for (var alarm in _destinationAlarms) {
      if (!alarm.isEnabled) continue;

      try {
        final dest = LatLng(alarm.destination.lat, alarm.destination.lng);
        final tmapData = await _tmapService.getTransitRoute(origin, dest);
        
        if (tmapData != null) {
          final parsed = _tmapService.parseTmapData(tmapData);
          final List<BusRouteInfo> routes = List<BusRouteInfo>.from(parsed['busRoutes'] ?? []);
          
          if (routes.isNotEmpty) {
            final bestRoute = routes.first;
            debugPrint('🔍 [Background Check] ${alarm.destination.name} 경로 확인: ${bestRoute.busName} (${bestRoute.statusText})');
            
            String remainStr = bestRoute.busArrivalRemaining < 0 ? '도착정보없음' : '${bestRoute.busArrivalRemaining}';
            String stopInfo = '${alarm.destination.name} · 도보 ${bestRoute.walkTimeRemaining}분';
            await _updateWidgetData(bestRoute.busName, remainStr, stopInfo);

            if (bestRoute.status == RouteStatus.tight || bestRoute.status == RouteStatus.hard) {
              _triggerLastBusNotification(alarm.destination.name, bestRoute.busName);
            }
            return;
          } else {
            await _updateWidgetData("정보 없음", "도착정보없음", alarm.destination.name);
          }
        } else {
          await _updateWidgetData("정보 없음", "도착정보없음", alarm.destination.name);
        }
      } catch (e) {
        await _updateWidgetData("정보 없음", "도착정보없음", alarm.destination.name);
      }
    }

    // 2. 목적지 알림이 없을 경우 요일별 루틴 체크 수행
    for (var routine in todayRoutines) {
      try {
        final results = await _kakaoLocalService.searchKeywords(routine.to);
        if (results.isNotEmpty) {
          final destLat = results[0]['lat'] as double;
          final destLng = results[0]['lng'] as double;
          final dest = LatLng(destLat, destLng);

          final tmapData = await _tmapService.getTransitRoute(origin, dest);
          if (tmapData != null) {
            final parsed = _tmapService.parseTmapData(tmapData);
            final List<BusRouteInfo> routes = List<BusRouteInfo>.from(parsed['busRoutes'] ?? []);
            if (routes.isNotEmpty) {
              final bestRoute = routes.first;
              String remainStr = bestRoute.busArrivalRemaining < 0 ? '도착정보없음' : '${bestRoute.busArrivalRemaining}';
              String stopInfo = '${routine.to} · 도보 ${bestRoute.walkTimeRemaining}분';
              await _updateWidgetData(bestRoute.busName, remainStr, stopInfo);
              return;
            }
          }
        }
        await _updateWidgetData("정보 없음", "도착정보없음", routine.to);
      } catch (e) {
        await _updateWidgetData("정보 없음", "도착정보없음", routine.to);
      }
    }
  }

  // 💡 [수석 개발자] 네이티브 위젯(Android/iOS)을 위한 SharedPreferences 데이터 기록
  Future<void> _updateWidgetData(String busName, String remainMin, String stopName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widget_busName', busName);
    await prefs.setString('widget_remainMin', remainMin);
    await prefs.setString('widget_stopName', stopName);
  }

  void _triggerLastBusNotification(String destName, String busName) {
    debugPrint('🔔 [NOTIFICATION] $destName행 막차 알림! $busName 버스가 곧 끊깁니다.');
    
    // 💡 [수석 개발자] 로컬 알림 서비스 호출
    NotificationService().showImmediate(
      id: 999,
      title: '🚇 막차 임박 알림!',
      body: '[$destName행] $busName 막차가 곧 끊깁니다. 지금 출발하세요!',
    );

    _updateState(_state.copyWith(
      alarmMessage: '⏰ [$destName행] $busName 막차가 임박했습니다! 지금 출발하세요.',
    ));
    
    // 💡 30초 후 알림 메시지 자동 제거
    Timer(const Duration(seconds: 30), () {
      _updateState(_state.copyWith(alarmMessage: null));
    });
  }

  HomeState _state = HomeState();
  HomeState get state => _state;

  List<Place> _favoritePlaces = [];
  List<BusRouteInfo> _stopArrivals = [];
  List<dynamic> _rawItineraries = [];
  List<dynamic> _extraLegItineraries = []; // 💡 안내 중 추가 목적지 경로들
  List<BusStop> _allGwangjuStations = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<DestinationAlarm> _destinationAlarms = []; // 💡 변경: 목적지 기반 막차 알람

  String _departLabel = '현재 위치';
  String _arriveLabel = '';
  
  List<DestinationAlarm> get destinationAlarms => _destinationAlarms;

  void addDestinationAlarm(Place destination) {
    if (!_destinationAlarms.any((a) => a.destination.id == destination.id)) {
      _destinationAlarms.add(DestinationAlarm(destination: destination));
      _storageService.saveDestinationAlarms(_destinationAlarms); // 💡 저장 로직 추가
      notifyListeners();
    }
  }

  void removeDestinationAlarm(String id) {
    _destinationAlarms.removeWhere((a) => a.destination.id == id);
    _storageService.saveDestinationAlarms(_destinationAlarms);
    notifyListeners();
  }

  void toggleDestinationAlarm(String id) {
    final idx = _destinationAlarms.indexWhere((a) => a.destination.id == id);
    if (idx != -1) {
      _destinationAlarms[idx].isEnabled = !_destinationAlarms[idx].isEnabled;
      _storageService.saveDestinationAlarms(_destinationAlarms);
      notifyListeners();
    }
  }
  
  // 💡 [수석 개발자] 피그마 명세서에 따른 임시 목적지 상태 관리
  String _tempArriveLabel = '';
  double? _tempArriveLat;
  double? _tempArriveLng;
  List<Place> _tempExtras = [];
  
  String? _selectedStopName;
  bool _isServiceEnded = false;
  bool _shouldFitBounds = false;
  bool _isSearching = false;
  bool _isLoadingArrivals = false;
  bool _shouldMoveToArrival = false; 
  int _selectedRouteIndex = 0;
  int _analysisCount = 0; 
  LatLng? _currentSelectedStopLatLng;

  // 헬퍼 게터들
  WidgetBarMode get barMode => _state.barMode;
  bool get isAnalyzing => _state.isAnalyzing;
  bool get isNearDestination => _state.isNearDestination;
  bool get shouldMoveToArrival => _shouldMoveToArrival; 
  List<BusRouteInfo> get recommendedRoutes => _state.routes;
  List<MapPin> get pins => _state.pins;
  List<RouteSegment> get routeSegments => _state.routeSegments; 
  String? get errorMessage => _state.errorMessage;

  String get departLabel => _departLabel;
  String get arriveLabel => _arriveLabel;
  String get tempArriveLabel => _tempArriveLabel;
  double? get tempArriveLat => _tempArriveLat; // 💡 추가
  double? get tempArriveLng => _tempArriveLng; // 💡 추가
  List<Place> get tempExtras => _tempExtras;
  bool get isGuidanceActive => _state.isGuidanceActive;
  
  int get totalGuidanceDuration {
    if (_state.segmentDurations.isEmpty) return 0;
    return _state.segmentDurations.reduce((a, b) => a + b);
  }
  
  List<Place> get favoritePlaces => _favoritePlaces;
  bool get shouldFitBounds => _shouldFitBounds;
  int get selectedRouteIndex => _selectedRouteIndex;
  int get analysisCount => _analysisCount; // 💡 지도 리빌드 트리거를 위해 노출
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

  /// 💡 [New Request] 버스 노선 정보(정류장 목록 등) 열기
  Future<void> openBusLineInfo(String busName, {String direction = 'UP'}) async {
    debugPrint('📋 [Provider] $busName ($direction) 노선 정보 열기');
    
    final lookupKey = "${busName}_$direction";
    
    // 💡 [수석 개발자] 하드코딩 데이터 즉시 로드로 0ms 반응 구현
    // _busApiService를 통하지 않고 즉시 hardcoded 데이터에 접근하여 상태 갱신
    final List<BusLineStation> cachedStations = hardcodedBusLines[lookupKey] ?? [];
    final Map<String, dynamic>? cachedDetails = hardcodedBusDetails[busName];

    // 1. 상태 전환 및 초기화 (하드코딩 데이터가 있으면 즉시 반영)
    _updateState(_state.copyWith(
      barMode: WidgetBarMode.lineInfo,
      activeBusName: busName,
      activeLineStations: cachedStations,
      activeBusDetails: cachedDetails,
      activeDirection: direction,
    ));

    // 2. 하드코딩 데이터가 없거나 부족할 때만 백그라운드 로드
    if (cachedStations.isEmpty || cachedDetails == null) {
      try {
        final results = await Future.wait([
          _busApiService.getLineStations(lookupKey),
          _busApiService.getBusLineDetailInfo(busName),
        ]);

        if (_state.activeBusName == busName && _state.activeDirection == direction) {
          _updateState(_state.copyWith(
            activeLineStations: results[0] as List<BusLineStation>,
            activeBusDetails: results[1] as Map<String, dynamic>?,
          ));
        }
      } catch (e) {
        debugPrint('❌ [LineInfo] 데이터 로드 실패: $e');
      }
    }
  }

  /// 💡 [New Request] 방향 전환
  Future<void> switchBusDirection() async {
    if (_state.activeBusName == null) return;
    final nextDir = _state.activeDirection == 'UP' ? 'DOWN' : 'UP';
    await openBusLineInfo(_state.activeBusName!, direction: nextDir);
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
    
    debugPrint('🛤️ [Provider] 분석 세션($currentSession) 시작: ${_state.isGuidanceActive ? "안내 모드" : "검색 모드"}');

    // 💡 분석 시작 시 이전 버스 정류장들만 제거
    final currentPins = List<MapPin>.from(_state.pins);
    currentPins.removeWhere((p) => p.type == PinType.busStop);

    _updateState(_state.copyWith(
      isAnalyzing: true,
      errorMessage: null,
      routes: [],
      routeSegments: [], 
      pins: currentPins,
      updateTrigger: _state.updateTrigger + 1,
    ));

    try {
      final List<LatLng> waypoints = [
        LatLng(departPin.x, departPin.y),
        ..._state.extraDestinations.map((e) => LatLng(e.lat, e.lng)),
        LatLng(arrivePin.x, arrivePin.y),
      ];

      // 💡 [수석 개발자] 경유지가 있는 경우와 없는 경우를 분리하여 처리
      if (!_state.isGuidanceActive || waypoints.length <= 2) {
        // 1. 단일 목적지 (일반 검색)
        final tmapData = await _tmapService.getTransitRoute(waypoints[0], waypoints.last);
        if (currentSession != _analysisCount) return;

        if (tmapData != null) {
          final Map<String, dynamic> parsed = _tmapService.parseTmapData(tmapData);
          _rawItineraries = parsed['rawItineraries'] ?? [];
          _extraLegItineraries = []; // 경유지 없음

          _updateState(_state.copyWith(
            routes: List<BusRouteInfo>.from(parsed['busRoutes'] ?? []),
            errorMessage: parsed['errorMessage'],
          ));
          await _enrichRecommendedRoutes(currentSession);
          if (currentSession == _analysisCount && _rawItineraries.isNotEmpty) {
            await selectRoute(0);
          }
        }
      } else {
        // 2. 다중 목적지 (안내 모드)
        debugPrint('🧬 [Provider] 다중 구간 분석 시작 (구간 수: ${waypoints.length - 1})');
        
        // 첫 번째 구간 (검색 옵션 리스트용)
        final firstLegData = await _tmapService.getTransitRoute(waypoints[0], waypoints[1]);
        if (currentSession != _analysisCount) return;

        if (firstLegData != null) {
          final Map<String, dynamic> firstParsed = _tmapService.parseTmapData(firstLegData);
          _rawItineraries = firstParsed['rawItineraries'] ?? [];
          _updateState(_state.copyWith(
            routes: List<BusRouteInfo>.from(firstParsed['busRoutes'] ?? []),
            errorMessage: firstParsed['errorMessage'],
          ));
          await _enrichRecommendedRoutes(currentSession);
        }

        // 나머지 구간들 (최적 경로만 추출하여 맵 표시용으로 누적)
        _extraLegItineraries = [];
        for (int i = 1; i < waypoints.length - 1; i++) {
          final legData = await _tmapService.getTransitRoute(waypoints[i], waypoints[i+1]);
          if (currentSession != _analysisCount) return;
          
          if (legData != null) {
            final Map<String, dynamic> legParsed = _tmapService.parseTmapData(legData);
            final legItineraries = legParsed['rawItineraries'] ?? [];
            if (legItineraries.isNotEmpty) {
              _extraLegItineraries.add(legItineraries[0]); // 각 구간의 최적 경로 하나만 저장
            }
          }
        }

        if (currentSession == _analysisCount && _rawItineraries.isNotEmpty) {
          await selectRoute(0); // 첫 번째 구간 선택 시 전체 경로가 병합됨
        }
      }

      _shouldFitBounds = true;
    } catch (e) {
      debugPrint('❌ [Provider] 분석 중 치명적 에러: $e');
      _updateState(_state.copyWith(
        errorMessage: '경로 분석 중 오류가 발생했습니다.',
        isAnalyzing: false,
      ));
    }

    if (currentSession == _analysisCount) {
      _updateState(_state.copyWith(isAnalyzing: false));
    }
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
              route.stopsRemaining = match.stopsRemaining; 
              route.nextBusArrivalRemaining = match.nextBusArrivalRemaining; // 💡 추가
              route.nextBusStopsRemaining = match.nextBusStopsRemaining;     // 💡 추가
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
    _tempArriveLabel = label; 
    
    debugPrint('🎯 [Provider] 목적지 설정 시도: $label ($lat, $lng)');
    
    if (lat != null && lng != null) {
      final cleanedPins = _state.pins.where((p) => p.type != PinType.arrive && p.type != PinType.busStop).toList();
      cleanedPins.add(MapPin(x: lat, y: lng, type: PinType.arrive, label: label)); 
      _shouldMoveToArrival = true; 
      _updateState(_state.copyWith(pins: cleanedPins, updateTrigger: _state.updateTrigger + 1));
      _triggerAnalysis();
    } else {
      // 💡 [수석 개발자] 좌표가 없는 경우 즐겨찾기에서 매핑 시도 (별칭 또는 이름으로 검색)
      final Place place = _favoritePlaces.firstWhere(
        (p) => (p.alias ?? p.name) == label || p.name == label, 
        orElse: () => Place(id: '0', name: '', lat: 0, lng: 0, address: '')
      );
      
      if (place.lat != 0) {
        final cleanedPins = _state.pins.where((p) => p.type != PinType.arrive && p.type != PinType.busStop).toList();
        cleanedPins.add(MapPin(x: place.lat, y: place.lng, type: PinType.arrive, label: place.alias ?? place.name));
        _shouldMoveToArrival = true; 
        _updateState(_state.copyWith(pins: cleanedPins, updateTrigger: _state.updateTrigger + 1));
        _triggerAnalysis();
      } else {
        debugPrint('⚠️ [Provider] 해당 장소의 좌표를 찾을 수 없습니다.');
      }
    }
  }

  void toggleStopsExpanded() {
    _updateState(_state.copyWith(isStopsExpanded: !_state.isStopsExpanded));
  }

  // 💡 [New Request] 피그마 명세서 전용 목적지 관리 메서드들
  
  void setTempArriveLabel(String label, {double? lat, double? lng}) {
    _tempArriveLabel = label;
    _tempArriveLat = lat;
    _tempArriveLng = lng;
    notifyListeners();
  }

  void addTempExtra(String label, {double? lat, double? lng}) {
    if (_tempExtras.length < 3) {
      _tempExtras.add(Place(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: label,
        lat: lat ?? 0,
        lng: lng ?? 0,
        address: '',
      ));
      notifyListeners();
    }
  }

  void removeTempExtra(int index) {
    if (index >= 0 && index < _tempExtras.length) {
      _tempExtras.removeAt(index);
      notifyListeners();
    }
  }

  void updateTempExtra(int index, String label, {double? lat, double? lng}) {
    if (index >= 0 && index < _tempExtras.length) {
      _tempExtras[index] = Place(
        id: _tempExtras[index].id,
        name: label,
        lat: lat ?? 0,
        lng: lng ?? 0,
        address: '',
      );
      notifyListeners();
    }
  }

  void resetTempSettings() {
    _tempArriveLabel = _arriveLabel;
    final arrivePin = _state.pins.firstWhere((p) => p.type == PinType.arrive, orElse: () => MapPin(x: 0, y: 0, type: PinType.arrive));
    _tempArriveLat = arrivePin.x != 0 ? arrivePin.x : null;
    _tempArriveLng = arrivePin.y != 0 ? arrivePin.y : null;
    _tempExtras = List.from(_state.extraDestinations);
    notifyListeners();
  }

  void removeExtraDestination(int index) {
    if (index >= 0 && index < _state.extraDestinations.length) {
      final newExtras = List<Place>.from(_state.extraDestinations)..removeAt(index);
      _updateState(_state.copyWith(extraDestinations: newExtras));
    }
  }

  Future<void> startGuidance() async {
    // 💡 [수석 개발자] 도착지가 비어있고 경유지가 있다면, 마지막 경유지를 도착지로 승격
    if (_tempArriveLabel.isEmpty && _tempExtras.isNotEmpty) {
      final lastExtra = _tempExtras.removeLast();
      _tempArriveLabel = lastExtra.alias ?? lastExtra.name;
      _tempArriveLat = lastExtra.lat;
      _tempArriveLng = lastExtra.lng;
    }
    
    // 도착지나 경유지가 아예 없으면 중단 (무한 로딩 방지)
    if (_tempArriveLabel.isEmpty) {
       debugPrint('⚠️ [Provider] 목적지가 없어 안내를 시작할 수 없습니다.');
       _updateState(_state.copyWith(isAnalyzing: false));
       return;
    }

    _arriveLabel = _tempArriveLabel;
    
    List<MapPin> newPins = _state.pins.where((p) => p.type != PinType.arrive && p.type != PinType.busStop).toList();
    
    if (_tempArriveLat != null && _tempArriveLng != null) {
      newPins.add(MapPin(x: _tempArriveLat!, y: _tempArriveLng!, type: PinType.arrive, label: _tempArriveLabel));
    } else if (_tempArriveLabel.isNotEmpty) {
      final place = _favoritePlaces.firstWhere(
        (p) => (p.alias ?? p.name) == _tempArriveLabel || p.name == _tempArriveLabel, 
        orElse: () => Place(id: '0', name: '', lat: 0, lng: 0, address: '')
      );
      if (place.lat != 0) {
        newPins.add(MapPin(x: place.lat, y: place.lng, type: PinType.arrive, label: _tempArriveLabel));
      }
    }

    _updateState(_state.copyWith(
      pins: newPins,
      extraDestinations: List.from(_tempExtras),
      isGuidanceActive: true,
      barMode: WidgetBarMode.main,
      isAnalyzing: true, // 💡 분석 중 표시
    ));

    // 💡 [수석 개발자] 구간별 정확한 데이터 산출 (Tmap API 순차 호출)
    final departPin = newPins.firstWhere((p) => p.type == PinType.depart);
    final arrivePin = newPins.firstWhere((p) => p.type == PinType.arrive);
    
    final List<LatLng> waypoints = [
      LatLng(departPin.x, departPin.y),
      ..._tempExtras.map((e) => LatLng(e.lat, e.lng)),
      LatLng(arrivePin.x, arrivePin.y),
    ];

    List<int> durations = [];
    List<double> distances = [];

    for (int i = 0; i < waypoints.length - 1; i++) {
      try {
        final route = await _tmapService.getTransitRoute(waypoints[i], waypoints[i+1]);
        if (route != null && route['metaData']?['plan']?['itineraries'] != null) {
          final itinerary = route['metaData']['plan']['itineraries'][0];
          durations.add(((itinerary['totalTime'] as num) / 60).round());
          distances.add(((itinerary['totalDistance'] as num) / 1000).toDouble());
        } else {
          // API 실패 시 거리 기반 추정
          double dist = Geolocator.distanceBetween(waypoints[i].latitude, waypoints[i].longitude, waypoints[i+1].latitude, waypoints[i+1].longitude);
          durations.add((dist / 300).round() + 5); // 약 18km/h 가정
          distances.add(dist / 1000);
        }
      } catch (e) {
        durations.add(10);
        distances.add(1.0);
      }
    }

    _updateState(_state.copyWith(
      segmentDurations: durations,
      segmentDistances: distances,
      isAnalyzing: false,
    ));
    
    _triggerAnalysis();
  }

  void stopGuidance() {
    _updateState(_state.copyWith(
      isGuidanceActive: false,
      extraDestinations: [],
    ));
    clearCurrentRoute();
  }

  // 💡 [New] 앱 데이터 전체 초기화 (Figma 스펙)
  Future<void> clearAllData() async {
    _routines = [];
    _destinationAlarms = [];
    _favoritePlaces = [];
    _arriveLabel = '';
    _departLabel = '현재 위치';
    _tempArriveLabel = '';
    _tempExtras = [];
    
    // Storage 초기화
    await _storageService.saveRoutines([]);
    await _storageService.saveDestinationAlarms([]);
    await _storageService.saveFavoritePlaces([]);
    
    _updateState(HomeState(
      isGuidanceActive: false,
      extraDestinations: [],
    ));
    
    notifyListeners();
    // 초기 장소 로드 재시도 (기본값 복원용)
    await loadFavoritePlaces();
  }

  void setFontScaleDelta(double delta) {
    _updateState(_state.copyWith(fontScaleDelta: delta));
  }

  void setSoundMode(String mode) {
    _updateState(_state.copyWith(soundMode: mode));
  }

  void setWalkSpeed(String speed) {
    _updateState(_state.copyWith(walkSpeed: speed));
  }

  void setRealTimeRefresh(bool val) {
    _updateState(_state.copyWith(realTimeRefresh: val));
  }

  void resetMoveToArrival() {
    _shouldMoveToArrival = false;
  }

  void resetFitBounds() {
    _shouldFitBounds = false;
  }

  Future<void> searchPlaces(String query) async {
    _searchDebounce?.cancel(); // 이전 타이머 취소
    
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    // 💡 [수석 개발자] 입력 즉시 로딩 상태 표시 (UX 개선)
    if (!_isSearching) {
      _isSearching = true;
      notifyListeners();
    }

    // 💡 300ms 디바운싱: 불필요한 API 호출을 획기적으로 줄임
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final searchId = ++_currentSearchId;
      
      try {
        final results = await _kakaoLocalService.searchKeywords(query);
        
        // 💡 레이스 컨디션 방지: 가장 최신 요청만 UI에 반영
        if (searchId == _currentSearchId) {
          _searchResults = results;
          _isSearching = false;
          notifyListeners();
          debugPrint('🔍 [Search] 검색 완료: "$query" (${results.length}건)');
        }
      } catch (e) {
        if (searchId == _currentSearchId) {
          debugPrint('❌ [Search] 검색 실패: $e');
          _isSearching = false;
          notifyListeners();
        }
      }
    });
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
        lat: lat, // 💡 좌표 전달 추가
        lng: lng,
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
        final cleanTarget = targetBusName!.replaceAll(RegExp(r'[^0-9가-힣]'), '');
        
        arrivals.sort((a, b) {
          final aClean = a.busName.replaceAll(RegExp(r'[^0-9가-힣]'), '');
          final bClean = b.busName.replaceAll(RegExp(r'[^0-9가-힣]'), '');
          
          bool aIsTarget = aClean == cleanTarget || a.busName.contains(targetBusName!);
          bool bIsTarget = bClean == cleanTarget || b.busName.contains(targetBusName!);
          
          // 1. [0순위] 경로상 타겟 버스 고정 (실시간 여부 무관)
          if (aIsTarget && !bIsTarget) return -1;
          if (!aIsTarget && bIsTarget) return 1;
          
          // 2. [1순위] 실시간 정보가 있는 버스 우선 (남은 분 >= 0)
          bool aHasInfo = a.busArrivalRemaining >= 0;
          bool bHasInfo = b.busArrivalRemaining >= 0;
          if (aHasInfo && !bHasInfo) return -1;
          if (!aHasInfo && bHasInfo) return 1;
          
          // 3. [2순위] 실시간 정보가 없는 버스들(-1, -2 등) 중 -1(정보없음)을 -2(종료)보다 위로
          if (a.busArrivalRemaining == -1 && b.busArrivalRemaining == -2) return -1;
          if (a.busArrivalRemaining == -2 && b.busArrivalRemaining == -1) return 1;

          // 4. 나머지는 이름순
          return a.busName.compareTo(b.busName);
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


  Future<void> loadFavoritePlaces() async {
    final saved = await _storageService.getFavoritePlaces();
    debugPrint('💾 [Provider] 장소 로드 완료: ${saved.length}개');
    for (var p in saved) {
      debugPrint('   - ${p.alias ?? p.name} (Alias: ${p.alias})');
    }
    _favoritePlaces = saved;
    
    _allGwangjuStations = await _storageService.getAllStations();
    if (_allGwangjuStations.isEmpty) {
      _allGwangjuStations = await _busApiService.fetchAllGwangjuStations();
      await _storageService.saveAllStations(_allGwangjuStations);
    }
    notifyListeners();
  }

  Future<void> updateFavoritePlace(int index, Place newPlace) async {
    if (index >= 0 && index < _favoritePlaces.length) {
      debugPrint('💾 [Provider] 장소 업데이트 시도: Index $index, Alias: ${newPlace.alias}');
      
      // 1. 메모리 즉시 갱신
      _favoritePlaces[index] = newPlace;
      _favoritePlaces = List<Place>.from(_favoritePlaces); 
      
      // 2. 저장소 영구 기록
      await _storageService.saveFavoritePlaces(_favoritePlaces);
      
      // 3. UI 강제 동기화 (저장소 데이터 재로드)
      final refreshed = await _storageService.getFavoritePlaces();
      _favoritePlaces = refreshed;
      
      // 4. UI 즉시 통보
      notifyListeners();
      debugPrint('✅ [Provider] UI 갱신 및 데이터 동기화 완료');
    }
  }

  Future<void> addFavoritePlace(Place place) async {
    debugPrint('💾 [Provider] 장소 추가 시작: ${place.alias ?? place.name}');
    _favoritePlaces.add(place);
    _favoritePlaces = List.from(_favoritePlaces);
    await _storageService.saveFavoritePlaces(_favoritePlaces);
    notifyListeners();
  }

  Future<void> removeFavoritePlace(int index) async {
    if (index >= 0 && index < _favoritePlaces.length) {
      _favoritePlaces.removeAt(index);
      _favoritePlaces = List.from(_favoritePlaces); // 💡 UI 갱신 보장
      await _storageService.saveFavoritePlaces(_favoritePlaces);
      notifyListeners();
    }
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

  /// 💡 [버그 수정] GPS 위치에 따라 즐겨찾기를 덮어쓰는 위험한 로직 제거
  Future<void> updateDefaultPlacesWithLocation(double lat, double lng) async {
    // 사용자가 직접 설정한 장소 정보를 보호하기 위해 자동 덮어쓰기를 중단합니다.
    debugPrint('📍 [Provider] 현재 위치 수신: $lat, $lng (즐겨찾기 보호 모드)');
  }

  Future<void> selectRoute(int index, {bool notify = true}) async {
    if (index < 0 || index >= _rawItineraries.length) return;
    final int currentSession = _analysisCount;
    _selectedRouteIndex = index;
    
    // 1. 모든 관련 구간(Legs) 수집
    List<dynamic> activeItineraries = [_rawItineraries[index]];
    if (_state.isGuidanceActive) {
      activeItineraries.addAll(_extraLegItineraries);
    }

    List<RouteSegment> allSegments = [];
    List<MapPin> allStops = [];
    final List<Future<void>> enrichmentTasks = [];

    debugPrint('🛤️ [SelectRoute] 경로 병합 및 보정 시작 (구간 수: ${activeItineraries.length})');

    for (int itIdx = 0; itIdx < activeItineraries.length; itIdx++) {
      final itinerary = activeItineraries[itIdx];
      final pathData = _tmapService.parseItineraryPath(itinerary);
      final List<RouteSegment> legSegments = List<RouteSegment>.from(pathData['segments']);
      allStops.addAll(List<MapPin>.from(pathData['stops']));

      final String suffix = itIdx == 0 ? "" : "_leg$itIdx";
      final bool isFutureLeg = itIdx > 0;

      for (int i = 0; i < legSegments.length; i++) {
        final leg = itinerary['legs'][i];
        final baseSeg = legSegments[i];
        
        // 고유 ID를 부여한 세그먼트 생성
        final segment = RouteSegment(
          id: '${baseSeg.id}$suffix',
          points: baseSeg.points,
          color: isFutureLeg ? baseSeg.color.withOpacity(0.5) : baseSeg.color,
          width: baseSeg.width,
          strokeStyle: baseSeg.strokeStyle,
        );
        
        allSegments.add(segment);
        final int currentIdx = allSegments.length - 1;

        // 도보 구간인 경우 정밀 경로(Shape) 보정 태스크 등록
        if (leg['mode'] == 'WALK' && leg['start'] != null && leg['end'] != null) {
          enrichmentTasks.add(() async {
            if (currentSession != _analysisCount) return;
            try {
              final start = LatLng(double.parse(leg['start']['lat'].toString()), double.parse(leg['start']['lon'].toString()));
              final end = LatLng(double.parse(leg['end']['lat'].toString()), double.parse(leg['end']['lon'].toString()));
              final walkPoints = await _tmapService.getWalkingPath(start, end);
              
              if (currentSession == _analysisCount && walkPoints.length > 2) {
                allSegments[currentIdx] = RouteSegment(
                  id: allSegments[currentIdx].id,
                  points: List<LatLng>.from(walkPoints),
                  color: allSegments[currentIdx].color,
                  width: allSegments[currentIdx].width,
                  strokeStyle: StrokeStyle.dot,
                );
              }
            } catch (e) {
              debugPrint('⚠️ [SelectRoute] 도보 보정 실패: $e');
            }
          }());
        }
      }
    }

    // 도보 보정 완료 대기
    if (enrichmentTasks.isNotEmpty) {
      await Future.wait(enrichmentTasks);
    }

    if (currentSession != _analysisCount) return;

    // 최종 핀 구성: 기존 출발/도착지 핀 유지 + 정류장 핀들 추가
    final basePins = _state.pins.where((p) => p.type == PinType.depart || p.type == PinType.arrive).toList();
    
    // 추가 목적지(경유지) 핀들도 유지하되, 라벨을 순서 숫자로 변경
    for (int i = 0; i < _state.extraDestinations.length; i++) {
      final extra = _state.extraDestinations[i];
      if (!basePins.any((p) => (p.x - extra.lat).abs() < 0.0001)) {
         basePins.add(MapPin(x: extra.lat, y: extra.lng, type: PinType.arrive, label: '${i + 1}번 경유지'));
      }
    }

    _shouldFitBounds = true;
    _updateState(_state.copyWith(
      routeSegments: allSegments,
      pins: [...basePins, ...allStops],
      updateTrigger: _state.updateTrigger + 1,
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
        // 💡 [수석 개발자] 다음 버스인 경우와 현재 버스인 경우 구분하여 토스트
        bool isNext = route.busArrivalRemaining - route.walkTimeRemaining < 0;
        String msg = isNext ? '⏰ 다음 버스 출발 5분 전 알림이 등록되었습니다!' : '⏰ 출발 5분 전 알림이 등록되었습니다!';
        ToastService().show(context, msg);
      }
    } catch (e) {
      if (context.mounted) {
        String errorMsg = e.toString();
        // 💡 [수석 개발자] 에러 원인에 따른 맞춤형 안내
        if (errorMsg.contains('실시간 정보')) {
           ToastService().show(context, '⚪ $errorMsg');
        } else if (errorMsg.contains('이미 출발')) {
           ToastService().show(context, '🏃 $errorMsg');
        } else {
           ToastService().show(context, '⚠️ $errorMsg');
        }
      }
    }
  }

  // ── 루틴 및 프로필 (기존 유지) ──
  List<Routine> _routines = [];
  bool _isLoadingRoutines = true;
  String _selectedDay = '월'; // 💡 기본값을 월요일로 변경
  
  List<Routine> get routines => _routines;
  
  // 💡 [수석 개발자] 현재 선택된 요일의 루틴만 반환하는 게터 추가
  List<Routine> get routinesForSelectedDay {
    return _routines.where((r) => r.day == _selectedDay).toList();
  }
  
  bool get isLoadingRoutines => _isLoadingRoutines;
  String get selectedDay => _selectedDay;

  Future<void> loadRoutines() async {
    _isLoadingRoutines = true;
    notifyListeners();
    final rawRoutines = await _storageService.getRoutines();
    // 💡 [수석 개발자] 시간순 정렬 (오전 12시부터 오후 11시 59분까지)
    _routines = _sortRoutines(rawRoutines);
    _isLoadingRoutines = false;
    notifyListeners();
  }

  List<Routine> _sortRoutines(List<Routine> list) {
    final sorted = List<Routine>.from(list);
    sorted.sort((a, b) {
      // 💡 [개선] 24시간제 변환 후 정렬
      return _convertToMinutes(a.time).compareTo(_convertToMinutes(b.time));
    });
    return sorted;
  }

  int _convertToMinutes(String timeStr) {
    try {
      // '오전 06:00' 또는 '오후 08:30' 형식 처리
      final parts = timeStr.split(' ');
      if (parts.length < 2) return 0;
      final ampm = parts[0];
      final hm = parts[1].split(':');
      int h = int.parse(hm[0]);
      final m = int.parse(hm[1]);
      
      if (ampm == '오후' && h != 12) h += 12;
      if (ampm == '오전' && h == 12) h = 0;
      
      return h * 60 + m;
    } catch (e) { return 0; }
  }

  void addRoutine({
    required String name,
    required String from,
    required String to,
    required String time,
    String? day, // 💡 요일 매개변수 추가
  }) {
    final newId = _routines.isEmpty ? 1 : _routines.map((e) => e.id).reduce(math.max) + 1;
    final routineName = name.trim().isNotEmpty ? name.trim() : '출근 루틴';
    final newRoutine = Routine(
      id: newId,
      name: routineName,
      day: day ?? _selectedDay, // 💡 지정된 요일 또는 현재 선택된 요일 저장
      time: time,
      from: from,
      to: to,
      bus: '미지정', // 향후 자동 추천 연동
      enabled: true,
    );
    _routines.add(newRoutine);
    _routines = _sortRoutines(_routines);
    _storageService.saveRoutines(_routines);
    notifyListeners();
  }

  void deleteRoutine(int id) {
    _routines.removeWhere((r) => r.id == id);
    _storageService.saveRoutines(_routines);
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
    _darkMode = await _storageService.getDarkMode(); // 💡 다크모드 로드
    _destinationAlarms = await _storageService.getDestinationAlarms(); // 💡 목적지 알람 로드
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    _storageService.setUserName(name);
    notifyListeners();
  }

  void setDarkMode(bool val) {
    _darkMode = val;
    _storageService.setDarkMode(val); // 💡 다크모드 저장
    notifyListeners();
  }

  void setNotifOn(bool val) {
    _notifOn = val;
    notifyListeners();
  }
}
