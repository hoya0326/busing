import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart'; // 💡 추가

// ── 지도 관련 모델 ──

// 지도상에서 위치를 구분하는 유형입니다.
enum PinType { depart, arrive, busStop, passStop } // 💡 passStop 추가

// 지도의 좌표와 해당 위치의 성격을 정의합니다.
class MapPin {
  final double x;
  final double y;
  final PinType type;
  final String? address; // 💡 장소 명칭 등으로 활용
  final String? label;   // 💡 추가: 정류장 이름 등 UI 표시용

  MapPin({
    required this.x,
    required this.y,
    required this.type,
    this.address,
    this.label,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'type': type.name,
    'address': address,
    'label': label,
  };
  
  factory MapPin.fromJson(Map<String, dynamic> json) => MapPin(
    x: json['x'],
    y: json['y'],
    type: PinType.values.firstWhere((e) => e.name == json['type']),
    address: json['address'],
    label: json['label'],
  );
}

// ── 루틴 및 일정 모델 ──

// 사용자가 설정한 정기 이동 정보를 담습니다.
class Routine {
  final int id;
  final String time;
  final String from;
  final String to;
  final String bus;
  bool enabled;

  Routine({
    required this.id,
    required this.time,
    required this.from,
    required this.to,
    required this.bus,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time,
    'from': from,
    'to': to,
    'bus': bus,
    'enabled': enabled,
  };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
    id: json['id'],
    time: json['time'],
    from: json['from'],
    to: json['to'],
    bus: json['bus'],
    enabled: json['enabled'] ?? true,
  );
}

// ── 장소 모델 ──

class Place {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String address;

  Place({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lat': lat,
    'lng': lng,
    'address': address,
  };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    id: json['id'],
    name: json['name'],
    lat: json['lat'],
    lng: json['lng'],
    address: json['address'],
  );
}

// ── 💡 Atcha의 LastRoute.swift 포팅 ──
class LastRoute {
  final String id;
  final DateTime departureTime;
  final int totalTime;
  final int totalWalkTime;
  final int totalDistance;
  final int totalWalkDistance;
  final List<TransportLeg> legs;

  LastRoute({
    required this.id,
    required this.departureTime,
    required this.totalTime,
    required this.totalWalkTime,
    required this.totalDistance,
    required this.totalWalkDistance,
    required this.legs,
  });

  /// 💡 Atcha의 요약 로직 포팅
  String? getRouteSummary() {
    final rideLegs = legs.where((leg) => leg.mode != TransportMode.walk).toList();
    if (rideLegs.isEmpty) return null;
    List<String> names = [];
    for (var leg in rideLegs) {
      if (leg.startStopName != null) names.add(leg.startStopName!);
    }
    if (rideLegs.last.endStopName != null) {
      names.add(rideLegs.last.endStopName!);
    }
    return names.isEmpty ? null : names.join(' → ');
  }
}

// ── 💡 Atcha의 RoutePoint.swift 포팅 ──
class RoutePoint {
  final String name;
  final LatLng coordinate;
  RoutePoint({required this.name, required this.coordinate});
}

// ── 💡 Atcha의 LastTrainActivityAttributes.swift 포팅 ──
// 홈 화면 위젯 및 잠금 화면 라이브 상태를 정의합니다.
enum ActivityUrgency { relaxed, caution, imminent }
enum ActivityStatus { active, missed, serviceEnded }

class ActivityContentState {
  final DateTime departureTime;
  final ActivityUrgency urgency;
  final ActivityStatus status;

  ActivityContentState({
    required this.departureTime,
    required this.urgency,
    required this.status,
  });
}

// ── 알고리즘 및 결과 모델 ──

// 💡 Atcha의 TransportMode.swift 포팅
enum TransportMode { walk, bus, subway, unknown }

// 💡 Atcha의 TransportLeg.swift 포팅
// 경로의 각 구간(도보, 탑승 등)을 세밀하게 정의합니다.
class TransportLeg {
  final TransportMode mode;
  final int durationMinutes;
  final String? routeName;
  final String? startStopName;
  final String? endStopName;

  TransportLeg({
    required this.mode,
    required this.durationMinutes,
    this.routeName,
    this.startStopName,
    this.endStopName,
  });
}

// 도보와 버스 타이밍을 분석한 결과 상태입니다.
enum RouteStatus { 
  safe,    // 🟢 안정: 여유롭게 탑승 가능
  tight,   // 🟡 촉박: 서둘러야 탑승 가능
  hard,    // 🔴 어려움: 현재 버스 탑승 불가, 다음 버스 권장
  noInfo,  // ⚪ 정보 없음: 실시간 정보를 불러오지 못함 (Atcha 포팅)
  ended    // 🌙 종료: 금일 운행 종료 (KST 기준 심야)
}

// 버스 노선별 상세 분석 정보와 추천 순위를 결정하는 데이터 구조입니다.
/// 💡 Atcha의 LastRoute.swift 포팅: 전체 도보 시간 및 거리 정보 포함
class BusRouteInfo {
  final String busName;           // 버스 번호 (예: 수완03)
  int busArrivalRemaining;        // 버스 정류장 도착까지 남은 시간 (분) - 💡 가변형으로 변경
  int walkTimeRemaining;          // 정류장까지 걷는 시간 (분) - 💡 가변형으로 변경
  final int travelDuration;       // 버스 탑승 후 목적지까지 주행 시간 (분)
  final int totalDuration;        // 총 소요 시간
  final String routeDescription;  // 경로 상세 설명
  final String? startStopName;    // 출발 정류장 이름
  final LatLng? startStopLatLng;  // 💡 추가: 출발 정류장 좌표
  final List<TransportLeg> legs;  // 💡 추가: 세부 구간 정보 (Atcha 포팅)
  
