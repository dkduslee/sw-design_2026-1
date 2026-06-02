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

      debugPrint('[등록시도]: 날짜');
      if (alarmTime.isBefore(DateTime.now())) {
        debugPrint('무시');
      }
      final alarmSetting = AlarmSetting(
        scheduleId: entry.id!,
        alarmTime: alarmTime,
        message: message,
      );

      final alarmId = await _scheduleManager.insertAlarmSetting(alarmSetting);
      await _alarmManager.scheduleAlarm(alarmSetting.copyWith(alarmId: alarmId));

      debugPrint('알람요청 전송');
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

      // 🌟 [수정 핵심]: 수정된 카테고리와 시간 규칙에 맞춰 새 알람 시간과 메시지를 완전히 새로 계산합니다.
      final alarmTime = await _computeAlarmDateTime(entry, category, leadMin);
      final message = _buildMessage(category.name, leadMin);

      // 과거 시간이면 안드로이드 알람 등록 로직 내부나 시스템에서 무시될 수 있으므로 로그 추적
      if (alarmTime.isBefore(DateTime.now())) {
        debugPrint('⚠️ [경고] 리뉴얼된 알람 시간이 이미 지난 시간입니다: $alarmTime');
      }

      // 기존에 이 스케줄ID로 등록된 알람 데이터를 가져옴
      final oldAlarm = await _scheduleManager.getAlarmByScheduleId(entry.id!);

      if (oldAlarm != null) {
        // 🌟 안드로이드 알림 매니저에서 기존 알람 ID를 확실히 취소하여 리뉴얼 준비
        if (oldAlarm.alarmId != null) {
          await _alarmManager.cancelAlarm(oldAlarm.alarmId!);
        }

        // 새롭게 계산된 시간과 메시지로 객체 업데이트
        final updatedAlarm = oldAlarm.copyWith(
          alarmTime: alarmTime,
          message: message,
        );

        // 데이터베이스(SQLite)와 안드로이드 시스템에 각각 업데이트 및 재등록
        await _scheduleManager.updateAlarmSetting(updatedAlarm);
        await _alarmManager.scheduleAlarm(updatedAlarm);

        debugPrint('⏰ [리뉴얼 완료] 기존 알람(ID: ${oldAlarm.alarmId})이 새로운 시간($alarmTime)으로 변경되었습니다.');
      }
      else {
        // 기존에 이 스케줄에 묶인 알람 데이터가 아예 없었다면 새로 생성 (기존 예외처리 유지)
        final alarmSetting = AlarmSetting(
          scheduleId: entry.id!,
          alarmTime: alarmTime,
          message: message,
        );
        final alarmId = await _scheduleManager.insertAlarmSetting(alarmSetting);
        await _alarmManager.scheduleAlarm(alarmSetting.copyWith(alarmId: alarmId));

        debugPrint('⏰ [신규 생성] 기존 알람이 없어 리뉴얼 스케줄에 맞춰 새로 등록했습니다.');
      }

      // 기기 기본 캘린더 동기화
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('calendar_sync') ?? true) {
        await _calendarManager.updateEntryEvent(entry, category);
      }
    } catch (e) {
      debugPrint('❌ SyncService.syncOnUpdate error: $e');
    }
  }

  Future<void> syncOnDelete(ScheduleEntry entry) async {
    if (entry.id == null) return;
    try {
      final alarm =
          await _scheduleManager.getAlarmByScheduleId(entry.id!);
      if (alarm?.alarmId != null) {
        await _alarmManager.cancelAlarm(alarm!.alarmId!);
        await _scheduleManager.deleteAlarmByScheduleId(entry.id!);
      }
      if (entry.calendarEventId != null) {
        await _calendarManager.deleteEvent(entry.calendarEventId!);
      }
    } catch (e) {
      debugPrint('SyncService.syncOnDelete error: $e');
    }
  }
}
