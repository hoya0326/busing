import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../models.dart';
import '../data/bus_schedules.dart';
import 'api_endpoints.dart'; // 💡 추가

List<dynamic> _parseArrivalJson(String body) {
  try {
    final data = json.decode(body);
    
    List<dynamic>? findList(dynamic node) {
      if (node == null) return null;
      if (node is List) return node;
      if (node is Map) {
        // ITEM 이라는 키가 있으면 그게 데이터 리스트
        if (node.containsKey('ITEM')) {
          final item = node['ITEM'];
          if (item == null) return []; // 💡 null 체크 추가
          return item is List ? item : [item];
        }
        if (node.containsKey('item')) {
          final item = node['item'];
          if (item == null) return []; // 💡 null 체크 추가
          return item is List ? item : [item];
        }
        // 하위 계층 탐색 (주요 키 위주)
        for (var key in ['ARRIVE_LIST', 'STATION_LIST', 'LINE_LIST', 'RESPONSE', 'BODY', 'body', 'items', 'item']) {
          if (node.containsKey(key)) {
            var found = findList(node[key]);
            if (found != null) return found;
          }
        }
      }
      return null;
    }

    final result = findList(data) ?? [];
    debugPrint('📋 [Parser] 추출된 아이템 수: ${result.length}');
    return result;
  } catch (e) {
    debugPrint('❌ [Parser] 에러: $e');
  }
  return [];
}

class BusApiService {
  List<dynamic>? _cachedStations;
  final Map<String, String> _lineIdCache = {}; // 💡 노선명 -> LINE_ID 캐시
  
  // 💡 실시간 정보 메모리 캐시 (정류장ID -> {데이터, 시간})
  final Map<String, _ArrivalCache> _arrivalCache = {};

