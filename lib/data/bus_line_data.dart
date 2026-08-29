import 'package:flutter/foundation.dart'; // 💡 debugPrint 사용을 위해 추가
import '../models.dart';
import 'bus_line_data_full.dart';
import 'bus_details_full.dart';

/// 💡 [수석 개발자] 광주 시내버스 전체 노선 데이터 통합 관리 (Full Version)
/// 사용자 제공 bus_line_data_full.dart 및 bus_details_full.dart를 기반으로 작동합니다.

final Map<String, List<BusLineStation>> hardcodedBusLines = _initializeBusLines();

final Map<String, Map<String, dynamic>> hardcodedBusDetails = _initializeBusDetails();

Map<String, Map<String, dynamic>> _initializeBusDetails() {
  final Map<String, Map<String, dynamic>> details = Map.from(allBusDetails);
  
  // 💡 [첨단30 전용 보정] 사용자 요청에 따라 기/종점 명칭 및 방향성 동기화
  if (details.containsKey('첨단30')) {
    details['첨단30'] = {
      ...details['첨단30']!,
      'DIR_UP_NAME': '운암산코오롱하늘채아파트',
      'DIR_DOWN_NAME': '국립광주과학관',
    };
  }
  
  return details;
}

Map<String, List<BusLineStation>> _initializeBusLines() {
  final Map<String, List<BusLineStation>> processed = {};
  
  allBusDetails.forEach((lineName, details) {
    final upKey = "${lineName}_UP";
    final downKey = "${lineName}_DOWN";
    
    // 💡 [수석 개발자] 가장 정확한 사용자 데이터(Full)에서 정류장 목록 확보
    List<BusLineStation>? rawStations = fullBusLines[upKey];
    
    // Fallback: 이름이 완벽히 일치하지 않는 경우 유연하게 매칭 (예: (계수초...) 등 생략된 이름)
    if (rawStations == null) {
      final baseName = lineName.replaceAll(RegExp(r'\(.*\)'), '');
      rawStations = fullBusLines["${baseName}_UP"] ?? fullBusLines[baseName];
    }

    if (rawStations == null) return; 

    String upTerminal = (details['DIR_UP_NAME'] ?? '').replaceAll(' ', '').replaceAll('아파트', '');
    String downTerminal = (details['DIR_DOWN_NAME'] ?? '').replaceAll(' ', '').replaceAll('아파트', '');
    
    int startIdx = rawStations.indexWhere((s) {
      final name = s.stationName.replaceAll(' ', '').replaceAll('아파트', '');
      return name.contains(upTerminal) || upTerminal.contains(name);
    });
    
    int endIdx = rawStations.indexWhere((s) {
      final name = s.stationName.replaceAll(' ', '').replaceAll('아파트', '');
      return name.contains(downTerminal) || downTerminal.contains(name);
    });
    
    List<BusLineStation> upSegment;
    if (startIdx != -1 && endIdx != -1) {
      if (startIdx <= endIdx) {
        upSegment = rawStations.sublist(startIdx, endIdx + 1);
      } else {
        upSegment = rawStations.sublist(endIdx, startIdx + 1).reversed.toList();
      }
    } else {
      upSegment = rawStations;
    }

    final String firstRun = details['FIRST_RUN'] ?? '05:40';
    final String lastRun = details['LAST_RUN'] ?? '22:30';
    final startParts = firstRun.split(':');
    final endParts = lastRun.split(':');
    final startBase = (int.tryParse(startParts[0]) ?? 5) * 60 + (int.tryParse(startParts[1]) ?? 40);
    final endBase = (int.tryParse(endParts[0]) ?? 22) * 60 + (int.tryParse(endParts[1]) ?? 30);

    processed[upKey] = List.generate(upSegment.length, (index) {
      final s = upSegment[index];
      return BusLineStation(
        stationName: s.stationName,
        stationId: s.stationId,
        arsId: s.arsId,
        lat: s.lat,
        lng: s.lng,
        firstBusTime: formatBusTime(startBase + (index * 2)),
        lastBusTime: formatBusTime(endBase + (index * 2)),
        isTransfer: s.isTransfer,
        hasBusNow: s.hasBusNow,
      );
    });

    final List<BusLineStation> downSegment = processed[upKey]!.reversed.toList();
    processed[downKey] = List.generate(downSegment.length, (index) {
      final s = downSegment[index];
      return BusLineStation(
        stationName: s.stationName,
        stationId: s.stationId,
        arsId: s.arsId,
        lat: s.lat,
        lng: s.lng,
        firstBusTime: formatBusTime(startBase + (index * 2)), 
        lastBusTime: formatBusTime(endBase + (index * 2)),
        isTransfer: s.isTransfer,
        hasBusNow: s.hasBusNow,
      );
    });
  });
  
  return processed;
}

// ── 공통 유틸리티 ──

String formatBusTime(int totalMin) {
  final h = (totalMin / 60).floor() % 24;
  final m = totalMin % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
