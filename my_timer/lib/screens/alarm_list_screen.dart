import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm_setting.dart';
import '../models/shift_type.dart';
import '../services/schedule_manager.dart';
import '../services/alarm_manager.dart';
import '../services/schedule_provider.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  final ScheduleManager _manager = ScheduleManager();
  final AppAlarmManager _alarmManager = AppAlarmManager();
  List<AlarmSetting> _alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    // ScheduleProvider 변경 시 자동 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().addListener(_loadAlarms);
    });
  }

  @override
  void dispose() {
    context.read<ScheduleProvider>().removeListener(_loadAlarms);
    super.dispose();
  }

  Future<void> _loadAlarms() async {
    final alarms = await _manager.getAllAlarms();
    if (mounted) setState(() => _alarms = alarms);
  }

  @override
  Widget build(BuildContext context) {
    // ScheduleProvider 변경을 감지해서 자동 리빌드
    context.watch<ScheduleProvider>();

    final upcoming = _alarms
        .where((a) => a.alarmTime.isAfter(DateTime.now()) && a.isEnabled)
        .toList();
    final past = _alarms
        .where((a) =>
            a.alarmTime.isBefore(DateTime.now()) || !a.isEnabled)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('알람 목록'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlarms,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _alarms.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadAlarms,
              child: ListView(
                children: [
                  if (upcoming.isNotEmpty) ...[
                    _buildSectionHeader('예정된 알람', upcoming.length),
                    ...upcoming.map((a) => _buildAlarmTile(a, true)),
                  ],
                  if (past.isNotEmpty) ...[
                    _buildSectionHeader('지난 알람', past.length),
                    ...past.map((a) => _buildAlarmTile(a, false)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '등록된 알람이 없습니다.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            '캘린더에서 근무 유형을 등록하면\n자동으로 알람이 생성됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count', style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmTile(AlarmSetting alarm, bool isUpcoming) {
    final time = alarm.alarmTime;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final dateStr = '${time.month}월 ${time.day}일';

    ShiftType? type;
    for (final t in ShiftType.values) {
      if (alarm.message.contains(t.name)) {
        type = t;
        break;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (type?.color ?? Colors.grey).withOpacity(0.15),
          child: Icon(Icons.alarm, color: type?.color ?? Colors.grey),
        ),
        title: Row(
          children: [
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isUpcoming
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            if (type != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: type.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type.name,
                  style: TextStyle(
                    color: type.color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '$dateStr · ${alarm.message}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Switch(
          value: alarm.isEnabled,
          onChanged: (val) => _toggleAlarm(alarm, val),
        ),
        onTap: () => _editAlarmTime(alarm),
      ),
    );
  }

  Future<void> _toggleAlarm(AlarmSetting alarm, bool enabled) async {
    if (!enabled) {
      await _alarmManager.cancelAlarm(alarm.alarmId!);
    } else {
      await _alarmManager.scheduleAlarm(alarm.copyWith(isEnabled: true));
    }
    await _manager.updateAlarmSetting(alarm.copyWith(isEnabled: enabled));
    await _loadAlarms();
  }

  Future<void> _editAlarmTime(AlarmSetting alarm) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(alarm.alarmTime),
      helpText: '알람 시간 변경',
    );
    if (picked == null) return;

    final old = alarm.alarmTime;
    final newTime =
        DateTime(old.year, old.month, old.day, picked.hour, picked.minute);
    final updated = alarm.copyWith(alarmTime: newTime);

    if (alarm.alarmId != null) {
      await _alarmManager.cancelAlarm(alarm.alarmId!);
    }
    await _manager.updateAlarmSetting(updated);
    await _alarmManager.scheduleAlarm(updated);
    await _loadAlarms();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '알람이 ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}으로 변경되었습니다.'),
        ),
      );
    }
  }
}
