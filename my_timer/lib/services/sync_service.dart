import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift_schedule.dart';
import '../models/alarm_setting.dart';
import '../models/shift_type.dart';
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

  Future<TimeOfDay> _getAlarmTime(ShiftType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'alarm_time_${type.dbValue}';
    final stored = prefs.getString(key);
    if (stored != null) {
      final parts = stored.split(':');
      return TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return type.defaultAlarmTime;
  }

  String _buildMessage(ShiftType type, int leadMinutes) {
    final typeName = type.name;
    if (leadMinutes == 0) {
      return '$typeName 근무 시작입니다.';
    }
    return '$typeName 근무 시작 $leadMinutes분 전입니다.';
  }

  Future<DateTime> _computeAlarmDateTime(
      ShiftSchedule schedule, int leadMinutes) async {
    final alarmTod = await _getAlarmTime(schedule.shiftType);
    final date = schedule.date;
    final alarmBase = DateTime(
        date.year, date.month, date.day, alarmTod.hour, alarmTod.minute);
    return alarmBase.subtract(Duration(minutes: leadMinutes));
  }

  // ── 생성 시 동기화 ──────────────────────────────────────────────────

  Future<void> syncOnCreate(ShiftSchedule schedule) async {
    if (schedule.id == null) return;

    try {
      final leadMin = await _getLeadMinutes();
      final alarmTime = await _computeAlarmDateTime(schedule, leadMin);
      final message = _buildMessage(schedule.shiftType, leadMin);

      // 1) 알람 저장 및 OS 등록
      final alarmSetting = AlarmSetting(
        scheduleId: schedule.id!,
        alarmTime: alarmTime,
        message: message,
      );
      final alarmId = await _scheduleManager.insertAlarmSetting(alarmSetting);
      final savedAlarm = alarmSetting.copyWith(alarmId: alarmId);
      await _alarmManager.scheduleAlarm(savedAlarm);

      // 2) 기기 캘린더 동기화
      final calSettings = await SharedPreferences.getInstance();
      final syncEnabled = calSettings.getBool('calendar_sync') ?? true;
      if (syncEnabled) {
        final eventId = await _calendarManager.createEvent(schedule);
        if (eventId != null) {
          await _scheduleManager.updateCalendarEventId(schedule.id!, eventId);
        }
      }
    } catch (e) {
      debugPrint('SyncService.syncOnCreate error: $e');
      await _rollback(schedule.id!);
    }
  }

  // ── 수정 시 동기화 ──────────────────────────────────────────────────

  Future<void> syncOnUpdate(ShiftSchedule schedule) async {
    if (schedule.id == null) return;

    try {
      final leadMin = await _getLeadMinutes();
      final alarmTime = await _computeAlarmDateTime(schedule, leadMin);
      final message = _buildMessage(schedule.shiftType, leadMin);

      // 1) 기존 알람 취소
      final oldAlarm =
          await _scheduleManager.getAlarmByScheduleId(schedule.id!);
      if (oldAlarm?.alarmId != null) {
        await _alarmManager.cancelAlarm(oldAlarm!.alarmId!);
        await _scheduleManager.deleteAlarmByScheduleId(schedule.id!);
      }

      // 2) 새 알람 등록
      final alarmSetting = AlarmSetting(
        scheduleId: schedule.id!,
        alarmTime: alarmTime,
        message: message,
      );
      final alarmId = await _scheduleManager.insertAlarmSetting(alarmSetting);
      await _alarmManager.scheduleAlarm(alarmSetting.copyWith(alarmId: alarmId));

      // 3) 캘린더 이벤트 갱신
      final prefs = await SharedPreferences.getInstance();
      final syncEnabled = prefs.getBool('calendar_sync') ?? true;
      if (syncEnabled) {
        await _calendarManager.updateEvent(schedule);
      }
    } catch (e) {
      debugPrint('SyncService.syncOnUpdate error: $e');
    }
  }

  // ── 삭제 시 동기화 ──────────────────────────────────────────────────

  Future<void> syncOnDelete(ShiftSchedule schedule) async {
    if (schedule.id == null) return;

    try {
      // 1) 알람 취소
      final alarm =
          await _scheduleManager.getAlarmByScheduleId(schedule.id!);
      if (alarm?.alarmId != null) {
        await _alarmManager.cancelAlarm(alarm!.alarmId!);
      }

      // 2) 캘린더 이벤트 삭제
      if (schedule.calendarEventId != null) {
        await _calendarManager.deleteEvent(schedule.calendarEventId!);
      }
    } catch (e) {
      debugPrint('SyncService.syncOnDelete error: $e');
    }
  }

  Future<void> _rollback(int scheduleId) async {
    try {
      await _scheduleManager.deleteAlarmByScheduleId(scheduleId);
    } catch (e) {
      debugPrint('SyncService._rollback error: $e');
    }
  }
}
