class AlarmSetting {
  final int? alarmId;
  final int scheduleId;
  final DateTime alarmTime;
  final String message;
  final bool isEnabled;

  AlarmSetting({
    this.alarmId,
    required this.scheduleId,
    required this.alarmTime,
    required this.message,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (alarmId != null) 'alarm_id': alarmId,
      'schedule_id': scheduleId,
      'alarm_time': alarmTime.toIso8601String(),
      'message': message,
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory AlarmSetting.fromMap(Map<String, dynamic> map) {
    return AlarmSetting(
      alarmId: map['alarm_id'] as int?,
      scheduleId: map['schedule_id'] as int,
      alarmTime: DateTime.parse(map['alarm_time'] as String),
      message: map['message'] as String,
      isEnabled: (map['is_enabled'] as int) == 1,
    );
  }

  AlarmSetting copyWith({
    int? alarmId,
    int? scheduleId,
    DateTime? alarmTime,
    String? message,
    bool? isEnabled,
  }) {
    return AlarmSetting(
      alarmId: alarmId ?? this.alarmId,
      scheduleId: scheduleId ?? this.scheduleId,
      alarmTime: alarmTime ?? this.alarmTime,
      message: message ?? this.message,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
