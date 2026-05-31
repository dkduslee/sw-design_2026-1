import 'package:flutter/material.dart';

enum ShiftType {
  day,
  night,
  off,
  holiday,
}

extension ShiftTypeExtension on ShiftType {
  String get name {
    switch (this) {
      case ShiftType.day:
        return '주간';
      case ShiftType.night:
        return '야간';
      case ShiftType.off:
        return '비번';
      case ShiftType.holiday:
        return '휴무';
    }
  }

  String get label => name;

  Color get color {
    switch (this) {
      case ShiftType.day:
        return const Color(0xFF4A90D9); // 파랑
      case ShiftType.night:
        return const Color(0xFF7B68EE); // 보라
      case ShiftType.off:
        return const Color(0xFF4CAF50); // 초록
      case ShiftType.holiday:
        return const Color(0xFFFF7043); // 주황
    }
  }

  String get colorHex {
    switch (this) {
      case ShiftType.day:
        return '#4A90D9';
      case ShiftType.night:
        return '#7B68EE';
      case ShiftType.off:
        return '#4CAF50';
      case ShiftType.holiday:
        return '#FF7043';
    }
  }

  /// 기본 알람 시간 (근무 시작 기준)
  TimeOfDay get defaultAlarmTime {
    switch (this) {
      case ShiftType.day:
        return const TimeOfDay(hour: 7, minute: 0);
      case ShiftType.night:
        return const TimeOfDay(hour: 22, minute: 30);
      case ShiftType.off:
        return const TimeOfDay(hour: 8, minute: 0);
      case ShiftType.holiday:
        return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  TimeOfDay get startTime {
    switch (this) {
      case ShiftType.day:
        return const TimeOfDay(hour: 8, minute: 0);
      case ShiftType.night:
        return const TimeOfDay(hour: 23, minute: 0);
      case ShiftType.off:
        return const TimeOfDay(hour: 0, minute: 0);
      case ShiftType.holiday:
        return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  TimeOfDay get endTime {
    switch (this) {
      case ShiftType.day:
        return const TimeOfDay(hour: 20, minute: 0);
      case ShiftType.night:
        return const TimeOfDay(hour: 8, minute: 0);
      case ShiftType.off:
        return const TimeOfDay(hour: 23, minute: 59);
      case ShiftType.holiday:
        return const TimeOfDay(hour: 23, minute: 59);
    }
  }

  String get dbValue {
    switch (this) {
      case ShiftType.day:
        return 'DAY';
      case ShiftType.night:
        return 'NIGHT';
      case ShiftType.off:
        return 'OFF';
      case ShiftType.holiday:
        return 'HOLIDAY';
    }
  }

  static ShiftType fromDb(String value) {
    switch (value) {
      case 'DAY':
        return ShiftType.day;
      case 'NIGHT':
        return ShiftType.night;
      case 'OFF':
        return ShiftType.off;
      case 'HOLIDAY':
        return ShiftType.holiday;
      default:
        return ShiftType.day;
    }
  }
}
