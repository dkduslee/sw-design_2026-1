import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/alarm_setting.dart';

class AppAlarmManager {
  static final AppAlarmManager _instance = AppAlarmManager._internal();
  factory AppAlarmManager() => _instance;
  AppAlarmManager._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // 한국 표준시
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Android 12+ SCHEDULE_EXACT_ALARM 권한 요청
  Future<bool> requestExactAlarmPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    final result = await androidPlugin.requestExactAlarmsPermission();
    return result ?? false;
  }

  /// 알람 등록
  Future<void> scheduleAlarm(AlarmSetting alarm) async {
    if (!alarm.isEnabled) return;

    final now = DateTime.now();
    if (alarm.alarmTime.isBefore(now)) return; // 이미 지난 알람은 무시

    final int targetNotificationId = alarm.alarmId ?? alarm.scheduleId;
    final androidDetails = AndroidNotificationDetails(
      'my_timer_channel',
      'My Timer 알람',
      channelDescription: '근무 스케줄 알람 채널',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      ongoing: true,
    );
    final details = NotificationDetails(android: androidDetails);

    final scheduledDate = tz.TZDateTime.from(alarm.alarmTime, tz.local);

    try {
      await _notifications.zonedSchedule(
        targetNotificationId,
        'My Timer',
        alarm.message,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'schedule_${alarm.scheduleId}',
      );
      debugPrint('등록완료');
    } catch (e) {
      // 권한 없을 시 근사치 알람으로 재시도
      debugPrint('Exact alarm failed, trying inexact: $e');
      await _notifications.zonedSchedule(
        targetNotificationId,
        'My Timer',
        alarm.message,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'schedule_${alarm.scheduleId}',
      );
    }
  }

  /// 알람 취소
  Future<void> cancelAlarm(int alarmId) async {
    await _notifications.cancel(alarmId);
  }

  /// 즉시 알림 표시 (스케줄 변경 알림 등)
  Future<void> showImmediateNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'my_timer_notify',
      'My Timer 알림',
      channelDescription: '스케줄 변경 알림',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(0, title, body, details);
  }
}
