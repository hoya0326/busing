import 'package:flutter/material.dart';

// ── 지도 관련 모델 ──

// 지도상에서 위치를 구분하는 유형입니다.
enum PinType { depart, arrive }

// 지도의 좌표와 해당 위치의 성격을 정의합니다.
class MapPin {
  final double x;
  final double y;
  final PinType type;

  MapPin({required this.x, required this.y, required this.type});

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'type': type.name};
  
  factory MapPin.fromJson(Map<String, dynamic> json) => MapPin(
    x: json['x'],
    y: json['y'],
    type: PinType.values.firstWhere((e) => e.name == json['type']),
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

// ── 알고리즘 및 결과 모델 ──

// 도보와 버스 타이밍을 분석한 결과 상태입니다.
enum RouteStatus { 
  safe,    // 🟢 안정: 여유롭게 탑승 가능
  tight,   // 🟡 촉박: 서둘러야 탑승 가능
  hard     // 🔴 어려움: 현재 버스 탑승 불가, 다음 버스 권장
}

// 버스 노선별 상세 분석 정보와 추천 순위를 결정하는 데이터 구조입니다.
class BusRouteInfo {
  final String busName;           // 버스 번호 (예: 수완03)
  final int busArrivalRemaining;  // 버스 정류장 도착까지 남은 시간 (분)
  final int walkTimeRemaining;    // 정류장까지 걷는 시간 (분)
  final int travelDuration;       // 버스 탑승 후 목적지까지 주행 시간 (분)
  final String routeDescription;  // 경로 상세 설명
  
  // ── 알고리즘 연산 결과 ──
  late final int syncMargin;      // 싱크로율 여유 수치 (도착시간 - 도보시간)
  late final RouteStatus status;  // 신호등 상태
  late final int totalETA;        // 최종 목적지 도착 예정 시간 (현재시각 기준 소요분)

  BusRouteInfo({
    required this.busName,
    required this.busArrivalRemaining,
    required this.walkTimeRemaining,
    required this.travelDuration,
    required this.routeDescription,
  }) {
    // 1. 도보-버스 싱크로율 연산: (버스 도착 시간) - (도보 소요 시간)
    syncMargin = busArrivalRemaining - walkTimeRemaining;

    // 2. 신호등 알고리즘 적용
    if (syncMargin >= 3) {
      status = RouteStatus.safe;
    } else if (syncMargin >= 0) {
      status = RouteStatus.tight;
    } else {
      status = RouteStatus.hard;
    }

    // 3. 목적지 최종 도착 시간(Total ETA) 계산
    // 만약 현재 버스를 못 탄다면(🔴), 다음 버스(보통 10분 뒤)를 탄다고 가정하여 계산
    if (status == RouteStatus.hard) {
      totalETA = busArrivalRemaining + 10 + travelDuration;
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
    }
  }

  // 상태에 따른 문구 정보를 반환합니다.
  String get statusText {
    switch (status) {
      case RouteStatus.safe: return '안정 탑승';
      case RouteStatus.tight: return '서두르세요';
      case RouteStatus.hard: return '탑승 어려움';
    }
  }
}
