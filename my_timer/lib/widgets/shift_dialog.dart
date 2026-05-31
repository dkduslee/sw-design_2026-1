import 'package:flutter/material.dart';
import '../models/schedule_category.dart';

class ShiftDialog extends StatefulWidget {
  final DateTime date;
  final ScheduleCategory? initialCategory;
  final String? initialMemo;
  final List<ScheduleCategory> categories;
  final void Function(ScheduleCategory category, String? memo) onConfirm;

  const ShiftDialog({
    super.key,
    required this.date,
    required this.categories,
    this.initialCategory,
    this.initialMemo,
    required this.onConfirm,
  });

  @override
  State<ShiftDialog> createState() => _ShiftDialogState();
}

class _ShiftDialogState extends State<ShiftDialog> {
  ScheduleCategory? _selected;
  final _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCategory;
    _memoController.text = widget.initialMemo ?? '';
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${widget.date.month}월 ${widget.date.day}일';

    return AlertDialog(
      title: Text('$dateStr 일정 등록'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('카테고리 선택',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            // 카테고리 버튼들 (2줄 그리드)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.categories.map((cat) {
                final isSelected = _selected?.id == cat.id;
                return GestureDetector(
                  onTap: () => setState(() => _selected = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color
                          : cat.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? cat.color
                            : cat.color.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : cat.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 메모 입력
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 1,
            ),
            // 알람 시간 안내
            if (_selected != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.alarm, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '기본 알람: ${_selected!.alarmTime.format(context)}',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소')),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onConfirm(
                    _selected!,
                    _memoController.text.trim().isEmpty
                        ? null
                        : _memoController.text.trim(),
                  );
                },
          child: const Text('등록'),
        ),
      ],
    );
  }
}