  /// 💡 Atcha 포팅: 전체 경로의 도보 정보
  final int totalWalkTimeSeconds;
  final int totalWalkDistanceMeters;

  // ── 알고리즘 연산 결과 ──
  late int syncMargin;      // 💡 가변형으로 변경
  late RouteStatus status;  // 💡 가변형으로 변경
  late int totalETA;        // 💡 가변형으로 변경

  BusRouteInfo({
    required this.busName,
    required this.busArrivalRemaining,
    required this.walkTimeRemaining,
    required this.travelDuration,
    required this.totalDuration,
    required this.routeDescription,
    this.startStopName,
    this.startStopLatLng,
    this.legs = const [], // 💡 추가됨
    this.totalWalkTimeSeconds = 0,
    this.totalWalkDistanceMeters = 0,
  }) {
    updateCalculatedFields();
  }

  /// 💡 [Request 2] Atcha의 요약 로직 포팅
  /// 도보 구간을 제외하고 "탑승지 → 환승지 → 하차지" 형태로 요약합니다.
  String? getRouteSummary() {
    // 1. 도보(.walk)가 아닌 구간만 필터링
    final rideLegs = legs.where((leg) => leg.mode != TransportMode.walk).toList();
    
    if (rideLegs.isEmpty) return null;

    List<String> names = [];
    
    // 2. 각 탑승 구간의 시작점 이름 수집
    for (var leg in rideLegs) {
      if (leg.startStopName != null) names.add(leg.startStopName!);
    }
    
    // 3. 마지막 구간의 도착점 이름 추가
    if (rideLegs.last.endStopName != null) {
      names.add(rideLegs.last.endStopName!);
    }

    return names.isEmpty ? null : names.join(' → ');
  }

  // 💡 알고리즘 연산 결과 업데이트 (Atcha 벤치마킹)
  void updateCalculatedFields() {
    // 0. 운행 종료 또는 정보 없음 처리
    if (busArrivalRemaining == -1) {
      syncMargin = -999;
      status = RouteStatus.noInfo;
      totalETA = totalDuration; 
      return;
    }

    if (busArrivalRemaining == -2) { // 💡 명시적인 운행 종료
      syncMargin = -999;
      status = RouteStatus.ended;
      totalETA = totalDuration;
      return;
    }

    // 1. 도보-버스 싱크로율 연산: (버스 도착 시간) - (도보 소요 시간)
    syncMargin = busArrivalRemaining - walkTimeRemaining;

    // 2. 신호등 알고리즘 적용 (Atcha 기준: 3분 여유)
    if (syncMargin >= 3) {
      status = RouteStatus.safe;    // 🟢 안정: 뛰지 않아도 탑승 가능
    } else if (syncMargin >= 0) {
      status = RouteStatus.tight;   // 🟡 촉박: 서둘러야 탑승 가능 (3분 이내)
    } else {
      status = RouteStatus.hard;    // 🔴 어려움: 지금 출발해도 놓칠 확률 높음
    }

    // 3. 목적지 최종 도착 시간 계산
    // 놓칠 상황(🔴)이면 다음 버스(평균 15분 대기)를 탄다고 가정하여 계산 (Atcha 로직 응용)
    if (status == RouteStatus.hard) {
      totalETA = busArrivalRemaining + 15 + travelDuration;
    } else {
      totalETA = walkTimeRemaining + (syncMargin > 0 ? syncMargin : 0) + travelDuration;
    }
  }

  // 상태에 따른 대표 색상을 반환합니다.
  Color get statusColor {
    switch (status) {
      case RouteStatus.safe: return const Color(0xFF10B981);
      case RouteStatus.tight: return const Color(0xFFF59E0B);
      case RouteStatus.hard: return const Color(0xFFDC2626);
      case RouteStatus.noInfo: return const Color(0xFF9CA3AF); 
      case RouteStatus.ended: return const Color(0xFF1F2937); // 아주 어두운 색
    }
  }

  // 상태에 따른 문구 정보를 반환합니다.
  String get statusText {
    switch (status) {
      case RouteStatus.safe: return '안정 탑승';
      case RouteStatus.tight: return '서두르세요';
      case RouteStatus.hard: return '탑승 어려움';
      case RouteStatus.noInfo: return '정보 없음';
      case RouteStatus.ended: return '운행 종료';
    }
  }
}

// ── 버스 노선 상세 정보 (정류장 목록용) ──
class BusLineStation {
  final String stationName;
  final String stationId;
  final String? arsId;
  final double lat;
  final double lng;
  final String firstBusTime;
  final String lastBusTime;
  final bool isTransfer;
  final bool hasBusNow; // 실시간 버스 위치 표시용

  BusLineStation({
    required this.stationName,
    required this.stationId,
    this.arsId,
    required this.lat,
    required this.lng,
    this.firstBusTime = '--:--',
    this.lastBusTime = '--:--',
    this.isTransfer = false,
    this.hasBusNow = false,
  });
}

// ── 버스 정류소 데이터 모델 ──

class BusStop {
  final String id;
  final String name;
  final double lat;
  final double lng;

  BusStop({required this.id, required this.name, required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'lat': lat, 'lng': lng};
  factory BusStop.fromJson(Map<String, dynamic> json) => BusStop(
    id: json['id'],
    name: json['name'],
    lat: json['lat'],
    lng: json['lng'],
  );
}

// ── 경로 시각화 모델 ──

class RouteSegment {
  final String id;
  final List<LatLng> points;
  final Color color;
  final double width;
  final StrokeStyle strokeStyle; // 💡 추가됨

  RouteSegment({
    required this.id,
    required this.points,
    required this.color,
    this.width = 6.0,
    this.strokeStyle = StrokeStyle.solid, // 💡 기본값 실선
  });
}
