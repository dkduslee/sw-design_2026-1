import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/schedule_entry.dart';
import '../models/schedule_category.dart';
import '../services/schedule_provider.dart';
import '../widgets/shift_dialog.dart';
import '../widgets/repeat_pattern_dialog.dart';
import 'category_manage_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: '카테고리 관리',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CategoryManageScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.repeat),
            tooltip: '반복 패턴 설정',
            onPressed: () => _showRepeatPatternDialog(context, provider),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<ScheduleEntry>(
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
              defaultBuilder: (context, day, _) =>
                  _buildDayCell(day, provider, false),
              selectedBuilder: (context, day, _) =>
                  _buildDayCell(day, provider, true),
              todayBuilder: (context, day, _) =>
                  _buildDayCell(day, provider, false, isToday: true),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                color: Color(0xFFFF7043),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFFFF7043),
                size: 28,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFFF7043),
                size: 28,
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3EF),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Color(0xFF888888),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              weekendStyle: TextStyle(
                color: Color(0xFFFF7043),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: const Color(0xFFFF7043).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF7043),
                  width: 1.5,
                ),
              ),
              todayTextStyle: const TextStyle(
                color: Color(0xFFFF7043),
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFFF7043),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: const TextStyle(
                color: Color(0xFFFF7043),
              ),
              cellMargin: const EdgeInsets.all(4),
            ),
            locale: 'ko_KR',
          ),
          const Divider(height: 1),
          if (_selectedDay != null)
            _buildSelectedDayInfo(context, _selectedDay!, provider),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, ScheduleProvider provider, bool isSelected,
      {bool isToday = false}) {
    final entry = provider.getEntry(day);
    final category =
    entry != null ? provider.getCategoryById(entry.categoryId) : null;
    final color = category?.color;
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isSelected
            ? (color ?? const Color(0xFFFF7043))
            : color?.withOpacity(0.15),
        shape: BoxShape.circle,
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: (color ?? const Color(0xFFFF7043)).withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : color != null
                  ? color
                  : isWeekend
                  ? const Color(0xFFFF7043)
                  : const Color(0xFF444444),
            ),
          ),
          if (category != null)
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 10, height: 1.1),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayInfo(
      BuildContext context, DateTime day, ScheduleProvider provider) {
    final entry = provider.getEntry(day);
    final category =
    entry != null ? provider.getCategoryById(entry.categoryId) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context)
          .colorScheme
          .surfaceVariant
          .withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.event, size: 18),
              const SizedBox(width: 8),
              Text('${day.month}월 ${day.day}일 · '),
              if (category != null)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${category.emoji} ${category.name}',
                    style: TextStyle(
                      color: category.color,
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
          if (entry != null && entry.memo != null && entry.memo!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orangeAccent.shade200,
                  width: 0.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sticky_note_2_outlined,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(child: Text(entry.memo!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  ),
                ],
              ),
            )
          ],
        ],
      ),
    );
  }

  void _onDayTapped(
      BuildContext context, DateTime day, ScheduleProvider provider) {
    final existing = provider.getEntry(day);
    if (existing != null) {
      _showEditDeleteDialog(context, existing, provider);
    } else {
      _showAddDialog(context, day, provider);
    }
  }

  Future<T?> _showAnimatedDialog<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => child,
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedAnimation = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  void _showAddDialog(
      BuildContext context, DateTime day, ScheduleProvider provider) {
    _showAnimatedDialog(
      context: context,
      child: ShiftDialog(
        date: day,
        categories: provider.categories,
        onConfirm: (category, memo) async {
          await provider.addEntry(day, category, memo: memo);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${category.emoji} ${category.name} 일정이 등록되었습니다.'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditDeleteDialog(
      BuildContext context, ScheduleEntry entry, ScheduleProvider provider) {
    final category = provider.getCategoryById(entry.categoryId);
    _showAnimatedDialog(
      context: context,
      child: AlertDialog(
        title: Text(
            '${entry.date.month}월 ${entry.date.day}일 · ${category?.emoji ?? ''} ${entry.categoryName}'),
        content: const Text('일정을 수정하거나 삭제할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirm(context, entry, provider);
            },
            child: Text('삭제',
                style: TextStyle(color: Colors.red.shade400)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(context, entry, provider);
            },
            child: const Text('수정'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기')),
        ],
      ),
    );
  }

  // 3. 일정 수정 다이얼로그
  void _showEditDialog(
      BuildContext context, ScheduleEntry entry, ScheduleProvider provider) {
    final category = provider.getCategoryById(entry.categoryId);
    _showAnimatedDialog(
      context: context,
      child: ShiftDialog(
        date: entry.date,
        categories: provider.categories,
        initialCategory: category,
        initialMemo: entry.memo,
        onConfirm: (newCategory, memo) async {
          await provider.editEntry(entry, newCategory, memo: memo);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${newCategory.emoji} ${newCategory.name}(으)로 변경되었습니다.')),
            );
          }
        },
      ),
    );
  }

  // 4. 일정 삭제 확인 다이얼로그
  void _showDeleteConfirm(
      BuildContext context, ScheduleEntry entry, ScheduleProvider provider) {
    _showAnimatedDialog(
      context: context,
      child: AlertDialog(
        title: const Text('일정 삭제'),
        content: Text(
            '${entry.date.month}월 ${entry.date.day}일 ${entry.categoryName} 일정을 삭제하시겠습니까?\n알람과 캘린더 이벤트도 함께 삭제됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.removeEntry(entry);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('일정이 삭제되었습니다.')),
                );
              }
            },
            child: Text('삭제', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _showRepeatPatternDialog(
      BuildContext context, ScheduleProvider provider) {
    showDialog(
      context: context,
      builder: (_) => RepeatPatternDialog(
        startDate: _selectedDay ?? DateTime.now(),
        categories: provider.categories,
        onConfirm: (startDate, pattern, weeks) async {
          await provider.applyRepeatPattern(startDate, pattern, weeks);
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