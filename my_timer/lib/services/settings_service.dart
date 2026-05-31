import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _settings = AppSettings(
      alarmLeadMinutes: prefs.getInt('alarm_lead_minutes') ?? 60,
      alarmSound: prefs.getBool('alarm_sound') ?? true,
      alarmVibrate: prefs.getBool('alarm_vibrate') ?? true,
      calendarSyncEnabled: prefs.getBool('calendar_sync') ?? true,
    );
    notifyListeners();
  }

  Future<void> save(AppSettings updated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alarm_lead_minutes', updated.alarmLeadMinutes);
    await prefs.setBool('alarm_sound', updated.alarmSound);
    await prefs.setBool('alarm_vibrate', updated.alarmVibrate);
    await prefs.setBool('calendar_sync', updated.calendarSyncEnabled);

    _settings = updated;
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    await save(AppSettings());
  }
}
