import 'shift_type.dart';

class ShiftSchedule {
  final int? id;
  final DateTime date;
  final ShiftType shiftType;
  final String? memo;
  // 기기 캘린더 이벤트 ID (동기화 후 저장)
  final String? calendarEventId;

  ShiftSchedule({
    this.id,
    required this.date,
    required this.shiftType,
    this.memo,
    this.calendarEventId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String().substring(0, 10), // yyyy-MM-dd
      'shift_type': shiftType.dbValue,
      'memo': memo,
      'calendar_event_id': calendarEventId,
    };
  }

  factory ShiftSchedule.fromMap(Map<String, dynamic> map) {
    return ShiftSchedule(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      shiftType: ShiftTypeExtension.fromDb(map['shift_type'] as String),
      memo: map['memo'] as String?,
      calendarEventId: map['calendar_event_id'] as String?,
    );
  }

  ShiftSchedule copyWith({
    int? id,
    DateTime? date,
    ShiftType? shiftType,
    String? memo,
    String? calendarEventId,
  }) {
    return ShiftSchedule(
      id: id ?? this.id,
      date: date ?? this.date,
      shiftType: shiftType ?? this.shiftType,
      memo: memo ?? this.memo,
      calendarEventId: calendarEventId ?? this.calendarEventId,
    );
  }
}
