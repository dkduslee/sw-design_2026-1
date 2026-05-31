import 'package:flutter/material.dart';
import '../models/shift_type.dart';

class AppSettings {
  // 근무 유형별 기본 알람 선행 시간 (분)
  final int alarmLeadMinutes; // 15, 30, 60

  // 알람 소리 / 진동
  final bool alarmSound;
  final bool alarmVibrate;

  // 기기 캘린더 연동 여부
  final bool calendarSyncEnabled;

  // 근무 유형별 커스텀 알람 시간 (HH:mm 문자열로 저장)
  final Map<ShiftType, TimeOfDay> customAlarmTimes;

  AppSettings({
    this.alarmLeadMinutes = 60,
    this.alarmSound = true,
    this.alarmVibrate = true,
    this.calendarSyncEnabled = true,
    Map<ShiftType, TimeOfDay>? customAlarmTimes,
  }) : customAlarmTimes = customAlarmTimes ??
            {
              ShiftType.day: const TimeOfDay(hour: 7, minute: 0),
              ShiftType.night: const TimeOfDay(hour: 22, minute: 30),
              ShiftType.off: const TimeOfDay(hour: 8, minute: 0),
              ShiftType.holiday: const TimeOfDay(hour: 9, minute: 0),
            };

  TimeOfDay getAlarmTime(ShiftType type) =>
      customAlarmTimes[type] ?? type.defaultAlarmTime;

  AppSettings copyWith({
    int? alarmLeadMinutes,
    bool? alarmSound,
    bool? alarmVibrate,
    bool? calendarSyncEnabled,
    Map<ShiftType, TimeOfDay>? customAlarmTimes,
  }) {
    return AppSettings(
      alarmLeadMinutes: alarmLeadMinutes ?? this.alarmLeadMinutes,
      alarmSound: alarmSound ?? this.alarmSound,
      alarmVibrate: alarmVibrate ?? this.alarmVibrate,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
      customAlarmTimes: customAlarmTimes ?? Map.from(this.customAlarmTimes),
    );
  }
}
