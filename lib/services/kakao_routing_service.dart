import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class KakaoRoutingService {
  // 💡 명확하게 REST API 키를 사용하도록 수정
  final String _restApiKey = dotenv.env['KAKAO_REST_API_KEY'] ?? '';

  Future<List<LatLng>> getRoadPath(LatLng origin, LatLng destination) async {
    if (_restApiKey.isEmpty) return [];

    try {
      // 카카오 모빌리티 자동차 길찾기 API (도로 매칭을 위해 사용)
      final url = Uri.parse(
        'https://apis-navi.kakaomobility.com/v1/directions?'
        'origin=${origin.longitude},${origin.latitude}&'
        'destination=${destination.longitude},${destination.latitude}&'
        'priority=RECOMMEND'
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $_restApiKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<LatLng> path = [];
        
        final List routes = data['routes'];
        if (routes.isNotEmpty) {
          final List sections = routes[0]['sections'];
          for (var section in sections) {
            final List roads = section['roads'];
            for (var road in roads) {
              final List vertexes = road['vertexes'];
              for (int i = 0; i < vertexes.length; i += 2) {
                // 카카오 API는 [경도, 위도] 순서이므로 반대로 넣습니다.
                path.add(LatLng(vertexes[i + 1].toDouble(), vertexes[i].toDouble()));
              }
            }
          }
        }
        print('🛣️ [KakaoNavi] 도로 매칭 좌표 ${path.length}개 로드 성공');
        return path;
      } else {
        print('❌ [KakaoNavi] API 에러: ${response.body}');
      }
    } catch (e) {
      print('❌ [KakaoNavi] 통신 에러: $e');
    }
    return [];
  }
}
