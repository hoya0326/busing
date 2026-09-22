import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';

/// 💡 [Request 9] Atcha 스타일의 단일 알람 정책 및 루틴 반복 알람 서비스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// 💡 알림 클릭 시 실행될 콜백 핸들러
  Function(String payload)? onNotificationClick;

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('🔔 [Notification Clicked] Payload: $payload');
          onNotificationClick?.call(payload);
        }
      },
    );

    // 💡 [수석 개발자] Android 13+ 알림 및 14+ 정밀 알람 권한 요청
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (e) {
      debugPrint('⚠️ [Notification] Asia/Seoul 타임존 설정 경고: $e');
    }
  }

  /// 💡 앱 완전 종료(Cold Start) 시 알림 클릭으로 앱이 시작된 경우 처리
  Future<void> checkLaunchNotification() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        final payload = details.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          debugPrint('🚀 [Notification Cold Start] Launch Payload: $payload');
          onNotificationClick?.call(payload);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Notification Launch Check Error] $e');
    }
  }

  /// 💡 루틴 탑승 안내 알림 등록 (해당 요일/시간 매주 반복 예약)
  Future<void> scheduleRoutineAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await _plugin.cancel(id);

      tz.Location location;
      try {
        location = tz.getLocation('Asia/Seoul');
      } catch (_) {
        location = tz.local;
      }

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, location);

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_bus_channel',
          '루틴 탑승 안내 알림',
          channelDescription: '설정한 루틴 시간에 맞춰 탑승 안내 알림을 전달합니다.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          notificationDetails,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // 💡 매주 지정 요일/시간 반복
        );
      } catch (e) {
        if (e.toString().contains('exact_alarms_not_permitted')) {
          debugPrint('⚠️ [Notification] Exact alarm 권한 없음. Inexact 모드로 전환합니다.');
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            tzScheduledDate,
            notificationDetails,
            payload: payload,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        } else {
          rethrow;
        }
      }
      
      debugPrint('⏰ [Notification] 루틴 반복 알람 등록 완료: id=$id, $scheduledDate ($tzScheduledDate)');
    } catch (e) {
      debugPrint('❌ [Notification] 루틴 알람 등록 실패: $e');
    }
  }

  /// 💡 개별 루틴 알람 취소
  Future<void> cancelRoutineAlarm(int id) async {
    try {
      await _plugin.cancel(id);
      debugPrint('🚫 [Notification] 루틴 알람 취소 완료: id=$id');
    } catch (e) {
      debugPrint('❌ [Notification] 루틴 알람 취소 실패: $e');
    }
  }

  /// 💡 Atcha 스타일: 기존 알람을 싹 비우고 새로운 알람 하나만 등록
  Future<void> replaceAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await _plugin.cancel(id);

      tz.Location location;
      try {
        location = tz.getLocation('Asia/Seoul');
      } catch (_) {
        location = tz.local;
      }

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, location);

      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'routine_bus_channel',
              '승하차 알림',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        if (e.toString().contains('exact_alarms_not_permitted')) {
          debugPrint('⚠️ [Notification] Exact alarm 권한 없음. Inexact 모드로 전환합니다.');
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            tzScheduledDate,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'routine_bus_channel',
                '승하차 알림',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: payload,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        } else {
          rethrow;
        }
      }
      
      debugPrint('⏰ [Notification] 새 알람 등록 완료: $scheduledDate ($tzScheduledDate)');
    } catch (e) {
      debugPrint('❌ [Notification] 알람 교체 실패: $e');
    }
  }

  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'last_bus_channel',
            '막차 알림',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ [Notification] 즉시 알림 실패: $e');
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('🚫 [Notification] 모든 알람이 취소되었습니다.');
  }
}
