import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';

/// 💡 [Request 9] Atcha 스타일의 단일 알람 정책 (Single Alarm Policy)
/// 여러 알람이 꼬이지 않도록 '기존 알람 무조건 삭제 -> 새 알람 등록'을 강제합니다.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    tz.initializeTimeZones();
  }

  /// 💡 Atcha 스타일: 기존 알람을 싹 비우고 새로운 알람 하나만 등록
  Future<void> replaceAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      // 1. 기존에 예약된 모든 알림 취소 (단일 알람 정책)
      await _plugin.cancelAll();
      debugPrint('🧹 [Notification] 기존 알람을 모두 초기화했습니다.');

      // 2. 새로운 알람 스케줄링
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'routine_bus_channel',
            '승하차 알림',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('⏰ [Notification] 새 알람 등록 완료: $scheduledDate');
    } catch (e) {
      debugPrint('❌ [Notification] 알람 교체 실패: $e');
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('🚫 [Notification] 모든 알람이 취소되었습니다.');
  }
}
