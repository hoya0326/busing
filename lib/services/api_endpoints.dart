import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 💡 Atcha의 PlaceEndpoint.swift 설계를 Dart로 포팅
/// 모든 API의 경로와 파라미터 규격을 한곳에서 관리합니다.
class BusApiEndpoint {
  static final String _baseUrl = "http://apis.data.go.kr/6290000/gj_bis"; // 💡 trailing slash 제거
  static final String _key = (dotenv.env['BUS_SERVICE_KEY'] ?? '').trim();

  static Uri arriveInfo(String stopId) {
    // STATION_ID 인지 BUSSTOP_ID 인지 자동으로 판단하여 최적의 파라미터 생성
    final param = stopId.length > 5 ? 'STATION_ID' : 'BUSSTOP_ID';
    return Uri.parse('$_baseUrl/arriveInfo?serviceKey=$_key&resultType=json&$param=$stopId');
  }

  static Uri stationInfo() {
    return Uri.parse('$_baseUrl/stationInfo?serviceKey=$_key&resultType=json&numOfRows=3000');
  }
}

class TmapEndpoint {
  static final String _key = (dotenv.env['TMAP_API_KEY'] ?? '').trim();

  static Map<String, String> headers() => {
    'accept': 'application/json',
    'appKey': _key,
    'content-type': 'application/json',
  };

  static Uri transitRoutes() => Uri.parse('https://apis.openapi.sk.com/transit/routes');
}
