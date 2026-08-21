import 'package:flutter/material.dart';

// 지도핀의 유형을 구분하기 위한 값들입니다.
enum PinType { depart, arrive }

// 지도상의 위치 정보와 핀의 종류를 담는 객체 정의입니다.
class MapPin {
  final double x;
  final double y;
  final PinType type;

  MapPin({required this.x, required this.y, required this.type});

  // 데이터를 저장 가능한 형식으로 변환합니다.
  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'type': type.name};
  
  // 저장된 데이터에서 객체를 생성합니다.
  factory MapPin.fromJson(Map<String, dynamic> json) => MapPin(
    x: json['x'],
    y: json['y'],
    type: PinType.values.firstWhere((e) => e.name == json['type']),
  );
}

// 사용자가 설정한 반복 이동 일정을 나타냅/니다.
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

// 자주 가는 장소의 정보를 보관하는 구조입니다.
class SavedPlace {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  SavedPlace({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });
}

// 실시간 버스 도착 및 경로 분석 결과를 담는 구조입니다.
class BusRouteInfo {
  final String busName;
  final String status;
  final int minutesRemaining;
  final String walkInfo;
  final int totalTravelTime;
  final Color color;
  final String? suggestion;

  BusRouteInfo({
    required this.busName,
    required this.status,
    required this.minutesRemaining,
    required this.walkInfo,
    required this.totalTravelTime,
    required this.color,
    this.suggestion,
  });
}
