import 'package:flutter/material.dart';
import '../models/shift_type.dart';

class ShiftDialog extends StatefulWidget {
  final DateTime date;
  final ShiftType? initialType;
  final String? initialMemo;
  final void Function(ShiftType type, String? memo) onConfirm;

  const ShiftDialog({
    super.key,
    required this.date,
    this.initialType,
    this.initialMemo,
    required this.onConfirm,
  });

  @override
  State<ShiftDialog> createState() => _ShiftDialogState();
}

class _ShiftDialogState extends State<ShiftDialog> {
  ShiftType? _selected;
  final _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialType;
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
      title: Text('$dateStr 근무 등록'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('근무 유형 선택',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            // 근무 유형 버튼들
            Row(
              children: ShiftType.values.map((type) {
                final isSelected = _selected == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? type.color
                              : type.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? type.color
                                : type.color.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _typeIcon(type),
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              type.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : type.color,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    '기본 알람: ${_selected!.defaultAlarmTime.format(context)}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
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

  String _typeIcon(ShiftType type) {
    switch (type) {
      case ShiftType.day:
        return '☀️';
      case ShiftType.night:
        return '🌙';
      case ShiftType.off:
        return '😴';
      case ShiftType.holiday:
        return '🏖️';
    }
  }
}
