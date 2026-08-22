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

  // 🎨 Tmap 헥사 색상 코드를 Flutter Color로 변환
  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFF2563EB);
    try {
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return const Color(0xFF2563EB);
    }
  }

  // Tmap 응답에서 모든 경로와 버스 정보를 추출합니다.
  Map<String, dynamic> parseTmapData(Map<String, dynamic> data) {
    List<RouteSegment> segments = [];
    List<LatLng> stops = [];
    List<BusRouteInfo> busRoutes = [];

    try {
      if (data['metaData'] == null || data['metaData']['plan'] == null) return {};
      
      final plan = data['metaData']['plan'];
      final itineraries = plan['itineraries'] as List;

      // 💡 [개선 1] 소요 시간(totalTime) 기준으로 정렬 후 상위 5개만 선택
      itineraries.sort((a, b) => (a['totalTime'] as num).compareTo(b['totalTime'] as num));
      final topItineraries = itineraries.take(5).toList();
      
      // 1. 추천 경로 리스트 생성
      for (var itinerary in topItineraries) {
        final legs = itinerary['legs'] as List;
        int totalWalkTime = ((itinerary['totalWalkTime'] as num) / 60).round();
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
          walkTimeRemaining: totalWalkTime,
          travelDuration: totalTravelTime - totalWalkTime,
          routeDescription: busNames.isNotEmpty ? '${busNames.join(' → ')} 이용' : '전 구간 도보',
        ));
      }

      // 2. 가장 첫 번째(최적) 경로의 상세 지도 데이터 생성
      if (topItineraries.isNotEmpty) {
        final bestLegs = topItineraries[0]['legs'] as List;
        for (var leg in bestLegs) {
          final mode = leg['mode'];
          
          // 경로 좌표 파싱 (기존 유지)
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

          // 💡 [개선 2] 승차(Start)와 하차(End) 정류장만 마커로 찍기
          if (mode == 'BUS' || mode == 'SUBWAY') {
            if (leg['start'] != null) {
              stops.add(LatLng(double.parse(leg['start']['lat'].toString()), double.parse(leg['start']['lon'].toString())));
            }
            if (leg['end'] != null) {
              stops.add(LatLng(double.parse(leg['end']['lat'].toString()), double.parse(leg['end']['lon'].toString())));
            }
          }

          segments.add(RouteSegment(
            points: points,
            color: mode == 'WALK' ? const Color(0xFF10B981) : _parseColor(leg['routeColor']),
            width: mode == 'WALK' ? 7.0 : 10.0,
          ));
        }
      }
    } catch (e) {
      print('❌ [Tmap] 고정밀 데이터 파싱 에러: $e');
    }

    return {
      'segments': segments,
      'stops': stops,
      'busRoutes': busRoutes,
    };
  }
}
