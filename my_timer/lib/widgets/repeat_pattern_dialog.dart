import 'package:flutter/material.dart';
import '../models/shift_type.dart';

class RepeatPatternDialog extends StatefulWidget {
  final DateTime startDate;
  final void Function(DateTime start, List<ShiftType> pattern, int weeks)
      onConfirm;

  const RepeatPatternDialog({
    super.key,
    required this.startDate,
    required this.onConfirm,
  });

  @override
  State<RepeatPatternDialog> createState() => _RepeatPatternDialogState();
}

class _RepeatPatternDialogState extends State<RepeatPatternDialog> {
  // 기본 패턴: 주야비휴
  List<ShiftType> _pattern = [
    ShiftType.day,
    ShiftType.night,
    ShiftType.off,
    ShiftType.holiday,
  ];
  int _weeks = 4;
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('반복 패턴 설정'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시작일
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, size: 18),
              title: Text(
                '시작일: ${_startDate!.month}월 ${_startDate!.day}일',
                style: const TextStyle(fontSize: 14),
              ),
              trailing: TextButton(
                onPressed: _pickStartDate,
                child: const Text('변경'),
              ),
            ),
            const Divider(),
            const Text('패턴 순서',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            // 패턴 편집 (드래그 가능)
            ReorderableListView(
              shrinkWrap: true,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx--;
                  final item = _pattern.removeAt(oldIdx);
                  _pattern.insert(newIdx, item);
                });
              },
              children: [
                for (int i = 0; i < _pattern.length; i++)
                  ListTile(
                    key: ValueKey(_pattern[i].dbValue + i.toString()),
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: _pattern[i].color.withOpacity(0.15),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                            color: _pattern[i].color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(_pattern[i].name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.drag_handle, color: Colors.grey),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: _pattern.length > 1
                              ? () => setState(() => _pattern.removeAt(i))
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // 추가 버튼
            Wrap(
              spacing: 6,
              children: ShiftType.values.map((type) {
                return ActionChip(
                  label: Text(type.name, style: const TextStyle(fontSize: 11)),
                  backgroundColor: type.color.withOpacity(0.1),
                  onPressed: () => setState(() => _pattern.add(type)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // 주 수 선택
            Row(
              children: [
                const Text('적용 기간: ', style: TextStyle(fontSize: 14)),
                DropdownButton<int>(
                  value: _weeks,
                  underline: const SizedBox(),
                  items: [1, 2, 4, 8, 12].map((w) {
                    return DropdownMenuItem(value: w, child: Text('$w주'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _weeks = val);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소')),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onConfirm(_startDate!, List.from(_pattern), _weeks);
          },
          child: const Text('적용'),
        ),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }
}
