import '../models.dart';

class RoutingService {
  Future<List<BusRouteInfo>> analyzeRoutes({
    required String departLabel,
    required String arriveLabel,
  }) async {
    if (arriveLabel.isEmpty) return [];

    // 연산 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 800));

    final routes = [
      BusRouteInfo(
        busName: '수완03',
        busArrivalRemaining: 7,
        walkTimeRemaining: 3,
        travelDuration: 15,
        routeDescription: '정류장까지 도보 3분',
      ),
      BusRouteInfo(
        busName: '지원151',
        busArrivalRemaining: 4,
        walkTimeRemaining: 4,
        travelDuration: 25,
        routeDescription: '도보 4분',
      ),
      BusRouteInfo(
        busName: '풍암16',
        busArrivalRemaining: 2,
        walkTimeRemaining: 5,
        travelDuration: 18,
        routeDescription: '도보 5분',
      ),
    ];

    // 최종 도착 시간(Total ETA) 기준 정렬
    routes.sort((a, b) => a.totalETA.compareTo(b.totalETA));
    return routes;
  }
}
