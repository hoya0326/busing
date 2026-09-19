import '../models.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';

/// 💡 Atcha의 DefaultRegisterAlarmUseCase.swift 포팅
/// 단일 알람 정책을 강제하며 승차 알림을 등록하는 비즈니스 로직입니다.
class RegisterAlarmUseCase {
  final NotificationService _notificationService = NotificationService();

  Future<void> execute(BusRouteInfo route) async {
    try {
      debugPrint('⏰ [UseCase] 알람 등록 시퀀스 가동: ${route.busName}');

      // 1. 실시간 정보 유무 확인
      if (route.busArrivalRemaining == -1) {
        throw '실시간 정보가 없어 정확한 알람을 설정할 수 없습니다.';
      }

      if (route.busArrivalRemaining == -2) {
        throw '해당 노선은 운행이 종료되었습니다.';
      }

      // 2. 현재 버스 승차 가능 여부 판단
      // (버스 도착 시간) - (도보 시간) = 여유 시간
      int margin = route.busArrivalRemaining - route.walkTimeRemaining;
      
      int targetArrivalMin = route.busArrivalRemaining;
      bool isNextBus = false;

      if (margin < 0) {
        debugPrint('⚠️ [UseCase] 현재 버스 탑승 불가. 다음 버스 탐색...');
        if (route.nextBusArrivalRemaining == null || route.nextBusArrivalRemaining! <= 0) {
          throw '지금 출발해도 버스를 놓칠 확률이 높으며, 다음 버스 정보가 없습니다.';
        }
        targetArrivalMin = route.nextBusArrivalRemaining!;
        margin = targetArrivalMin - route.walkTimeRemaining;
        isNextBus = true;
      }

      // 3. 알람 시점 계산 (여유 시간에서 5분을 더 뺀 시점, 즉 출발 5분 전 알림)
      // Atcha 로직: (도착예정 - 도보시간 - 5분)
      final alarmLeadTime = 5; 
      final minutesUntilAlarm = targetArrivalMin - route.walkTimeRemaining - alarmLeadTime;

      if (minutesUntilAlarm < 0) {
        if (isNextBus) {
           throw '다음 버스도 곧 도착 예정입니다. 지금 바로 출발하세요!';
        } else {
           throw '버스가 곧 도착합니다. 지금 바로 출발하세요!';
        }
      }

      // 4. 기존 알람 초기화 및 새 알람 등록
      await _notificationService.cancelAll();

      final scheduledDate = DateTime.now().add(Duration(minutes: minutesUntilAlarm));

      await _notificationService.replaceAlarm(
        id: route.hashCode,
        title: isNextBus ? '다음 버스 출발 5분 전!' : '버스 출발 5분 전!',
        body: '${route.busName}번 버스가 ${targetArrivalMin}분 뒤 도착합니다. 지금 준비하세요.',
        scheduledDate: scheduledDate,
      );

      debugPrint('✅ [UseCase] 알람 등록 성공: ${scheduledDate.toLocal()} (Target: ${targetArrivalMin}min)');
    } catch (e) {
      debugPrint('❌ [UseCase] 알람 등록 실패: $e');
      rethrow;
    }
  }
}
