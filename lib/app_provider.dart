import 'package:flutter/material.dart';
import 'models.dart';
import 'storage_service.dart';

// 앱 전체의 데이터 관리와 핵심 알고리즘 연산을 담당합니다.
class AppProvider extends ChangeNotifier {
  final StorageService _storageService;

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

  List<BusRouteInfo> get recommendedRoutes => _recommendedRoutes;
  bool get isAnalyzing => _isAnalyzing;

  void setDepartLabel(String label) {
    _departLabel = label;
    _runRouteAnalysis(); // 위치 변경 시 자동 재연산
    notifyListeners();
  }

  void setArriveLabel(String label) {
    _arriveLabel = label;
    _runRouteAnalysis(); // 위치 변경 시 자동 재연산
    notifyListeners();
  }

  void setMapPending(PinType? type) {
    _mapPending = type;
    notifyListeners();
  }

  // 지도 위를 눌러 출발지나 도착지를 직접 지정할 때 호출됩니다.
  void handleMapTap(double x, double y) {
    if (_mapPending == null) return;
    _pins = [..._pins.where((p) => p.type != _mapPending), MapPin(x: x, y: y, type: _mapPending!)];
    if (_mapPending == PinType.depart) {
      _departLabel = '지도에서 선택한 위치';
    } else {
      _arriveLabel = '지도에서 선택한 위치';
    }
    _mapPending = null;
    _runRouteAnalysis(); // 지도 탭 위치 변경 시 재연산
    notifyListeners();
  }

  void clearArrival() {
    _arriveLabel = '';
    _pins = _pins.where((p) => p.type != PinType.arrive).toList();
    _recommendedRoutes = [];
    notifyListeners();
  }

  // ── 핵심 알고리즘: 경로 분석 및 정렬 ──

  // 실시간 에이피아이 데이터를 모사하여 경로를 연산하고 정렬합니다.
  Future<void> _runRouteAnalysis() async {
    if (_arriveLabel.isEmpty) return;

    _isAnalyzing = true;
    notifyListeners();

    // 연산 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 800));

    _recommendedRoutes = [
      BusRouteInfo(
        busName: '수완03',
        busArrivalRemaining: 7, // 7분 뒤 정류장 도착
        walkTimeRemaining: 3,   // 정류장까지 3분 소요
        travelDuration: 15,     // 탑승 후 목적지까지 15분
        routeDescription: '정류장까지 도보 3분',
      ),
      BusRouteInfo(
        busName: '지원151',
        busArrivalRemaining: 4, // 4분 뒤 도착 (촉박)
        walkTimeRemaining: 4,   // 정류장까지 4분 소요
        travelDuration: 25,     // 탑승 후 25분 소요
        routeDescription: '도보 4분',
      ),
      BusRouteInfo(
        busName: '풍암16',
        busArrivalRemaining: 2, // 2분 뒤 도착 (탑승 어려움)
        walkTimeRemaining: 5,   // 도보 5분 필요
        travelDuration: 18,     // 탑승 후 18분 소요
        routeDescription: '도보 5분',
      ),
    ];

    // 최종 도착 시간(Total ETA) 기준 정렬
    _recommendedRoutes.sort((a, b) => a.totalETA.compareTo(b.totalETA));

    _isAnalyzing = false;
    notifyListeners();
  }

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
