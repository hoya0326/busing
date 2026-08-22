import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class KakaoLocalService {
  final String _restApiKey = dotenv.env['KAKAO_REST_API_KEY'] ?? '';

  // 📍 카카오맵 내부 POI 데이터를 검색하여 지도 아이콘과 100% 일치하는 좌표를 가져옵니다.
  Future<Map<String, dynamic>?> getExactBusStopLocation(String stationName, double lat, double lng) async {
    if (_restApiKey.isEmpty) return null;

    try {
      // 💡 수석 개발자의 팁: 이름 뒤에 '정류장'을 붙여 검색하면 카카오 내부 POI 좌표가 정확히 잡힙니다.
      final query = stationName.contains('정류장') ? stationName : '$stationName 정류장';
      final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/keyword.json?'
        'query=${Uri.encodeComponent(query)}&x=$lng&y=$lat&radius=500&sort=distance'
      );

      final response = await http.get(url, headers: {'Authorization': 'KakaoAK $_restApiKey'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List documents = data['documents'];
        
        // 검색 결과 중 '교통,수송 > 버스 > 버스정류장' 카테고리만 필터링
        final busStops = documents.where((doc) => doc['category_name'].contains('버스정류장')).toList();

        if (busStops.isNotEmpty) {
          final stop = busStops[0];
          print('🎯 [KakaoPOI] 지도 아이콘 좌표 매칭 성공: ${stop['place_name']}');
          return {
            'name': stop['place_name'],
            'lat': double.parse(stop['y']),
            'lng': double.parse(stop['x']),
          };
        }
      }
    } catch (e) {
      print('❌ [KakaoPOI] 검색 실패: $e');
    }
    return null;
  }

  // 💡 [추가] 키워드로 장소 검색 (출발지/목적지 입력용)
  Future<List<Map<String, dynamic>>> searchKeywords(String query) async {
    if (_restApiKey.isEmpty) return [];
    try {
      final url = Uri.parse('https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeComponent(query)}&size=10');
      final response = await http.get(url, headers: {'Authorization': 'KakaoAK $_restApiKey'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List docs = data['documents'];
        return docs.map((d) => {
          'name': d['place_name'],
          'address': d['address_name'],
          'lat': double.parse(d['y']),
          'lng': double.parse(d['x']),
        }).toList();
      }
    } catch (e) {
      print('❌ [Search] 키워드 검색 실패: $e');
    }
    return [];
  }
}
