import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import '../models/shift_schedule.dart';
import '../models/shift_type.dart';

class CalendarManager {
  static final CalendarManager _instance = CalendarManager._internal();
  factory CalendarManager() => _instance;
  CalendarManager._internal();

  final DeviceCalendarPlugin _deviceCalendar = DeviceCalendarPlugin();
  String? _calendarId;

  Future<bool> requestPermissions() async {
    var result = await _deviceCalendar.requestPermissions();
    return result.isSuccess && (result.data ?? false);
  }

  Future<bool> _ensureCalendar() async {
    if (_calendarId != null) return true;

    final hasPermission = await requestPermissions();
    if (!hasPermission) return false;

    final calendarsResult = await _deviceCalendar.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null) {
      return false;
    }

    // My Timer 전용 캘린더 찾기 (없으면 기본 캘린더 사용)
    final calendars = calendarsResult.data!;
    final myTimerCal = calendars.firstWhere(
      (c) => c.name == 'My Timer',
      orElse: () => calendars.first,
    );
    _calendarId = myTimerCal.id;
    return true;
  }

  Future<String?> createEvent(ShiftSchedule schedule) async {
    try {
      final ready = await _ensureCalendar();
      if (!ready || _calendarId == null) return null;

      final date = schedule.date;
      final startHour = schedule.shiftType.startTime.hour;
      final startMin = schedule.shiftType.startTime.minute;
      final endHour = schedule.shiftType.endTime.hour;
      final endMin = schedule.shiftType.endTime.minute;

      final startTime = TZDateTime.local(
          date.year, date.month, date.day, startHour, startMin);
      final endTime = schedule.shiftType == ShiftType.night
          ? TZDateTime.local(
              date.year, date.month, date.day + 1, endHour, endMin)
          : TZDateTime.local(
              date.year, date.month, date.day, endHour, endMin);

      final event = Event(
        _calendarId,
        title: '[${schedule.shiftType.name}] 근무',
        start: startTime,
        end: endTime,
        description: schedule.memo,
      );

      final result =
          await _deviceCalendar.createOrUpdateEvent(event);
      if (result?.isSuccess == true) {
        return result!.data;
      }
    } catch (e) {
      debugPrint('CalendarManager.createEvent error: $e');
    }
    return null;
  }

  Future<void> updateEvent(ShiftSchedule schedule) async {
    if (schedule.calendarEventId == null) {
      await createEvent(schedule);
      return;
    }
    try {
      final ready = await _ensureCalendar();
      if (!ready || _calendarId == null) return;

      final date = schedule.date;
      final startHour = schedule.shiftType.startTime.hour;
      final startMin = schedule.shiftType.startTime.minute;
      final endHour = schedule.shiftType.endTime.hour;
      final endMin = schedule.shiftType.endTime.minute;

      final startTime = TZDateTime.local(
          date.year, date.month, date.day, startHour, startMin);
      final endTime = TZDateTime.local(
          date.year, date.month, date.day, endHour, endMin);

      final event = Event(
        _calendarId,
        eventId: schedule.calendarEventId,
        title: '[${schedule.shiftType.name}] 근무',
        start: startTime,
        end: endTime,
        description: schedule.memo,
      );
      await _deviceCalendar.createOrUpdateEvent(event);
    } catch (e) {
      debugPrint('CalendarManager.updateEvent error: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final ready = await _ensureCalendar();
      if (!ready || _calendarId == null) return;
      await _deviceCalendar.deleteEvent(_calendarId!, eventId);
    } catch (e) {
      debugPrint('CalendarManager.deleteEvent error: $e');
    }
  }
}
