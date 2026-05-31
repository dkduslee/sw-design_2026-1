import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../models/shift_type.dart';

class SettingsService extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final leadMin = prefs.getInt('alarm_lead_minutes') ?? 60;
    final sound = prefs.getBool('alarm_sound') ?? true;
    final vibrate = prefs.getBool('alarm_vibrate') ?? true;
    final calSync = prefs.getBool('calendar_sync') ?? true;

    final customTimes = <ShiftType, TimeOfDay>{};
    for (final type in ShiftType.values) {
      final key = 'alarm_time_${type.dbValue}';
      final stored = prefs.getString(key);
      if (stored != null) {
        final parts = stored.split(':');
        customTimes[type] =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } else {
        customTimes[type] = type.defaultAlarmTime;
      }
    }

    _settings = AppSettings(
      alarmLeadMinutes: leadMin,
      alarmSound: sound,
      alarmVibrate: vibrate,
      calendarSyncEnabled: calSync,
      customAlarmTimes: customTimes,
    );
    notifyListeners();
  }

  Future<void> save(AppSettings updated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alarm_lead_minutes', updated.alarmLeadMinutes);
    await prefs.setBool('alarm_sound', updated.alarmSound);
    await prefs.setBool('alarm_vibrate', updated.alarmVibrate);
    await prefs.setBool('calendar_sync', updated.calendarSyncEnabled);

    for (final entry in updated.customAlarmTimes.entries) {
      final key = 'alarm_time_${entry.key.dbValue}';
      await prefs.setString(
          key, '${entry.value.hour}:${entry.value.minute.toString().padLeft(2, '0')}');
    }

    _settings = updated;
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    await save(AppSettings());
  }
}
