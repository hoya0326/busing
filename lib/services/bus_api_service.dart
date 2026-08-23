import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xml/xml.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../models.dart';
import '../data/bus_schedules.dart';

List<dynamic> _parseArrivalJson(String body) {
  try {
    final data = json.decode(body);
    debugPrint('📦 [Parser] 분석 시작...');

    // 💡 [수석 개발자] 재귀적 리스트 검색 알고리즘 도입
    // 어떤 깊이에 있든 ITEM 리스트를 찾아냅니다.
    List<dynamic>? findItems(dynamic node) {
      if (node == null) return null;
      if (node is List) return node;
      if (node is Map) {
        if (node.containsKey('ITEM')) return node['ITEM'] is List ? node['ITEM'] : [node['ITEM']];
        if (node.containsKey('item')) return node['item'] is List ? node['item'] : [node['item']];
        
        for (var key in ['ARRIVE_LIST', 'STATION_LIST', 'LINE_LIST', 'items', 'BODY', 'body', 'RESPONSE', 'response']) {
          if (node.containsKey(key)) {
            var found = findItems(node[key]);
            if (found != null) return found;
          }
        }
      }
      return null;
    }

    final items = findItems(data);
    if (items != null) {
      debugPrint('✅ [Parser] ${items.length}개의 아이템 추출 성공');
      return items;
    }
  } catch (e) {
    debugPrint('❌ [Parser] 에러: $e');
  }
  debugPrint('⚠️ [Parser] 아이템을 찾지 못했습니다.');
  return [];
}

class BusApiService {
  final String _baseUrl = "http://apis.data.go.kr/6290000/gj_bis/";
  final String _apiKey = (dotenv.env['BUS_SERVICE_KEY'] ?? '').trim();
  
  List<dynamic>? _cachedStations;

  Future<void> initStationCache() async {
    if (_apiKey.isEmpty) return;
    try {
      if (_cachedStations == null) {
        final url = '${_baseUrl}stationInfo?serviceKey=$_apiKey&resultType=json&numOfRows=3000';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _cachedStations = data['STATION_LIST'] ?? data['RESPONSE']?['STATION_LIST']?['ITEM'] ?? [];
          if (_cachedStations!.isNotEmpty) {
            // 💡 [수석 개발자] '돌고개' 정류장을 찾아 실제 필드 구조 정밀 분석
            final dolgogae = _cachedStations!.firstWhere(
              (s) => s['BUSSTOP_NAME']?.toString().contains('돌고개') ?? false,
              orElse: () => _cachedStations!.first
            );
            debugPrint('📍 [BusAPI] 스테이션 캐시 분석 (돌고개): $dolgogae');
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
    for (var s in _cachedStations!) {
      final sLat = double.tryParse(s['LATITUDE']?.toString() ?? '0') ?? 0.0;
      final sLng = double.tryParse(s['LONGITUDE']?.toString() ?? '0') ?? 0.0;
      if (sLat == 0) continue;
      if (lat != null && lng != null) {
        double dist = (sLat - lat).abs() + (sLng - lng).abs();
        if (dist < minDistance) { minDistance = dist; closest = s; }
      }
    }
    if (closest != null) {
      // 💡 [수석 개발자] API 조회용 ID(Internal)와 ARS ID를 모두 반환하도록 개선
      return {
        'id': (closest['STATION_ID'] ?? closest['BUSSTOP_ID'])?.toString(),
        'arsId': closest['BUSSTOP_ID']?.toString(),
        'name': closest['BUSSTOP_NAME'],
        'lat': double.tryParse(closest['LATITUDE']?.toString() ?? '0'),
        'lng': double.tryParse(closest['LONGITUDE']?.toString() ?? '0'),
      };
    }
    return null;
  }

  Future<List<BusRouteInfo>> getArrivalInfo(String busStopId, {String? stopName}) async {
    debugPrint('📡 [StopInfo] getArrivalInfo 호출: ID=$busStopId, Name=$stopName');
    List<BusRouteInfo> liveArrivals = [];
    
    if (busStopId != 'Unknown' && busStopId.isNotEmpty && _apiKey.isNotEmpty) {
      try {
        // 💡 [수석 개발자] 포털 API의 다양한 변수명을 대응하기 위한 다중 시도 로직
        final List<String> idParams = ['BUSSTOP_ID', 'busStopId', 'STATION_ID', 'stationId'];
        
        for (var param in idParams) {
          final url = '${_baseUrl}arriveInfo?serviceKey=$_apiKey&resultType=json&$param=$busStopId';
          final response = await http.get(Uri.parse(url));
          
          if (response.statusCode == 200) {
            // XML이 반환되는 경우(API 에러)를 필터링
            if (response.body.trim().startsWith('<')) {
              debugPrint('⚠️ [BusAPI] XML 응답 수신 ($param): ${response.body.substring(0, 50)}...');
              continue;
            }

            final items = await compute(_parseArrivalJson, response.body);
            if (items.isNotEmpty) {
              debugPrint('✅ [BusAPI] $param 으로 데이터 획득 성공! (${items.length}개)');
              liveArrivals = items.map((item) {
                final lineName = item['LINE_NAME'] ?? item['lineName'] ?? item['SHORT_LINE_NAME'] ?? '버스';
                final remainMinVal = item['REMAIN_MIN'] ?? item['remainMin'] ?? '0';
                final dirEnd = item['DIR_END'] ?? item['dirEnd'] ?? '종점';
                final remainStop = item['REMAIN_STOP'] ?? item['remainStop'] ?? '-';

                return BusRouteInfo(
                  busName: lineName.toString(),
                  busArrivalRemaining: int.tryParse(remainMinVal.toString()) ?? 0,
                  walkTimeRemaining: 0, travelDuration: 15, totalDuration: (int.tryParse(remainMinVal.toString()) ?? 0) + 15,
                  routeDescription: '$dirEnd 방면 ($remainStop구간 전)',
                );
              }).toList();
              break; // 데이터 찾았으면 종료
            }
          }
        }
      } catch (e) { debugPrint('❌ [GJ-BIS] 실시간 조회 에러: $e'); }
    }

    // Step 2: 기점/종점 시간표 정보 추가
    if (stopName != null) {
      final scheduled = await _getScheduledArrivals(stopName);
      for (var s in scheduled) {
        if (!liveArrivals.any((l) => l.busName == s.busName)) {
          liveArrivals.add(s);
        }
      }
    }
    
    return liveArrivals;
  }

  Future<List<BusRouteInfo>> _getScheduledArrivals(String stopName) async {
    final cleanStopName = stopName.split('|')[0].replaceAll(RegExp(r'\(.*\)'), '').replaceAll(' ', '').trim();
    final now = DateTime.now();
    final dayType = now.weekday; 

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
          final dep = DateTime(now.year, now.month, now.day, int.parse(p[0]), int.parse(p[1]));
          
          if (dep.isAfter(now)) {
            final diff = dep.difference(now).inMinutes;
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
    if (_apiKey.isEmpty) return [];
    if (_cachedStations == null) await initStationCache();
    if (_cachedStations == null) return [];

    try {
      return _cachedStations!.map((s) {
        // 💡 [핵심] 실시간 도착 정보 조회에는 STATION_ID가 필요합니다.
        final id = s['STATION_ID']?.toString() ?? s['BUSSTOP_ID']?.toString() ?? '';
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
}
