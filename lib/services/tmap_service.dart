import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../models.dart';

class TmapService {
  final String _appKey = (dotenv.env['TMAP_API_KEY'] ?? '').trim();

  Future<Map<String, dynamic>?> getTransitRoute(LatLng origin, LatLng dest) async {
    if (_appKey.isEmpty) return null;

    try {
      // 💡 [수정] 팀장님이 주신 최신 샘플 URL 및 바디 규격을 적용합니다.
      final url = Uri.parse('https://apis.openapi.sk.com/transit/routes');
      
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'appKey': _appKey,
          'content-type': 'application/json',
        },
        body: json.encode({
          "startX": origin.longitude.toString(),
          "startY": origin.latitude.toString(),
          "endX": dest.longitude.toString(),
          "endY": dest.latitude.toString(),
          "count": 5,
          "lang": 0,
          "format": "json"
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ [Tmap] API 에러 (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('❌ [Tmap] 통신 에러: $e');
    }
    return null;
  }

  // 💡 [추가] Tmap 보행자 경로 API: 정확한 도보 시간 계산
  Future<int> getWalkingDuration(LatLng origin, LatLng dest) async {
    if (_appKey.isEmpty) return 0;
    try {
      final url = Uri.parse('https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1');
      final response = await http.post(
        url,
        headers: {'appKey': _appKey, 'content-type': 'application/json'},
        body: json.encode({
          "startX": origin.longitude.toString(),
          "startY": origin.latitude.toString(),
          "endX": dest.longitude.toString(),
          "endY": dest.latitude.toString(),
          "startName": "출발지",
          "endName": "정류장"
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final int duration = ((data['features'][0]['properties']['totalTime'] as num) / 60).round();
        return duration;
      }
    } catch (e) {
      print('❌ [Tmap] 도보 시간 계산 실패: $e');
    }
    return 3; // 기본값 3분
  }

  // 🎨 Tmap 헥사 색상 코드를 Flutter Color로 변환
  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFF2563EB);
    try {
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return const Color(0xFF2563EB);
    }
  }

  // 💡 특정 경로(itinerary)의 상세 지도 데이터만 추출하는 기능 분리
  Map<String, dynamic> parseItineraryPath(dynamic itinerary) {
    List<RouteSegment> segments = [];
    List<LatLng> allBusStops = []; // 모든 버스 정류장 임시 보관
    
    try {
      final List legs = itinerary['legs'];
      for (var leg in legs) {
        final mode = leg['mode'];
        final List<LatLng> points = [];
        
        if (leg['passShape'] != null && leg['passShape']['linestring'] != null) {
          final String linestring = leg['passShape']['linestring'];
          final parts = linestring.split(' ');
          for (var p in parts) {
            final coords = p.split(',');
            if (coords.length == 2) {
              points.add(LatLng(double.parse(coords[1]), double.parse(coords[0])));
            }
          }
        }

        if (mode == 'BUS' || mode == 'SUBWAY') {
          if (leg['start'] != null) {
            allBusStops.add(LatLng(double.parse(leg['start']['lat'].toString()), double.parse(leg['start']['lon'].toString())));
          }
          if (leg['end'] != null) {
            allBusStops.add(LatLng(double.parse(leg['end']['lat'].toString()), double.parse(leg['end']['lon'].toString())));
          }
        }

        segments.add(RouteSegment(
          points: points,
          color: mode == 'WALK' ? const Color(0xFF10B981) : _parseColor(leg['routeColor']),
          width: mode == 'WALK' ? 7.0 : 10.0,
        ));
      }
    } catch (e) {
      print('❌ [Tmap] 개별 경로 파싱 에러: $e');
    }

    // 💡 [핵심 개선] 처음 탑승, 환승, 마지막 하차 정류장을 모두 추출
    List<Map<String, dynamic>> filteredStops = [];
    
    if (allBusStops.isNotEmpty) {
      // 1. 첫 승차
      filteredStops.add({'latlng': allBusStops.first, 'type': 'boarding'});
      
      // 2. 환승 지점 검색 (중간에 있는 모든 정류소들)
      if (allBusStops.length > 2) {
        for (int i = 1; i < allBusStops.length - 1; i++) {
          filteredStops.add({'latlng': allBusStops[i], 'type': 'transfer'});
        }
      }
      
      // 3. 최종 하차
      if (allBusStops.length > 1) {
        filteredStops.add({'latlng': allBusStops.last, 'type': 'alighting'});
      }
    }

    return {'segments': segments, 'stops': filteredStops};
  }

  // Tmap 응답에서 모든 경로와 버스 정보를 추출합니다.
  Map<String, dynamic> parseTmapData(Map<String, dynamic> data) {
    List<BusRouteInfo> busRoutes = [];
    List<dynamic> rawItineraries = [];
    String? errorMessage;

    try {
      // 💡 [에러 핸들링 추가] result 코드가 있는 경우 분석
      if (data['result'] != null) {
        final int code = data['result']['code'] ?? 0;
        switch (code) {
          case 11: errorMessage = '출발지와 도착지가 너무 가깝습니다. (도보 권장)'; break;
          case 12: errorMessage = '출발지 주변에 버스 정류장이 없습니다.'; break;
          case 13: errorMessage = '도착지 주변에 버스 정류장이 없습니다.'; break;
          case 14: errorMessage = '현재 이용 가능한 대중교통 경로가 없습니다.'; break;
          case 21: case 22: errorMessage = '입력 값이 올바르지 않습니다. (시스템 오류)'; break;
          case 23: errorMessage = '서비스 지원 지역이 아닙니다.'; break;
          case 31: case 32: errorMessage = '서버 응답이 지연되고 있습니다. 잠시 후 시도해 주세요.'; break;
        }
      }

      if (data['metaData'] == null || data['metaData']['plan'] == null) {
        return {'errorMessage': errorMessage ?? '경로를 찾을 수 없습니다.'};
      }
      
      final plan = data['metaData']['plan'];
      final itineraries = plan['itineraries'] as List;

      itineraries.sort((a, b) => (a['totalTime'] as num).compareTo(b['totalTime'] as num));
      rawItineraries = itineraries.take(5).toList();
      
      for (var itinerary in rawItineraries) {
        final legs = itinerary['legs'] as List;
        
        // 💡 [수정] 첫 번째 도보 구간의 시간만 추출
        int firstWalkTime = 0;
        if (legs.isNotEmpty && legs[0]['mode'] == 'WALK') {
          firstWalkTime = ((legs[0]['duration'] as num) / 60).round();
        }

        int totalTravelTime = ((itinerary['totalTime'] as num) / 60).round();

        List<String> busNames = [];
        for (var leg in legs) {
          if (leg['mode'] == 'BUS' || leg['mode'] == 'SUBWAY') {
            final name = leg['route'] ?? leg['lane']?[0]['route'] ?? '대중교통';
            busNames.add(name.toString().replaceAll('간선:', '').replaceAll('지선:', ''));
          }
        }

        busRoutes.add(BusRouteInfo(
          busName: busNames.isNotEmpty ? busNames.first : '도보',
          busArrivalRemaining: 5,
          walkTimeRemaining: firstWalkTime,
          travelDuration: totalTravelTime - firstWalkTime,
          totalDuration: totalTravelTime,
          routeDescription: busNames.isNotEmpty ? '${busNames.join(' → ')} 이용' : '전 구간 도보',
        ));
      }
    } catch (e) {
      print('❌ [Tmap] 메인 데이터 파싱 에러: $e');
    }

    return {
      'busRoutes': busRoutes,
      'rawItineraries': rawItineraries,
      'errorMessage': errorMessage, // 💡 추가
      'segments': [],
      'stops': [],
    };
  }
}
