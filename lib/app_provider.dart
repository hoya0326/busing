import 'package:flutter/material.dart';
import 'models.dart';
import 'storage_service.dart';

// 앱 전체의 데이터 흐름과 상태를 제어하는 중심 클래스입니다.
class AppProvider extends ChangeNotifier {
  final StorageService _storageService;

  AppProvider(this._storageService);

  // ── 홈 화면 관련 변수와 기능 ──
  String _departLabel = '현재 위치';
  String _arriveLabel = '';
  List<MapPin> _pins = [MapPin(x: 162, y: 240, type: PinType.depart)];
  PinType? _mapPending;

  String get departLabel => _departLabel;
  String get arriveLabel => _arriveLabel;
  List<MapPin> get pins => _pins;
  PinType? get mapPending => _mapPending;

  void setDepartLabel(String label) {
    _departLabel = label;
    notifyListeners();
  }

  void setArriveLabel(String label) {
    _arriveLabel = label;
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
    notifyListeners();
  }

  void clearArrival() {
    _arriveLabel = '';
    _pins = _pins.where((p) => p.type != PinType.arrive).toList();
    notifyListeners();
  }

  // ── 일정 화면 관련 변수와 기능 ──
  List<Routine> _routines = [];
  bool _isLoadingRoutines = true;
  String _selectedDay = '화';

  List<Routine> get routines => _routines;
  bool get isLoadingRoutines => _isLoadingRoutines;
  String get selectedDay => _selectedDay;

  // 저장된 루틴 정보를 불러오는 비동기 작업입니다.
  Future<void> loadRoutines() async {
    _isLoadingRoutines = true;
    notifyListeners();
    _routines = await _storageService.getRoutines();
    _isLoadingRoutines = false;
    notifyListeners();
  }

  // 루틴의 활성화 상태를 켜거나 끕니다.
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

  // ── 프로필 및 환경 설정 관련 ──
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