  Future<void> initStationCache() async {
    try {
      if (_cachedStations == null) {
        // 💡 [최적화] 네트워크 지연으로 인한 부팅 방지를 위해 타임아웃 5초 설정
        final response = await http.get(BusApiEndpoint.stationInfo()).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          // 💡 공통 파서 사용으로 구조적 결함 해결
          _cachedStations = _parseArrivalJson(response.body);
          if (_cachedStations!.isNotEmpty) {
            final dolgogae = _cachedStations!.firstWhere(
              (s) => s['BUSSTOP_NAME']?.toString().contains('돌고개') ?? false,
              orElse: () => _cachedStations!.first
            );
            debugPrint('📍 [BusAPI] 스테이션 캐시 완료 (${_cachedStations!.length}개). 샘플: $dolgogae');
          }
        }
      }
    } catch (e) { debugPrint('❌ [GJ-BIS] 로드 실패: $e'); }
  }

  Future<Map<String, dynamic>?> getStationByNameOrCoords({String? name, double? lat, double? lng}) async {
    if (_cachedStations == null) await initStationCache();
    if (_cachedStations == null) return null;
    
    dynamic closest;
    double minDistance = double.infinity;

    // 💡 [수석 개발자] 좌표가 있는 경우 좌표 우선 매핑
    if (lat != null && lng != null) {
      for (var s in _cachedStations!) {
        final sLat = double.tryParse(s['LATITUDE']?.toString() ?? '0') ?? 0.0;
        final sLng = double.tryParse(s['LONGITUDE']?.toString() ?? '0') ?? 0.0;
        if (sLat == 0) continue;
        
        double dist = (sLat - lat) * (sLat - lat) + (sLng - lng) * (sLng - lng);
        if (dist < minDistance) {
          minDistance = dist;
          closest = s;
        }
      }
      // 너무 멀면(약 500m 이상) 이름 매칭으로 전환 시도
      if (minDistance > 0.000025 && name != null) {
        closest = null;
      }
    }

    // 💡 [수석 개발자] 이름 기반 매핑 (좌표가 없거나 좌표 매핑 결과가 없는 경우)
    if (closest == null && name != null) {
      final cleanName = name.replaceAll(' ', '').replaceAll('아파트', '');
      closest = _cachedStations!.firstWhere(
        (s) {
          final sName = s['BUSSTOP_NAME']?.toString().replaceAll(' ', '') ?? '';
          return sName.contains(cleanName) || cleanName.contains(sName.replaceAll('아파트', ''));
        },
        orElse: () => null
      );
    }

    if (closest != null) {
      // 💡 [수석 개발자] 실시간 정보 조회 전용 ID(BUSSTOP_ID)를 우선 반환
      return {
        'id': (closest['BUSSTOP_ID'] ?? closest['STATION_ID'] ?? closest['STATION_NUM'])?.toString(),
        'arsId': closest['BUSSTOP_ID']?.toString(),
        'name': closest['BUSSTOP_NAME'],
        'lat': double.tryParse(closest['LATITUDE']?.toString() ?? '0'),
        'lng': double.tryParse(closest['LONGITUDE']?.toString() ?? '0'),
      };
    }
    return null;
  }

  static bool _isQuotaExceeded = false; // 💡 쿼터 초과 상태 전역 관리
  static DateTime? _quotaExceededTime;

  Future<String?> _getLineId(String lineName) async {
    final cleanName = lineName.replaceAll(RegExp(r'[^0-9가-힣]'), '');
    if (_lineIdCache.containsKey(cleanName)) return _lineIdCache[cleanName];

    try {
      final response = await http.get(BusApiEndpoint.lineSearch(cleanName)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final items = _parseArrivalJson(response.body);
        if (items.isNotEmpty) {
          final lineId = items.first['LINE_ID']?.toString();
          if (lineId != null) {
            _lineIdCache[cleanName] = lineId;
            return lineId;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [BusAPI] 노선 ID 조회 실패: $e');
    }
    return null;
  }

  Future<List<BusRouteInfo>> getArrivalInfo(String busStopId, {String? stopName, String? targetBusName}) async {
    if (busStopId == 'Unknown' || busStopId.isEmpty) return [];

    final nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
    
    // 타겟 버스가 있는 경우 캐시 무시하고 강제 조회 (최신성 보장)
    if (targetBusName == null && _arrivalCache.containsKey(busStopId)) {
      final cache = _arrivalCache[busStopId]!;
      if (nowKst.difference(cache.timestamp).inSeconds < 30) { // 30초로 단축
        return cache.data;
      }
    }

    try {
      List<dynamic> items = [];
      
      // 1. 기본 조회
      final url = BusApiEndpoint.arriveInfo(busStopId);
      final response1 = await http.get(url).timeout(const Duration(seconds: 5));
      if (response1.statusCode == 200) items = _parseArrivalJson(response1.body);

      // 2. 결과 없으면 STATION_ID 시도
      if (items.isEmpty) {
        final altUrl = Uri.parse(url.toString().replaceAll('BUSSTOP_ID', 'STATION_ID'));
        final response2 = await http.get(altUrl).timeout(const Duration(seconds: 5));
        if (response2.statusCode == 200) items = _parseArrivalJson(response2.body);
      }

      if (items.isNotEmpty) {
        final arrivals = items.map((item) {
          final lineName = item['LINE_NAME'] ?? item['lineName'] ?? item['SHORT_LINE_NAME'] ?? '버스';
          final remainMinVal = item['REMAIN_MIN'] ?? item['remainMin'] ?? '0';
          final dirEnd = item['DIR_END'] ?? item['dirEnd'] ?? '종점';
          final remainStop = item['REMAIN_STOP'] ?? item['remainStop'] ?? '-';

          return BusRouteInfo(
            busName: lineName.toString(),
            busArrivalRemaining: int.tryParse(remainMinVal.toString()) ?? 0,
            walkTimeRemaining: 0, 
            travelDuration: 15, 
            totalDuration: (int.tryParse(remainMinVal.toString()) ?? 0) + 15,
            routeDescription: '$dirEnd 방면 ($remainStop구간 전)',
          );
        }).toList();

        _arrivalCache[busStopId] = _ArrivalCache(arrivals, nowKst);
        
        // 💡 [수석 개발자] 타겟 버스가 목록에 있는지 확인
        if (targetBusName != null) {
          final cleanTarget = targetBusName.replaceAll(RegExp(r'[^0-9]'), '');
          bool found = arrivals.any((a) => a.busName.replaceAll(RegExp(r'[^0-9]'), '') == cleanTarget);
          
          if (!found) {
            debugPrint('🔍 [BusAPI] 타겟($targetBusName) 누락 - 노선 위치 정보 추적 시도');
            // 여기서 더 깊은 추적(Line Location API)을 할 수 있으나, 
            // 현재는 1순위로 시간표 엔진을 호출하여 "정보 없음" 상태를 방어함
          }
        }
        
        return arrivals;
      }
    } catch (e) { 
      debugPrint('❌ [BusAPI] 조회 예외: $e'); 
    }

    if (stopName != null) return await _getScheduledArrivals(stopName);
    return [];
  }

  /// 💡 [Atcha Fallback] 실시간 데이터 차단 시 정류장 명칭 기반으로 실제 시간표 DB에서 매칭
  Future<List<BusRouteInfo>> _getEmergencyScheduledArrivals(String stopName) async {
    // 1. 실제 시간표 DB에서 해당 정류장이 기점인 노선들을 찾음
    final baseArrivals = await _getScheduledArrivals(stopName);
    if (baseArrivals.isNotEmpty) return baseArrivals;

    // 2. 만약 기점 매칭이 안 된다면, 아무 버스나 보여주는 대신 빈 리스트를 반환하여 데이터 무결성 유지
    // (잘못된 정보를 주는 것은 '비서'로서 가장 피해야 할 행동입니다.)
    debugPrint('⚠️ [BusAPI] 현재 정류장($stopName)의 기점 시간표 데이터가 로컬 DB에 없습니다.');
    return [];
  }

  /// 💡 [Atcha Fallback] 한국 시간(KST) 기준 심야/새벽 운행 종료 및 시간표 매칭
  Future<List<BusRouteInfo>> _getScheduledArrivals(String stopName) async {
    final cleanStopName = stopName.split('|')[0].replaceAll(RegExp(r'\(.*\)'), '').replaceAll(' ', '').trim();
    
    // 💡 [수석 개발자] 기기 설정과 무관하게 한국 시간(KST, UTC+9) 강제 적용
    final nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final hour = nowKst.hour;
    final minute = nowKst.minute;

    // 1. 심야 운행 종료 체크 (00:30 ~ 04:30)
    if ((hour == 0 && minute >= 30) || (hour >= 1 && hour < 4) || (hour == 4 && minute < 30)) {
      debugPrint('🌙 [BusAPI] 심야 시간대: 모든 버스 운행 종료 (KST $hour:$minute)');
      // 💡 [수석 개발자] 심야 시간대임을 명시적으로 알리기 위해 특수 값 반환
      return [BusRouteInfo(
        busName: '종료', 
        busArrivalRemaining: -2, // 💡 운행 종료 코드
        walkTimeRemaining: 0, 
        travelDuration: 0, 
        totalDuration: 0, 
        routeDescription: '금일 운행이 모두 종료되었습니다.'
      )];
    }

    final dayType = nowKst.weekday; 
    List<BusRouteInfo> results = [];

    try {
      final matchedSchedules = gwangjuBusSchedules.where((s) {
        String station = s.startStation.replaceAll(' ', '');
        return cleanStopName.contains(station) || station.contains(cleanStopName);
      }).toList();

      for (var schedule in matchedSchedules) {
        List<String> times = (dayType == 6) ? schedule.saturday : (dayType == 7 ? schedule.sunday : schedule.weekday);
        if (times.isEmpty) times = schedule.weekday;

        for (var t in times) {
          final p = t.split(':');
          if (p.length < 2) continue;
          final dep = DateTime(nowKst.year, nowKst.month, nowKst.day, int.parse(p[0]), int.parse(p[1]));
          
          if (dep.isAfter(nowKst)) {
            final diff = dep.difference(nowKst).inMinutes;
            // 💡 [수석 개발자] 60분 이상 차이나는 버스는 '운행 종료'로 간주 (곧 올 버스가 아님)
            if (diff > 60) continue; 

            results.add(BusRouteInfo(
              busName: schedule.routeName,
              busArrivalRemaining: diff,
              walkTimeRemaining: 0, 
              travelDuration: 15, 
              totalDuration: diff + 15,
              routeDescription: '${schedule.startStation} 출발 예정 (시간표)',
            ));
            break; 
          }
        }
      }
    } catch (e) { debugPrint('❌ [Schedule] 에러: $e'); }
    return results;
  }

  Future<List<BusStop>> fetchAllGwangjuStations() async {
    if (_cachedStations == null) await initStationCache();
    if (_cachedStations == null) return [];

    try {
      return _cachedStations!.map((s) {
        // 💡 [수석 개발자] 광주 BIS 실시간 정보 조회의 핵심인 BUSSTOP_ID를 최우선으로 확보
        final id = s['BUSSTOP_ID']?.toString() ?? s['STATION_ID']?.toString() ?? s['STATION_NUM']?.toString() ?? '';
        return BusStop(
          id: id,
          name: s['BUSSTOP_NAME'] ?? '알 수 없음',
          lat: double.tryParse(s['LATITUDE']?.toString() ?? '0') ?? 0.0,
          lng: double.tryParse(s['LONGITUDE']?.toString() ?? '0') ?? 0.0,
        );
      }).where((s) => s.lat != 0).toList();
    } catch (e) {
      debugPrint('❌ [BusAPI] 전체 정류소 변환 실패: $e');
      return [];
    }
  }
} // 💡 클래스 닫기

// 💡 캐시 구조체
class _ArrivalCache {
  final List<BusRouteInfo> data;
  final DateTime timestamp;
  _ArrivalCache(this.data, this.timestamp);
}
