import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_category.dart';
import '../services/schedule_provider.dart';

class CategoryManageScreen extends StatelessWidget {
  const CategoryManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('카테고리 관리'),
        centerTitle: true,
      ),
      body: provider.categories.isEmpty
          ? const Center(child: Text('카테고리가 없습니다.'))
          : ListView.builder(
              itemCount: provider.categories.length,
              itemBuilder: (context, i) {
                final cat = provider.categories[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cat.color.withOpacity(0.15),
                      child: Text(cat.emoji,
                          style: const TextStyle(fontSize: 20)),
                    ),
                    title: Text(cat.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '기본 알람: ${cat.alarmTime.hour.toString().padLeft(2, '0')}:${cat.alarmTime.minute.toString().padLeft(2, '0')}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              _showEditDialog(context, cat, provider),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Colors.red.shade300),
                          onPressed: () =>
                              _showDeleteConfirm(context, cat, provider),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, provider),
        icon: const Icon(Icons.add),
        label: const Text('카테고리 추가'),
      ),
    );
  }

  void _showAddDialog(BuildContext context, ScheduleProvider provider) {
    showDialog(
      context: context,
      builder: (_) => _CategoryEditDialog(
        onConfirm: (cat) => provider.addCategory(cat),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ScheduleCategory cat,
      ScheduleProvider provider) {
    showDialog(
      context: context,
      builder: (_) => _CategoryEditDialog(
        initial: cat,
        onConfirm: (updated) => provider.updateCategory(updated),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, ScheduleCategory cat,
      ScheduleProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text(
            '"${cat.emoji} ${cat.name}" 카테고리를 삭제하시겠습니까?\n해당 카테고리로 등록된 일정은 영향받지 않습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteCategory(cat.id!);
            },
            child: Text('삭제',
                style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}

class _CategoryEditDialog extends StatefulWidget {
  final ScheduleCategory? initial;
  final void Function(ScheduleCategory) onConfirm;

  const _CategoryEditDialog({this.initial, required this.onConfirm});

  @override
  State<_CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<_CategoryEditDialog> {
  final _nameController = TextEditingController();
  String _emoji = '📅';
  Color _color = const Color(0xFF4A90D9);
  TimeOfDay _alarmTime = const TimeOfDay(hour: 8, minute: 0);

  // 선택 가능한 색상 목록
  final List<Color> _colors = [
    const Color(0xFF4A90D9),
    const Color(0xFF7B68EE),
    const Color(0xFF4CAF50),
    const Color(0xFFFF7043),
    const Color(0xFFE91E63),
    const Color(0xFF00BCD4),
    const Color(0xFFFF9800),
    const Color(0xFF9C27B0),
    const Color(0xFF607D8B),
    const Color(0xFF795548),
  ];

  // 선택 가능한 이모지 목록
  final List<String> _emojis = [
    '☀️', '🌙', '😴', '🏖️', '🏥', '💊', '🏋️', '📚',
    '🎯', '🍽️', '✈️', '🎉', '💼', '🏠', '🚗', '📅',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameController.text = widget.initial!.name;
      _emoji = widget.initial!.emoji;
      _color = widget.initial!.color;
      _alarmTime = widget.initial!.alarmTime;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return AlertDialog(
      title: Text(isEdit ? '카테고리 수정' : '새 카테고리'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이름 입력
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '카테고리 이름',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            // 이모지 선택
            const Text('이모지',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _emojis.map((e) {
                final isSelected = _emoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _color.withOpacity(0.2)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: _color, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(e,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 색상 선택
            const Text('색상',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((c) {
                final isSelected = _color.value == c.value;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: c.withOpacity(0.5),
                                  blurRadius: 6)
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // 기본 알람 시간
            const Text('기본 알람 시간',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alarm),
              title: Text(
                '${_alarmTime.hour.toString().padLeft(2, '0')}:${_alarmTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _alarmTime,
                  );
                  if (picked != null) setState(() => _alarmTime = picked);
                },
                child: const Text('변경'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소')),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () {
                  final cat = ScheduleCategory(
                    id: widget.initial?.id,
                    name: _nameController.text.trim(),
                    emoji: _emoji,
                    color: _color,
                    alarmTime: _alarmTime,
                  );
                  Navigator.pop(context);
                  widget.onConfirm(cat);
                },
          child: Text(isEdit ? '저장' : '추가'),
        ),
      ],
    );
  }
}
