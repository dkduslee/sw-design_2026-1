import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import '../models/schedule_entry.dart';
import '../models/schedule_category.dart';

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
    if (!calendarsResult.isSuccess || calendarsResult.data == null) return false;

    final calendars = calendarsResult.data!;
    final cal = calendars.firstWhere(
      (c) => c.name == 'My Timer',
      orElse: () => calendars.first,
    );
    _calendarId = cal.id;
    return true;
  }

  Future<String?> createEntryEvent(
      ScheduleEntry entry, ScheduleCategory category) async {
    try {
      final ready = await _ensureCalendar();
      if (!ready || _calendarId == null) return null;

      final date = entry.date;
      final alarmHour = category.alarmTime.hour;
      final alarmMin = category.alarmTime.minute;

      final startTime =
          TZDateTime.local(date.year, date.month, date.day, alarmHour, alarmMin);
      final endTime = startTime.add(const Duration(hours: 1));

      final event = Event(
        _calendarId,
        title: '[${category.emoji}] ${category.name}',
        start: startTime,
        end: endTime,
        description: entry.memo,
      );

      final result = await _deviceCalendar.createOrUpdateEvent(event);
      if (result?.isSuccess == true) return result!.data;
    } catch (e) {
      debugPrint('CalendarManager.createEntryEvent error: $e');
    }
    return null;
  }

  Future<void> updateEntryEvent(
      ScheduleEntry entry, ScheduleCategory category) async {
    if (entry.calendarEventId == null) {
      await createEntryEvent(entry, category);
      return;
    }
    try {
      final ready = await _ensureCalendar();
      if (!ready || _calendarId == null) return;

      final date = entry.date;
      final startTime = TZDateTime.local(date.year, date.month, date.day,
          category.alarmTime.hour, category.alarmTime.minute);
      final endTime = startTime.add(const Duration(hours: 1));

      final event = Event(
        _calendarId,
        eventId: entry.calendarEventId,
        title: '[${category.emoji}] ${category.name}',
        start: startTime,
        end: endTime,
        description: entry.memo,
      );
      await _deviceCalendar.createOrUpdateEvent(event);
    } catch (e) {
      debugPrint('CalendarManager.updateEntryEvent error: $e');
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
