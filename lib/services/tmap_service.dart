import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../models.dart';
import 'api_endpoints.dart'; // 💡 추가

class TmapService {
  Future<Map<String, dynamic>?> getTransitRoute(LatLng origin, LatLng dest) async {
    try {
      final response = await http.post(
        TmapEndpoint.transitRoutes(),
        headers: TmapEndpoint.headers(),
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

  // 💡 [수석 개발자] Tmap 보행자 경로 API: 문 앞부터 정류장까지 진짜 도보 시간 계산
  Future<int> getWalkingDuration(LatLng origin, LatLng dest) async {
    try {
      final response = await http.post(
        Uri.parse('https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1'),
        headers: TmapEndpoint.headers(),
        body: json.encode({
          "startX": origin.longitude.toString(),
          "startY": origin.latitude.toString(),
          "endX": dest.longitude.toString(),
          "endY": dest.latitude.toString(),
          "startName": "내 위치",
          "endName": "정류장"
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final num totalTimeSeconds = data['features'][0]['properties']['totalTime'] ?? 0;
        // 초 단위를 분 단위로 반환 (최소 1분 보장)
        int minutes = (totalTimeSeconds / 60).ceil();
        return minutes > 0 ? minutes : 1;
      }
    } catch (e) {
      print('❌ [Tmap] 도보 시간 정밀 계산 실패: $e');
    }
    return 3; // 기본값 3분
  }

  // 💡 [수석 개발자] Tmap 대중교통 API를 활용하여 버스 노선의 전체 궤적(Shape)을 가져옵니다.
  Future<List<LatLng>> getBusLinePath(String busName) async {
    final cleanBusName = busName.replaceAll(RegExp(r'[^0-9가-힣]'), '');
    debugPrint('📡 [Tmap] $cleanBusName 노선 ID 조회 중...');

    try {
      // 1. 노선 이름으로 Tmap 전용 RouteID 조회 (광주 시티코드 24)
      var response = await http.get(TmapEndpoint.searchBusRoute(cleanBusName), headers: TmapEndpoint.headers());
      
      // 검색 결과가 없으면 번(number)을 떼고 재시도
      if (response.statusCode != 200 || json.decode(response.body)['busRouteList'] == null) {
        final simplerName = cleanBusName.replaceAll('번', '');
        if (simplerName != cleanBusName) {
          debugPrint('🔄 [Tmap] $cleanBusName 결과 없음, $simplerName 으로 재시도...');
          response = await http.get(TmapEndpoint.searchBusRoute(simplerName), headers: TmapEndpoint.headers());
        }
      }

      if (response.statusCode != 200) return [];
      
      final searchData = json.decode(response.body);
      final List? routes = searchData['busRouteList'];
      if (routes == null || routes.isEmpty) {
        debugPrint('⚠️ [Tmap] $cleanBusName 노선을 찾을 수 없습니다.');
        return [];
      }

      // 💡 [수석 개발자] 여러 결과 중 가장 적합한 노선 ID 선택 (광주 지역 최우선 및 이름 유사도 체크)
      final matchedRoute = routes.firstWhere(
        (r) => r['routeName'].toString().contains(cleanBusName),
        orElse: () => routes.first,
      );
      
      final String routeId = matchedRoute['routeId'].toString();
      debugPrint('✅ [Tmap] 노선 ID 획득: $routeId (${matchedRoute['routeName']})');

      // 2. 노선 상세 정보(Shape 포함) 조회
      final detailRes = await http.get(TmapEndpoint.busRouteDetail(routeId), headers: TmapEndpoint.headers());
      if (detailRes.statusCode != 200) return [];

      final detailData = json.decode(detailRes.body);
      final String? linestring = detailData['passShape']?['linestring'];
      
      if (linestring == null) {
        debugPrint('⚠️ [Tmap] 노선 형상 데이터(linestring)가 없습니다.');
        return [];
      }

      final List<LatLng> points = [];
      // Tmap 특유의 'lng,lat lng,lat' 또는 'lng,lat|lng,lat' 형식 대응
      final delimiters = RegExp(r'[ |]');
      final parts = linestring.split(delimiters);
      
      for (var p in parts) {
        final coords = p.split(',');
        if (coords.length == 2) {
          final lng = double.tryParse(coords[0]);
          final lat = double.tryParse(coords[1]);
          if (lat != null && lng != null && lat != 0) {
            points.add(LatLng(lat, lng));
          }
        }
      }
      
      debugPrint('✅ [Tmap] 노선 경로 획득 완료: ${points.length}개 좌표');
      return points;
    } catch (e) {
      debugPrint('❌ [Tmap] 노선 경로 조회 예외: $e');
    }
    return [];
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

  // 💡 [수석 개발자] Tmap 보행자 경로 API: 좌표 리스트(Shape) 가져오기
  Future<List<LatLng>> getWalkingPath(LatLng origin, LatLng dest) async {
    try {
      final response = await http.post(
        Uri.parse('https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1&format=json'),
        headers: TmapEndpoint.headers(),
        body: json.encode({
          "startX": origin.longitude.toString(),
          "startY": origin.latitude.toString(),
          "endX": dest.longitude.toString(),
          "endY": dest.latitude.toString(),
          "startName": "출발지",
          "endName": "도착지",
          "searchOption": "0",
          "reqCoordType": "WGS84GEO",
          "resCoordType": "WGS84GEO",
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<LatLng> points = [];
        final List features = data['features'] ?? [];
        
        for (var f in features) {
          final geometry = f['geometry'];
          if (geometry != null && geometry['type'] == 'LineString') {
            final List coords = geometry['coordinates'];
            for (var c in coords) {
              // c[0]: lon, c[1]: lat
              final lat = c[1].toDouble();
              final lon = c[0].toDouble();
              final newPoint = LatLng(lat, lon);
              if (points.isEmpty || points.last != newPoint) {
                points.add(newPoint);
              }
            }
          }
        }
        
        if (points.isNotEmpty) {
          debugPrint('✅ [Tmap] 보행자 경로 획득: ${points.length}개 좌표');
          return points;
        }
      } else {
        debugPrint('❌ [Tmap] 도보 API 응답 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Tmap] 도보 경로 예외: $e');
    }
    return [origin, dest]; 
  }

  // 💡 특정 경로(itinerary)의 상세 지도 데이터만 추출하는 기능 분리
  Map<String, dynamic> parseItineraryPath(dynamic itinerary) {
    List<RouteSegment> segments = [];
    List<MapPin> stops = []; // 모든 버스 정류장 정밀 관리
    
    try {
      final List legs = itinerary['legs'];
      for (var leg in legs) {
        final mode = leg['mode'];
        final List<LatLng> points = [];
        
        // 1. 경로 선(Shape) 파싱
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

        if (points.isEmpty && leg['start'] != null && leg['end'] != null) {
          points.add(LatLng(double.parse(leg['start']['lat'].toString()), double.parse(leg['start']['lon'].toString())));
          points.add(LatLng(double.parse(leg['end']['lat'].toString()), double.parse(leg['end']['lon'].toString())));
        }

        // 2. 경유 정류장(passStopList) 파싱
        if (mode == 'BUS' || mode == 'SUBWAY') {
          if (leg['passStopList'] != null && leg['passStopList']['stations'] != null) {
            final List stations = leg['passStopList']['stations'];
            for (int i = 0; i < stations.length; i++) {
              final s = stations[i];
              final lat = double.parse(s['lat'].toString());
              final lon = double.parse(s['lon'].toString());
              
              String type = 'pass';
              if (i == 0) type = 'boarding';
              else if (i == stations.length - 1) type = 'alighting';

              // 💡 중복 위치 처리 (환승 정류장 감지)
              final existingIndex = stops.indexWhere((p) => (p.x - lat).abs() < 0.0001 && (p.y - lon).abs() < 0.0001);
              if (existingIndex != -1) {
                // 이미 해당 위치에 핀이 있다면 '환승'으로 업그레이드
                stops[existingIndex] = MapPin(
                  x: lat, y: lon,
                  type: PinType.busStop,
                  address: 'transfer',
                  label: s['stationName'],
                );
              } else {
                stops.add(MapPin(
                  x: lat, y: lon,
                  type: type == 'pass' ? PinType.passStop : PinType.busStop,
                  address: type,
                  label: s['stationName'],
                ));
              }
            }
          }
        }

        segments.add(RouteSegment(
          id: 'seg_${segments.length}_${mode}_${points.length}',
          points: points,
          color: mode == 'WALK' ? const Color(0xFF34D399) : _parseColor(leg['routeColor']),
          width: mode == 'WALK' ? 5.0 : 10.0,
          strokeStyle: mode == 'WALK' ? StrokeStyle.dot : StrokeStyle.solid,
        ));
      }
    } catch (e) {
      print('❌ [Tmap] 개별 경로 파싱 에러: $e');
    }

    return {'segments': segments, 'stops': stops};
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

      itineraries.sort((a, b) {
        final aTime = (a['totalTime'] ?? 999999) as num;
        final bTime = (b['totalTime'] ?? 999999) as num;
        return aTime.compareTo(bTime);
      });
      rawItineraries = itineraries.take(5).toList();
      
      for (var itinerary in rawItineraries) {
        final legs = itinerary['legs'] as List;
        
        // 💡 [수정] 첫 번째 도보 구간의 시간만 추출
        int firstWalkTime = 0;
        if (legs.isNotEmpty && legs[0]['mode'] == 'WALK') {
          final duration = legs[0]['duration'];
          if (duration != null) {
            firstWalkTime = ((duration as num) / 60).round();
          }
        }

        final totalTimeValue = itinerary['totalTime'];
        int totalTravelTime = 0;
        if (totalTimeValue != null) {
          totalTravelTime = ((totalTimeValue as num) / 60).round();
        }

        List<String> busNames = [];
        String? firstStopName;
        LatLng? firstStopLatLng;
        List<TransportLeg> routeLegs = []; // 💡 Atcha 포팅

        for (var leg in legs) {
          final modeStr = leg['mode'];
          final mode = modeStr == 'WALK' ? TransportMode.walk : 
                       (modeStr == 'BUS' ? TransportMode.bus : TransportMode.subway);
          
          final int duration = ((leg['duration'] as num? ?? 0) / 60).round();
          
          routeLegs.add(TransportLeg(
            mode: mode,
            durationMinutes: duration,
            routeName: leg['route'] ?? leg['lane']?[0]['route'],
            startStopName: leg['start']?['name'],
            endStopName: leg['end']?['name'],
          ));

          if (leg['mode'] == 'BUS' || leg['mode'] == 'SUBWAY') {
            final name = leg['route'] ?? leg['lane']?[0]['route'] ?? '대중교통';
            busNames.add(name.toString().replaceAll('간선:', '').replaceAll('지선:', ''));
            if (firstStopName == null && leg['start'] != null) {
              firstStopName = leg['start']['name'];
              firstStopLatLng = LatLng(
                double.parse(leg['start']['lat'].toString()),
                double.parse(leg['start']['lon'].toString()),
              );
            }
          }
        }

        busRoutes.add(BusRouteInfo(
          busName: busNames.isNotEmpty ? busNames.first : '도보',
          busArrivalRemaining: -1, // 💡 기본값을 -1(정보 없음)로 변경
          walkTimeRemaining: firstWalkTime,
          travelDuration: totalTravelTime - firstWalkTime,
          totalDuration: totalTravelTime,
          routeDescription: busNames.isNotEmpty ? '${busNames.join(' → ')} 이용' : '전 구간 도보',
          startStopName: firstStopName,
          startStopLatLng: firstStopLatLng,
          legs: routeLegs, // 💡 추가됨
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
