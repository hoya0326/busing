import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

// 앱의 설정과 데이터를 기기에 영구 저장하는 서비스입니다.
class StorageService {
  static const String _routinesKey = 'routines';
  static const String _userNameKey = 'userName';

  // 저장소를 사용하기 전 준비 작업을 수행합니다.
  Future<void> init() async {
    // 초기화가 필요한 로직을 여기에 작성합니다.
  }

  // 저장된 모든 이동 루틴을 불러옵니다.
  Future<List<Routine>> getRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_routinesKey);
    if (jsonString == null) {
      // 초기 사용자에게 제공할 기본 루틴 정보입니다.
      return [
        Routine(id: 1, time: '오전 08:30', from: '집', to: '학교 (조선대)', bus: '수완03'),
        Routine(id: 2, time: '오후 06:30', from: '학교 (조선대)', to: '학원', bus: '지원151'),
      ];
    }
    final List<dynamic> list = json.decode(jsonString);
    return list.map((e) => Routine.fromJson(e)).toList();
  }

  // 수정된 루틴 목록을 기기에 저장합니다.
  Future<void> saveRoutines(List<Routine> routines) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(routines.map((e) => e.toJson()).toList());
    await prefs.setString(_routinesKey, jsonString);
  }

  // 사용자 이름을 가져옵니다. 기본값은 '루틴버스 사용자'입니다.
  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? '루틴버스 사용자';
  }

  // 변경된 사용자 이름을 기기에 기록합니다.
  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }
}
