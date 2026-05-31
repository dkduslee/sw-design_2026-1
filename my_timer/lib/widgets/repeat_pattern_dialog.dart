import 'package:flutter/material.dart';
import '../models/schedule_category.dart';

class RepeatPatternDialog extends StatefulWidget {
  final DateTime startDate;
  final List<ScheduleCategory> categories;
  final void Function(
      DateTime start, List<ScheduleCategory> pattern, int weeks) onConfirm;

  const RepeatPatternDialog({
    super.key,
    required this.startDate,
    required this.categories,
    required this.onConfirm,
  });

  @override
  State<RepeatPatternDialog> createState() => _RepeatPatternDialogState();
}

class _RepeatPatternDialogState extends State<RepeatPatternDialog> {
  List<ScheduleCategory> _pattern = [];
  int _weeks = 4;
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    // 기본 패턴: 카테고리 앞 4개
    _pattern = widget.categories.take(4).toList();
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
            // 현재 패턴
            if (_pattern.isEmpty)
              const Text('아래에서 카테고리를 추가하세요',
                  style: TextStyle(color: Colors.grey, fontSize: 12))
            else
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
                      key: ValueKey('$i-${_pattern[i].id}'),
                      dense: true,
                      leading: Text('${_pattern[i].emoji}',
                          style: const TextStyle(fontSize: 20)),
                      title: Text(_pattern[i].name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.drag_handle, color: Colors.grey),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () =>
                                setState(() => _pattern.removeAt(i)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            // 카테고리 추가 칩
            const Text('추가할 카테고리',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.categories.map((cat) {
                return ActionChip(
                  avatar: Text(cat.emoji),
                  label: Text(cat.name,
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: cat.color.withOpacity(0.1),
                  side: BorderSide(color: cat.color.withOpacity(0.3)),
                  onPressed: () => setState(() => _pattern.add(cat)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // 주 수
            Row(
              children: [
                const Text('적용 기간: ', style: TextStyle(fontSize: 14)),
                DropdownButton<int>(
                  value: _weeks,
                  underline: const SizedBox(),
                  items: [1, 2, 4, 8, 12].map((w) {
                    return DropdownMenuItem(
                        value: w, child: Text('$w주'));
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
          onPressed: _pattern.isEmpty
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onConfirm(
                      _startDate!, List.from(_pattern), _weeks);
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
