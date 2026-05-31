import 'package:flutter/material.dart';

/// 사용자가 직접 만드는 스케줄 카테고리 (근무/개인일정/기타 등 자유롭게)
class ScheduleCategory {
  final int? id;
  final String name;       // 카테고리 이름 (예: 주간, 야간, 병원, 운동 등)
  final String emoji;      // 아이콘 이모지
  final Color color;       // 표시 색상
  final TimeOfDay alarmTime; // 기본 알람 시간

  ScheduleCategory({
    this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.alarmTime = const TimeOfDay(hour: 8, minute: 0),
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'emoji': emoji,
      'color': color.value,
      'alarm_hour': alarmTime.hour,
      'alarm_minute': alarmTime.minute,
    };
  }

  factory ScheduleCategory.fromMap(Map<String, dynamic> map) {
    return ScheduleCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      emoji: map['emoji'] as String,
      color: Color(map['color'] as int),
      alarmTime: TimeOfDay(
        hour: map['alarm_hour'] as int,
        minute: map['alarm_minute'] as int,
      ),
    );
  }

  ScheduleCategory copyWith({
    int? id,
    String? name,
    String? emoji,
    Color? color,
    TimeOfDay? alarmTime,
  }) {
    return ScheduleCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      alarmTime: alarmTime ?? this.alarmTime,
    );
  }

  /// 기본 제공 카테고리
  static List<ScheduleCategory> get defaults => [
        ScheduleCategory(
          name: '주간',
          emoji: '☀️',
          color: const Color(0xFF4A90D9),
          alarmTime: const TimeOfDay(hour: 7, minute: 0),
        ),
        ScheduleCategory(
          name: '야간',
          emoji: '🌙',
          color: const Color(0xFF7B68EE),
          alarmTime: const TimeOfDay(hour: 22, minute: 30),
        ),
        ScheduleCategory(
          name: '비번',
          emoji: '😴',
          color: const Color(0xFF4CAF50),
          alarmTime: const TimeOfDay(hour: 8, minute: 0),
        ),
        ScheduleCategory(
          name: '휴무',
          emoji: '🏖️',
          color: const Color(0xFFFF7043),
          alarmTime: const TimeOfDay(hour: 9, minute: 0),
        ),
      ];
}
