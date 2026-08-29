import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../models.dart';
import '../data/bus_schedules.dart';
import '../data/bus_line_data.dart'; // 💡 추가
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

  Future<List<BusRouteInfo>> getArrivalInfo(String busStopId, {String? stopName, String? targetBusName, double? lat, double? lng}) async {
    if (busStopId == 'Unknown' || busStopId.isEmpty) return [];

    final nowKst = DateTime.now().toUtc().add(const Duration(hours: 9));
    
    // 💡 [수석 개발자] 해당 정류장을 지나는 모든 하드코딩 노선 목록 확보 (좌표 기반 검증 추가)
    final Set<String> expectedBuses = _getExpectedBusesForStop(busStopId, stopName, lat: lat, lng: lng);

    // 타겟 버스가 있는 경우 캐시 무시하고 강제 조회
    if (targetBusName == null && _arrivalCache.containsKey(busStopId)) {
      final cache = _arrivalCache[busStopId]!;
      if (nowKst.difference(cache.timestamp).inSeconds < 30) {
        return _mergeWithExpected(cache.data, expectedBuses);
      }
    }

    List<BusRouteInfo> realTimeArrivals = [];
    try {
      List<dynamic> items = [];
      final url = BusApiEndpoint.arriveInfo(busStopId);
      final response1 = await http.get(url).timeout(const Duration(seconds: 5));
      if (response1.statusCode == 200) items = _parseArrivalJson(response1.body);

      if (items.isEmpty) {
        final altUrl = Uri.parse(url.toString().replaceAll('BUSSTOP_ID', 'STATION_ID'));
        final response2 = await http.get(altUrl).timeout(const Duration(seconds: 5));
        if (response2.statusCode == 200) items = _parseArrivalJson(response2.body);
      }

      if (items.isNotEmpty) {
        realTimeArrivals = items.map((item) {
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

        _arrivalCache[busStopId] = _ArrivalCache(realTimeArrivals, nowKst);
      }
    } catch (e) { 
      debugPrint('❌ [BusAPI] 조회 예외: $e'); 
    }

    // 💡 [핵심] 실시간 정보와 하드코딩 데이터를 병합하여 반환
    final merged = _mergeWithExpected(realTimeArrivals, expectedBuses);
    
    if (merged.isEmpty && stopName != null) return await _getScheduledArrivals(stopName);
    return merged;
  }

  /// 💡 [New] 하드코딩 데이터에서 해당 정류장을 경유하는 버스 이름 추출
  Set<String> _getExpectedBusesForStop(String stopId, String? name, {double? lat, double? lng}) {
    final Set<String> buses = {};
    
    // 💡 [수석 개발자] 매칭 정확도를 위해 데이터 규격화
    final cleanId = stopId.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanName = name?.replaceAll(' ', '').replaceAll(RegExp(r'\(.*\)'), '') ?? '';

    if (cleanId.isEmpty && cleanName.isEmpty && (lat == null || lng == null)) return buses;

    hardcodedBusLines.forEach((key, stations) {
      final busName = key.split('_')[0];
      
      // 💡 [수정] 3중 검증 필터 (좌표 -> ID -> 이름) 적용으로 정확도 극대화
      final passes = stations.any((s) {
        // 1순위: 좌표 기반 정밀 검증 (물리적 거리 확인)
        if (lat != null && lng != null && s.lat != 0 && s.lng != 0) {
          final distSq = (s.lat - lat) * (s.lat - lat) + (s.lng - lng) * (s.lng - lng);
          // 약 60m 이내면 동일 정류장으로 확정
          if (distSq < 0.0000004) return true; 
        }

        // 2순위: ID 기반 엄격 매칭 (내부 ID 또는 공공 ARS_ID)
        final targetId = s.stationId.replaceAll(RegExp(r'[^0-9]'), '');
        final targetArs = s.arsId?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
        
        if (cleanId.isNotEmpty) {
          if (targetId == cleanId || targetArs == cleanId) {
            // ID가 같더라도 좌표 정보가 있다면 최소한의 거리 확인 (오매칭 방지)
            if (lat != null && lng != null && s.lat != 0) {
              final distSq = (s.lat - lat) * (s.lat - lat) + (s.lng - lng) * (s.lng - lng);
              if (distSq > 0.00001) return false; // 약 300m 이상 멀면 무시
            }
            return true;
          }
        }
        
        // 3순위: 명칭 기반 매칭 (보조 수단)
        if (cleanName.isNotEmpty) {
          final targetName = s.stationName.replaceAll(' ', '').replaceAll(RegExp(r'\(.*\)'), '');
          if (targetName == cleanName) {
             // 이름이 같을 경우 매우 엄격한 거리 확인 (동일 명칭 정류장 오인 방지)
             if (lat != null && lng != null && s.lat != 0) {
                final distSq = (s.lat - lat) * (s.lat - lat) + (s.lng - lng) * (s.lng - lng);
                return distSq < 0.000002; // 약 140m 이내
             }
             return true;
          }
        }
        return false;
      });

      if (passes) buses.add(busName);
    });
    return buses;
  }

  /// 💡 [New] 실시간 정보와 예상 노선을 병합 (실시간 정보가 없으면 '정보 없음' 추가)
  List<BusRouteInfo> _mergeWithExpected(List<BusRouteInfo> realTime, Set<String> expected) {
    final List<BusRouteInfo> result = List.from(realTime);
    
    // 💡 [수석 개발자] 실시간 정보에 있는 노선들의 '순수 번호' 추출
    final Set<String> realTimeNames = realTime.map((r) {
      return r.busName.replaceAll(RegExp(r'[^0-9가-힣]'), '');
    }).toSet();

    for (var busName in expected) {
      final cleanExpected = busName.replaceAll(RegExp(r'[^0-9가-힣]'), '');
      
      // 💡 [개선] 실시간 정보에 없는 경우만 '정보 없음'으로 추가
      if (!realTimeNames.contains(cleanExpected)) {
        result.add(BusRouteInfo(
          busName: busName,
          busArrivalRemaining: -1, // 💡 실시간 정보 없음
          walkTimeRemaining: 0,
          travelDuration: 15,
          totalDuration: 15,
          routeDescription: '현재 실시간 정보가 제공되지 않는 구간입니다.',
        ));
      }
    }
    
    // 💡 정렬: 실시간 정보(남은 시간 > 0) -> 실시간 정보 없음(-1) -> 운행 종료(-2)
    result.sort((a, b) {
      if (a.busArrivalRemaining >= 0 && b.busArrivalRemaining < 0) return -1;
      if (a.busArrivalRemaining < 0 && b.busArrivalRemaining >= 0) return 1;
      if (a.busArrivalRemaining == -1 && b.busArrivalRemaining == -2) return -1;
      if (a.busArrivalRemaining == -2 && b.busArrivalRemaining == -1) return 1;
      return a.busName.compareTo(b.busName);
    });

    return result;
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

  Future<Map<String, dynamic>?> getBusLineDetailInfo(String lineName) async {
    // 💡 [수석 개발자] 로컬 하드코딩 데이터 우선 적용 (네트워크 0초 로딩)
    if (hardcodedBusDetails.containsKey(lineName)) {
      debugPrint('📦 [BusAPI] 로컬 상세정보 사용(Direct): $lineName');
      return hardcodedBusDetails[lineName];
    }

    final cleanName = lineName.replaceAll(RegExp(r'[^0-9가-힣]'), '');
    if (hardcodedBusDetails.containsKey(cleanName)) {
      debugPrint('📦 [BusAPI] 로컬 상세정보 사용(Cleaned): $cleanName');
      return hardcodedBusDetails[cleanName];
    }

    final lineId = await _getLineId(lineName);
    if (lineId == null) return null;

    try {
      final response = await http.get(BusApiEndpoint.lineDetail(lineId)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final items = _parseArrivalJson(response.body);
        if (items.isNotEmpty) return items.first;
      }
    } catch (e) {
      debugPrint('⚠️ [BusAPI] 노선 상세 정보 조회 실패: $e');
    }
    return null;
  }

  Future<List<BusLineStation>> getLineStations(String lineName, {String direction = 'UP'}) async {
    // 💡 [수석 개발자] 로컬 하드코딩 데이터 우선 적용 (정확도 100% 보장)
    // 1. 원본 이름으로 시도
    final directKey = "${lineName}_$direction";
    if (hardcodedBusLines.containsKey(directKey)) {
      debugPrint('📦 [BusAPI] 로컬 정류장 데이터 사용(Direct): $directKey');
      return hardcodedBusLines[directKey]!;
    }

    // 2. 정규화된 이름으로 시도
    final cleanName = lineName.replaceAll(RegExp(r'[^0-9가-힣]'), '');
    final cleanKey = "${cleanName}_$direction";
    if (hardcodedBusLines.containsKey(cleanKey)) {
      debugPrint('📦 [BusAPI] 로컬 정류장 데이터 사용(Cleaned): $cleanKey');
      return hardcodedBusLines[cleanKey]!;
    }

    // 하드코딩 데이터가 없는 경우만 API 호출 (Fallback)
    final lineId = await _getLineId(lineName);
    if (lineId == null) return [];

    try {
      final response = await http.get(BusApiEndpoint.lineStation(lineId)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final items = _parseArrivalJson(response.body);
        return List.generate(items.length, (index) {
          final item = items[index];
          return BusLineStation(
            stationName: item['BUSSTOP_NAME'] ?? '알 수 없음',
            stationId: item['BUSSTOP_ID']?.toString() ?? '',
            arsId: item['ARS_ID']?.toString(),
            lat: double.tryParse(item['LATITUDE']?.toString() ?? '0') ?? 0.0,
            lng: double.tryParse(item['LONGITUDE']?.toString() ?? '0') ?? 0.0,
            firstBusTime: '05:40', 
            lastBusTime: '22:30',
          );
        });
      }
    } catch (e) {
      debugPrint('⚠️ [BusAPI] 노선 정류장 조회 실패: $e');
    }
    return [];
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
