import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 💡 Atcha의 PlaceEndpoint.swift 설계를 Dart로 포팅
/// 모든 API의 경로와 파라미터 규격을 한곳에서 관리합니다.
class BusApiEndpoint {
  static final String _baseUrl = "http://apis.data.go.kr/6290000/gj_bis";
  static final String _rawKey = (dotenv.env['BUS_SERVICE_KEY'] ?? '').trim();

  /// 💡 serviceKey 내부의 + 가 HTTP query 통신 시 공백으로 변환되는 현상 방지
  static String get formattedKey {
    if (_rawKey.contains('+') && !_rawKey.contains('%2B')) {
      return _rawKey.replaceAll('+', '%2B');
    }
    return _rawKey;
  }

  static Uri arriveInfo(String stopId) {
    final param = stopId.length > 5 ? 'STATION_ID' : 'BUSSTOP_ID';
    return Uri.parse('$_baseUrl/arriveInfo?serviceKey=$formattedKey&resultType=json&$param=$stopId');
  }

  static Uri lineLocation(String lineId) {
    return Uri.parse('$_baseUrl/lineArrivalInfo?serviceKey=$formattedKey&resultType=json&LINE_ID=$lineId');
  }

  static Uri lineSearch(String lineName) {
    return Uri.parse('$_baseUrl/lineInfo?serviceKey=$formattedKey&resultType=json&LINE_NAME=$lineName');
  }

  static Uri linePath(String lineId) {
    return Uri.parse('$_baseUrl/linePathInfo?serviceKey=$formattedKey&resultType=json&LINE_ID=$lineId');
  }

  static Uri lineStation(String lineId) {
    return Uri.parse('$_baseUrl/lineStationInfo?serviceKey=$formattedKey&resultType=json&LINE_ID=$lineId');
  }

  static Uri lineDetail(String lineId) {
    return Uri.parse('$_baseUrl/lineInfo?serviceKey=$formattedKey&resultType=json&LINE_ID=$lineId');
  }

  static Uri stationInfo() {
    return Uri.parse('$_baseUrl/stationInfo?serviceKey=$formattedKey&resultType=json&numOfRows=3000');
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

  static Uri searchBusRoute(String busNumber) {
    // 💡 Gwangju cityCode: 24
    return Uri.parse('https://apis.openapi.sk.com/transit/bus/routes?busNumber=$busNumber&cityCode=24');
  }

  static Uri busRouteDetail(String routeId) {
    return Uri.parse('https://apis.openapi.sk.com/transit/bus/routes/$routeId');
  }
}
