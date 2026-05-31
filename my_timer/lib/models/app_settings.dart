import 'package:flutter/material.dart';

class AppSettings {
  final int alarmLeadMinutes; // 15, 30, 60
  final bool alarmSound;
  final bool alarmVibrate;
  final bool calendarSyncEnabled;

  AppSettings({
    this.alarmLeadMinutes = 60,
    this.alarmSound = true,
    this.alarmVibrate = true,
    this.calendarSyncEnabled = true,
  });

  AppSettings copyWith({
    int? alarmLeadMinutes,
    bool? alarmSound,
    bool? alarmVibrate,
    bool? calendarSyncEnabled,
  }) {
    return AppSettings(
      alarmLeadMinutes: alarmLeadMinutes ?? this.alarmLeadMinutes,
      alarmSound: alarmSound ?? this.alarmSound,
      alarmVibrate: alarmVibrate ?? this.alarmVibrate,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
    );
  }
}
