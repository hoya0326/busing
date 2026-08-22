import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xml/xml.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart'; // 💡 추가
import '../models.dart';

class BusApiService {
  // 광주광역시 공공데이터 통합 엔드포인트
  final String _baseUrl = "http://api.gwangju.go.kr/xmlConfInfo.do";
  final String _apiKey = dotenv.env['BUS_SERVICE_KEY'] ?? '';

  // 📍 1. 주변 정류소 찾기 (좌표 및 이름 포함)
  Future<Map<String, dynamic>?> getNearbyStation(double lat, double lng) async {
    if (_apiKey.isEmpty) return null;

    try {
      final url = '$_baseUrl?serviceKey=$_apiKey&act=STATION_LIST&lat=$lat&lng=$lng';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final station = document.findAllElements('STATION_LIST').firstOrNull;
        
        if (station != null) {
          final id = station.getElement('STATION_ID')?.innerText;
          final name = station.getElement('BUSSTOP_NAME')?.innerText ?? '알 수 없음';
          final sLat = double.tryParse(station.getElement('LAT')?.innerText ?? '0') ?? 0.0;
          final sLng = double.tryParse(station.getElement('LONG')?.innerText ?? '0') ?? 0.0;
          
          return {
            'id': id,
            'name': name,
            'lat': sLat,
            'lng': sLng,
          };
        }
      }
    } catch (e) {
      print('❌ [BusAPI] 정류소 검색 실패: $e');
    }
    return null;
  }

  // 📍 2. 특정 정류소의 실시간 도착 정보 조회 (버스 도착정보 서비스 API)
  Future<List<BusRouteInfo>> getArrivalInfo(String stationId) async {
    if (_apiKey.isEmpty) return [];

    try {
      final url = '$_baseUrl?serviceKey=$_apiKey&act=BUS_ARR_INFO&STATION_ID=$stationId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return _parseArrivalXml(response.body);
      }
    } catch (e) {
      print('❌ [BusAPI] 도착 정보 조회 실패: $e');
    }
    return [];
  }

  List<BusRouteInfo> _parseArrivalXml(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final items = document.findAllElements('BUS_ARR_INFO');

      return items.map((node) {
        final busName = node.getElement('LINE_NAME')?.innerText ?? '알 수 없음';
        final remainMin = int.tryParse(node.getElement('REMAIN_MIN')?.innerText ?? '0') ?? 0;
        final stationName = node.getElement('BUSSTOP_NAME')?.innerText ?? '';

        return BusRouteInfo(
          busName: busName,
          busArrivalRemaining: remainMin,
          walkTimeRemaining: 3, 
          travelDuration: 15,
          totalDuration: remainMin + 15 + 3,
          routeDescription: '$stationName 정류장 승차', // 문구 수정
        );
      }).toList();
    } catch (e) {
      print('❌ [BusAPI] XML 파싱 에러: $e');
      return [];
    }
  }

  // 📍 3. 노선의 실제 주행 경로 좌표 리스트 조회 (버스 노선정보 서비스 API)
  Future<List<LatLng>> getRoutePathNodes(String lineId) async {
    if (_apiKey.isEmpty) return [];

    try {
      // 광주 API: 특정 노선의 전체 경유 노드(좌표) 목록 조회
      final url = '$_baseUrl?serviceKey=$_apiKey&act=ROUTE_NODE_LIST&LINE_ID=$lineId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('ROUTE_NODE_LIST');

        return items.map((node) {
          final lat = double.tryParse(node.getElement('LAT')?.innerText ?? '0') ?? 0.0;
          final lng = double.tryParse(node.getElement('LONG')?.innerText ?? '0') ?? 0.0;
          return LatLng(lat, lng);
        }).where((latLng) => latLng.latitude != 0).toList();
      }
    } catch (e) {
      print('❌ [BusAPI] 노선 경로 조회 실패: $e');
    }
    return [];
  }

  // 📍 [추가] 광주광역시 전체 정류소 목록을 가져와서 분석합니다.
  Future<List<BusStop>> fetchAllGwangjuStations() async {
    if (_apiKey.isEmpty) return [];

    try {
      final url = '$_baseUrl?serviceKey=$_apiKey&act=STATION_LIST';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('STATION_LIST');

        return items.map((node) {
          return BusStop(
            id: node.getElement('STATION_ID')?.innerText ?? '',
            name: node.getElement('BUSSTOP_NAME')?.innerText ?? '알 수 없음',
            lat: double.tryParse(node.getElement('LAT')?.innerText ?? '0') ?? 0.0,
            lng: double.tryParse(node.getElement('LONG')?.innerText ?? '0') ?? 0.0,
          );
        }).where((s) => s.lat != 0).toList();
      }
    } catch (e) {
      print('❌ [BusAPI] 전체 정류소 분석 실패: $e');
    }
    return [];
  }
}
