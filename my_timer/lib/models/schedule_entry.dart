/// ShiftSchedule 대체 - 카테고리 기반의 범용 스케줄 항목
class ScheduleEntry {
  final int? id;
  final DateTime date;
  final int categoryId;       // ScheduleCategory.id 참조
  final String categoryName;  // 조회 편의를 위해 함께 저장
  final String? memo;
  final String? calendarEventId;

  ScheduleEntry({
    this.id,
    required this.date,
    required this.categoryId,
    required this.categoryName,
    this.memo,
    this.calendarEventId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String().substring(0, 10),
      'category_id': categoryId,
      'category_name': categoryName,
      'memo': memo,
      'calendar_event_id': calendarEventId,
    };
  }

  factory ScheduleEntry.fromMap(Map<String, dynamic> map) {
    return ScheduleEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String,
      memo: map['memo'] as String?,
      calendarEventId: map['calendar_event_id'] as String?,
    );
  }

  ScheduleEntry copyWith({
    int? id,
    DateTime? date,
    int? categoryId,
    String? categoryName,
    String? memo,
    String? calendarEventId,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      memo: memo ?? this.memo,
      calendarEventId: calendarEventId ?? this.calendarEventId,
    );
  }
}
