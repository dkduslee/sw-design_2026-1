import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/shift_schedule.dart';
import '../models/shift_type.dart';
import '../services/schedule_provider.dart';
import '../widgets/shift_dialog.dart';
import '../widgets/repeat_pattern_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat),
            tooltip: '반복 패턴 설정',
            onPressed: () => _showRepeatPatternDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<ShiftSchedule>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: '월',
            },
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _onDayTapped(context, selected, provider);
            },
            onPageChanged: (focused) {
              setState(() => _focusedDay = focused);
              provider.loadMonth(focused.year, focused.month);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, provider, false),
              selectedBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, provider, true),
              todayBuilder: (context, day, focusedDay) =>
                  _buildDayCell(day, provider, false, isToday: true),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(context).textTheme.titleMedium!,
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle:
                  TextStyle(color: colorScheme.error),
            ),
            locale: 'ko_KR',
          ),
          const Divider(height: 1),
          // 선택된 날짜 정보
          if (_selectedDay != null)
            _buildSelectedDayInfo(context, _selectedDay!, provider),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildDayCell(
      DateTime day, ScheduleProvider provider, bool isSelected,
      {bool isToday = false}) {
    final schedule = provider.getSchedule(day);
    final shiftType = schedule?.shiftType;
    final color = shiftType?.color;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.2),
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(
                color: color ?? Theme.of(context).colorScheme.primary,
                width: 2)
            : isToday
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    width: 1.5)
                : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              color: color != null
                  ? color.withOpacity(0.85)
                  : (day.weekday == DateTime.sunday ||
                          day.weekday == DateTime.saturday)
                      ? Colors.red.shade400
                      : null,
            ),
          ),
          if (shiftType != null)
            Text(
              shiftType.name,
              style: TextStyle(
                fontSize: 8,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayInfo(
      BuildContext context, DateTime day, ScheduleProvider provider) {
    final schedule = provider.getSchedule(day);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Row(
        children: [
          const Icon(Icons.event, size: 18),
          const SizedBox(width: 8),
          Text(
            '${day.month}월 ${day.day}일 · ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (schedule != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: schedule.shiftType.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                schedule.shiftType.name,
                style: TextStyle(
                  color: schedule.shiftType.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )
          else
            Text('미등록',
                style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  void _onDayTapped(
      BuildContext context, DateTime day, ScheduleProvider provider) {
    final existing = provider.getSchedule(day);
    if (existing != null) {
      _showEditDeleteDialog(context, existing, provider);
    } else {
      _showAddDialog(context, day, provider);
    }
  }

  void _showAddDialog(
      BuildContext context, DateTime day, ScheduleProvider provider) {
    showDialog(
      context: context,
      builder: (_) => ShiftDialog(
        date: day,
        onConfirm: (type, memo) async {
          await provider.addSchedule(day, type, memo: memo);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${type.name} 근무가 등록되었습니다.'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditDeleteDialog(
      BuildContext context, ShiftSchedule schedule, ScheduleProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
            '${schedule.date.month}월 ${schedule.date.day}일 · ${schedule.shiftType.name}'),
        content: const Text('근무 일정을 수정하거나 삭제할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirm(context, schedule, provider);
            },
            child:
                Text('삭제', style: TextStyle(color: Colors.red.shade400)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(context, schedule, provider);
            },
            child: const Text('수정'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, ShiftSchedule schedule, ScheduleProvider provider) {
    showDialog(
      context: context,
      builder: (_) => ShiftDialog(
        date: schedule.date,
        initialType: schedule.shiftType,
        initialMemo: schedule.memo,
        onConfirm: (type, memo) async {
          await provider.editSchedule(schedule, type, memo: memo);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${type.name}(으)로 변경되었습니다.')),
            );
          }
        },
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, ShiftSchedule schedule, ScheduleProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('근무 일정 삭제'),
        content: Text(
            '${schedule.date.month}월 ${schedule.date.day}일 ${schedule.shiftType.name} 근무를 삭제하시겠습니까?\n알람과 캘린더 이벤트도 함께 삭제됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.removeSchedule(schedule);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('근무 일정이 삭제되었습니다.')),
                );
              }
            },
            child: Text('삭제', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _showRepeatPatternDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => RepeatPatternDialog(
        startDate: _selectedDay ?? DateTime.now(),
        onConfirm: (startDate, pattern, weeks) async {
          await context
              .read<ScheduleProvider>()
              .applyRepeatPattern(startDate, pattern, weeks);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$weeks주 패턴이 적용되었습니다.')),
            );
          }
        },
      ),
    );
  }
}
