import 'package:flutter/material.dart';
import '../models/shift_schedule.dart';
import '../models/shift_type.dart';
import '../services/schedule_manager.dart';
import '../services/sync_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleManager _manager = ScheduleManager();
  final SyncService _sync = SyncService();

  Map<DateTime, ShiftSchedule> scheduleMap = {};
  List<ShiftSchedule> _monthSchedules = [];

  DateTime _focusedMonth = DateTime.now();
  DateTime get focusedMonth => _focusedMonth;

  void setFocusedMonth(DateTime month) {
    _focusedMonth = month;
    loadMonth(month.year, month.month);
  }

  Future<void> loadMonth(int year, int month) async {
    _monthSchedules = await _manager.getSchedulesByMonth(year, month);
    scheduleMap = {
      for (final s in _monthSchedules)
        DateTime(s.date.year, s.date.month, s.date.day): s
    };
    notifyListeners();
  }

  ShiftSchedule? getSchedule(DateTime day) {
    return scheduleMap[DateTime(day.year, day.month, day.day)];
  }

  Future<void> addSchedule(DateTime date, ShiftType type, {String? memo}) async {
    final schedule = ShiftSchedule(date: date, shiftType: type, memo: memo);
    final id = await _manager.insertSchedule(schedule);
    final saved = schedule.copyWith(id: id);
    await _sync.syncOnCreate(saved);
    await loadMonth(date.year, date.month);
  }

  Future<void> editSchedule(ShiftSchedule old, ShiftType newType,
      {String? memo}) async {
    final updated = old.copyWith(shiftType: newType, memo: memo);
    await _manager.updateSchedule(updated);
    await _sync.syncOnUpdate(updated);
    await loadMonth(old.date.year, old.date.month);
  }

  Future<void> removeSchedule(ShiftSchedule schedule) async {
    await _sync.syncOnDelete(schedule);
    if (schedule.id != null) await _manager.deleteSchedule(schedule.id!);
    await loadMonth(schedule.date.year, schedule.date.month);
  }

  /// 반복 패턴 적용
  Future<void> applyRepeatPattern(
      DateTime startDate, List<ShiftType> pattern, int weeks) async {
    await _manager.applyRepeatPattern(startDate, pattern, weeks);
    // 생성된 각 스케줄에 대해 sync (간단히 month reload 후 일괄 sync)
    final schedules = await _manager.getSchedulesByMonth(
        startDate.year, startDate.month);
    for (final s in schedules) {
      if (s.id != null) await _sync.syncOnCreate(s);
    }
    await loadMonth(startDate.year, startDate.month);
  }
}
