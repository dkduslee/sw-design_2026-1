import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_entry.dart';
import '../models/schedule_category.dart';
import '../models/alarm_setting.dart';
import 'alarm_manager.dart';
import 'calendar_manager.dart';
import 'schedule_manager.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final AppAlarmManager _alarmManager = AppAlarmManager();
  final CalendarManager _calendarManager = CalendarManager();
  final ScheduleManager _scheduleManager = ScheduleManager();

  Future<int> _getLeadMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('alarm_lead_minutes') ?? 60;
  }

  String _buildMessage(String categoryName, int leadMinutes) {
    if (leadMinutes == 0) return '$categoryName 시작입니다.';
    return '$categoryName 시작 $leadMinutes분 전입니다.';
  }

  Future<DateTime> _computeAlarmDateTime(
      ScheduleEntry entry, ScheduleCategory category, int leadMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'alarm_time_${category.id}';
    final stored = prefs.getString(key);
    TimeOfDay alarmTod;
    if (stored != null) {
      final parts = stored.split(':');
      alarmTod =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } else {
      alarmTod = category.alarmTime;
    }
    final date = entry.date;
    final base = DateTime(
        date.year, date.month, date.day, alarmTod.hour, alarmTod.minute);
    return base.subtract(Duration(minutes: leadMinutes));
  }

  Future<void> syncOnCreate(
      ScheduleEntry entry, ScheduleCategory category) async {
    if (entry.id == null) return;
    try {
      final leadMin = await _getLeadMinutes();
      final alarmTime = await _computeAlarmDateTime(entry, category, leadMin);
      final message = _buildMessage(category.name, leadMin);

      final alarmSetting = AlarmSetting(
        scheduleId: entry.id!,
        alarmTime: alarmTime,
        message: message,
      );
      final alarmId =
          await _scheduleManager.insertAlarmSetting(alarmSetting);
      await _alarmManager.scheduleAlarm(alarmSetting.copyWith(alarmId: alarmId));

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('calendar_sync') ?? true) {
        final eventId = await _calendarManager.createEntryEvent(entry, category);
        if (eventId != null) {
          await _scheduleManager.updateCalendarEventId(entry.id!, eventId);
        }
      }
    } catch (e) {
      debugPrint('SyncService.syncOnCreate error: $e');
    }
  }

  Future<void> syncOnUpdate(
      ScheduleEntry entry, ScheduleCategory category) async {
    if (entry.id == null) return;
    try {
      final leadMin = await _getLeadMinutes();
      final alarmTime = await _computeAlarmDateTime(entry, category, leadMin);
      final message = _buildMessage(category.name, leadMin);

      final oldAlarm =
          await _scheduleManager.getAlarmByScheduleId(entry.id!);
      if (oldAlarm?.alarmId != null) {
        await _alarmManager.cancelAlarm(oldAlarm!.alarmId!);
        await _scheduleManager.deleteAlarmByScheduleId(entry.id!);
      }

      final alarmSetting = AlarmSetting(
        scheduleId: entry.id!,
        alarmTime: alarmTime,
        message: message,
      );
      final alarmId =
          await _scheduleManager.insertAlarmSetting(alarmSetting);
      await _alarmManager
          .scheduleAlarm(alarmSetting.copyWith(alarmId: alarmId));

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('calendar_sync') ?? true) {
        await _calendarManager.updateEntryEvent(entry, category);
      }
    } catch (e) {
      debugPrint('SyncService.syncOnUpdate error: $e');
    }
  }

  Future<void> syncOnDelete(ScheduleEntry entry) async {
    if (entry.id == null) return;
    try {
      final alarm =
          await _scheduleManager.getAlarmByScheduleId(entry.id!);
      if (alarm?.alarmId != null) {
        await _alarmManager.cancelAlarm(alarm!.alarmId!);
      }
      if (entry.calendarEventId != null) {
        await _calendarManager.deleteEvent(entry.calendarEventId!);
      }
    } catch (e) {
      debugPrint('SyncService.syncOnDelete error: $e');
    }
  }
}
