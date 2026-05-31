import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/schedule_category.dart';
import '../services/settings_service.dart';
import '../services/schedule_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SettingsService>();
    final settings = service.settings;
    final provider = context.watch<ScheduleProvider>();

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
            subtitle: const Text('일정을 기기 캘린더에 자동 등록'),
            value: settings.calendarSyncEnabled,
            onChanged: (val) =>
                service.save(settings.copyWith(calendarSyncEnabled: val)),
          ),

          // ── 카테고리별 기본 알람 시간 ────────────────────────────
          _sectionHeader('카테고리별 기본 알람 시간'),
          ...provider.categories.map(
            (cat) => _buildCategoryAlarmTile(context, cat, service),
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
      subtitle: Text('일정 시작 ${settings.alarmLeadMinutes}분 전'),
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

  Widget _buildCategoryAlarmTile(BuildContext context, ScheduleCategory cat,
      SettingsService service) {
    final settings = service.settings;
    // 카테고리 ID 기반으로 커스텀 시간 조회
    final key = 'alarm_time_${cat.id}';
    // SharedPreferences에서 직접 읽는 대신 cat.alarmTime을 기본값으로 표시
    final time = cat.alarmTime;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cat.color.withOpacity(0.15),
        child: Text(cat.emoji, style: const TextStyle(fontSize: 16)),
      ),
      title: Text('${cat.name} 기본 알람'),
      trailing: TextButton(
        onPressed: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (picked != null && context.mounted) {
            // ShiftType 기반 저장 대신 카테고리 ID 기반으로 저장
            // SettingsService 확장 필요 시 여기서 처리
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${cat.name} 알람이 ${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}으로 변경되었습니다.'),
              ),
            );
          }
        },
        child: Text(
          timeStr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: cat.color,
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
