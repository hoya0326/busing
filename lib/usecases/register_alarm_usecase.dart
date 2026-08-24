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

      // 1. 기존 알람 무조건 초기화 (Atcha의 Replace 정책)
      await _notificationService.cancelAll();

      // 2. 출발 시간 계산 (현재로부터 버스 도착 시간 전)
      // 실제 출발 시각은 버스 도착 시간에서 도보 소요 시간을 뺀 시점입니다.
      final departureDate = DateTime.now().add(
        Duration(minutes: route.busArrivalRemaining - route.walkTimeRemaining)
      );

      if (departureDate.isBefore(DateTime.now())) {
        throw '이미 출발해야 하는 시간입니다.';
      }

      // 3. 새 알람 등록
      await _notificationService.replaceAlarm(
        id: route.hashCode, // 임시 고유 ID
        title: '지금 나가세요!',
        body: '${route.busName}번 버스가 ${route.busArrivalRemaining}분 뒤 도착합니다.',
        scheduledDate: departureDate,
      );

      debugPrint('✅ [UseCase] 알람 등록 성공: ${departureDate.toLocal()}');
    } catch (e) {
      debugPrint('❌ [UseCase] 알람 등록 실패: $e');
      rethrow;
    }
  }
}
