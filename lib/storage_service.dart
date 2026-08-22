import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class StorageService {
  static const String _routinesKey = 'routines';
  static const String _userNameKey = 'userName';
  static const String _favoritePlacesKey = 'favorite_places';
  static const String _allStationsKey = 'gwangju_stations'; // 💡 추가

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _instance {
    if (_prefs == null) {
      throw Exception('StorageService must be initialized before use.');
    }
    return _prefs!;
  }

  // 자주 가는 장소 목록 가져오기
  Future<List<Place>> getFavoritePlaces() async {
    final jsonString = _instance.getString(_favoritePlacesKey);
    if (jsonString == null) {
      // 초기 기본 장소들 (경진대회 시연용 데모 데이터)
      return [
        Place(id: '1', name: '우리집', lat: 35.1425, lng: 126.9341, address: '광주광역시 동구 지산동'),
        Place(id: '2', name: '학교', lat: 35.1403165, lng: 126.9355550, address: '광주광역시 동구 필문대로 309'),
        Place(id: '3', name: '학원', lat: 35.1500, lng: 126.9200, address: '광주광역시 북구 중흥동'),
        Place(id: '4', name: '헬스장', lat: 35.1600, lng: 126.9100, address: '광주광역시 서구 치평동'),
      ];
    }
    try {
      final List<dynamic> list = json.decode(jsonString);
      return list.map((e) => Place.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // 장소 목록 저장하기
  Future<void> saveFavoritePlaces(List<Place> places) async {
    final jsonString = json.encode(places.map((e) => e.toJson()).toList());
    await _instance.setString(_favoritePlacesKey, jsonString);
  }

  // 💡 수석 개발자: 광주 전체 정류소 데이터 캐싱
  Future<void> saveAllStations(List<BusStop> stations) async {
    final jsonString = json.encode(stations.map((e) => e.toJson()).toList());
    await _instance.setString(_allStationsKey, jsonString);
  }

  Future<List<BusStop>> getAllStations() async {
    final jsonString = _instance.getString(_allStationsKey);
    if (jsonString == null) return [];
    final List<dynamic> list = json.decode(jsonString);
    return list.map((e) => BusStop.fromJson(e)).toList();
  }

  Future<List<Routine>> getRoutines() async {
    final jsonString = _instance.getString(_routinesKey);
    if (jsonString == null) {
      return [
        Routine(id: 1, time: '오전 08:30', from: '집', to: '학교 (조선대)', bus: '수완03'),
        Routine(id: 2, time: '오후 06:30', from: '학교 (조선대)', to: '학원', bus: '지원151'),
      ];
    }
    try {
      final List<dynamic> list = json.decode(jsonString);
      return list.map((e) => Routine.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveRoutines(List<Routine> routines) async {
    final jsonString = json.encode(routines.map((e) => e.toJson()).toList());
    await _instance.setString(_routinesKey, jsonString);
  }

  Future<String> getUserName() async {
    return _instance.getString(_userNameKey) ?? '루틴버스 사용자';
  }

  Future<void> setUserName(String name) async {
    await _instance.setString(_userNameKey, name);
  }
}
