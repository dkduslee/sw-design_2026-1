import 'package:flutter/material.dart';
import '../models/schedule_entry.dart';
import '../models/schedule_category.dart';
import '../services/schedule_manager.dart';
import '../services/sync_service.dart';
import '../services/category_manager.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleManager _manager = ScheduleManager();
  final SyncService _sync = SyncService();
  final CategoryManager _catManager = CategoryManager();

  Map<DateTime, ScheduleEntry> entryMap = {};
  List<ScheduleCategory> categories = [];

  DateTime _focusedMonth = DateTime.now();
  DateTime get focusedMonth => _focusedMonth;

  void setFocusedMonth(DateTime month) {
    _focusedMonth = month;
    loadMonth(month.year, month.month);
  }

  Future<void> loadMonth(int year, int month) async {
    // DB 초기화 보장
    await _manager.database;

    final entries = await _manager.getEntriesByMonth(year, month);
    entryMap = {
      for (final e in entries)
        DateTime(e.date.year, e.date.month, e.date.day): e
    };
    categories = await _catManager.getAll();
    notifyListeners();
  }

  Future<void> loadCategories() async {
    await _manager.database;
    categories = await _catManager.getAll();
    notifyListeners();
  }

  ScheduleEntry? getEntry(DateTime day) {
    return entryMap[DateTime(day.year, day.month, day.day)];
  }

  ScheduleCategory? getCategoryById(int id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── 스케줄 등록 ─────────────────────────────────────────────────────

  Future<void> addEntry(
      DateTime date, ScheduleCategory category, {String? memo}) async {
    final entry = ScheduleEntry(
      date: date,
      categoryId: category.id!,
      categoryName: category.name,
      memo: memo,
    );
    final id = await _manager.insertEntry(entry);
    final saved = entry.copyWith(id: id);
    await _sync.syncOnCreate(saved, category);
    await loadMonth(date.year, date.month);
  }

  // ── 스케줄 수정 ─────────────────────────────────────────────────────

  Future<void> editEntry(
      ScheduleEntry old, ScheduleCategory category, {String? memo}) async {
    final updated = old.copyWith(
      categoryId: category.id!,
      categoryName: category.name,
      memo: memo,
    );
    await _manager.updateEntry(updated);
    await _sync.syncOnUpdate(updated, category);
    await loadMonth(old.date.year, old.date.month);
  }

  // ── 스케줄 삭제 ─────────────────────────────────────────────────────

  Future<void> removeEntry(ScheduleEntry entry) async {
    await _sync.syncOnDelete(entry);
    if (entry.id != null) await _manager.deleteEntry(entry.id!);
    await loadMonth(entry.date.year, entry.date.month);
  }

  // ── 반복 패턴 ───────────────────────────────────────────────────────

  Future<void> applyRepeatPattern(
      DateTime startDate, List<ScheduleCategory> pattern, int weeks) async {
    await _manager.applyRepeatPattern(startDate, pattern, weeks);
    await loadMonth(startDate.year, startDate.month);
  }

  // ── 카테고리 관리 ────────────────────────────────────────────────────

  Future<void> addCategory(ScheduleCategory category) async {
    await _catManager.insert(category);
    await loadCategories();
  }

  Future<void> updateCategory(ScheduleCategory category) async {
    await _catManager.update(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _catManager.delete(id);
    await loadCategories();
  }
}
