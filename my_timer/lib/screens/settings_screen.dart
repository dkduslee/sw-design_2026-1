import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/shift_type.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SettingsService>();
    final settings = service.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _resetConfirm(context, service),
            child: const Text('초기화'),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── 알람 선행 시간 ──────────────────────────────────────
          _sectionHeader('알람 선행 시간'),
          _buildLeadMinutesTile(context, settings, service),

          // ── 알람 소리 / 진동 ────────────────────────────────────
          _sectionHeader('알람 소리 · 진동'),
          SwitchListTile(
            title: const Text('알람 소리'),
            value: settings.alarmSound,
            onChanged: (val) =>
                service.save(settings.copyWith(alarmSound: val)),
          ),
          SwitchListTile(
            title: const Text('진동'),
            value: settings.alarmVibrate,
            onChanged: (val) =>
                service.save(settings.copyWith(alarmVibrate: val)),
          ),

          // ── 기기 캘린더 연동 ────────────────────────────────────
          _sectionHeader('캘린더 연동'),
          SwitchListTile(
            title: const Text('기기 캘린더 동기화'),
            subtitle: const Text('근무 일정을 기기 캘린더에 자동 등록'),
            value: settings.calendarSyncEnabled,
            onChanged: (val) =>
                service.save(settings.copyWith(calendarSyncEnabled: val)),
          ),

          // ── 근무 유형별 기본 알람 시간 ───────────────────────────
          _sectionHeader('근무 유형별 기본 알람 시간'),
          ...ShiftType.values.map(
            (type) => _buildAlarmTimeTile(context, type, settings, service),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLeadMinutesTile(
      BuildContext context, AppSettings settings, SettingsService service) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      title: const Text('알람 선행 시간'),
      subtitle: Text('근무 시작 ${settings.alarmLeadMinutes}분 전'),
      trailing: DropdownButton<int>(
        value: settings.alarmLeadMinutes,
        underline: const SizedBox(),
        items: [15, 30, 60].map((min) {
          return DropdownMenuItem(value: min, child: Text('$min분 전'));
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            service.save(settings.copyWith(alarmLeadMinutes: val));
          }
        },
      ),
    );
  }

  Widget _buildAlarmTimeTile(BuildContext context, ShiftType type,
      AppSettings settings, SettingsService service) {
    final time = settings.getAlarmTime(type);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: type.color.withOpacity(0.15),
        child: Text(
          type.name[0],
          style: TextStyle(color: type.color, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text('${type.name} 기본 알람'),
      trailing: TextButton(
        onPressed: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (picked != null) {
            final updated = Map<ShiftType, TimeOfDay>.from(
                settings.customAlarmTimes)..[type] = picked;
            service.save(settings.copyWith(customAlarmTimes: updated));
          }
        },
        child: Text(
          timeStr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: type.color,
          ),
        ),
      ),
    );
  }

  void _resetConfirm(BuildContext context, SettingsService service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('설정 초기화'),
        content: const Text('모든 설정을 기본값으로 되돌리시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.resetToDefaults();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('설정이 초기화되었습니다.')),
                );
              }
            },
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }
}
