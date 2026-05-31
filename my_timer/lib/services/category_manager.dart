import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/schedule_category.dart';

/// 카테고리 CRUD 담당
class CategoryManager {
  static final CategoryManager _instance = CategoryManager._internal();
  factory CategoryManager() => _instance;
  CategoryManager._internal();

  Database? _db;

  void setDatabase(Database db) => _db = db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    throw Exception('DB not initialized. Call setDatabase() first.');
  }

  Future<void> insertDefaults(Database db) async {
    final existing = await db.query('categories');
    if (existing.isNotEmpty) return;
    for (final cat in ScheduleCategory.defaults) {
      await db.insert('categories', cat.toMap());
    }
  }

  Future<List<ScheduleCategory>> getAll() async {
    final db = await _database;
    final maps = await db.query('categories', orderBy: 'id ASC');
    return maps.map((m) => ScheduleCategory.fromMap(m)).toList();
  }

  Future<ScheduleCategory?> getById(int id) async {
    final db = await _database;
    final maps =
        await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ScheduleCategory.fromMap(maps.first);
  }

  Future<int> insert(ScheduleCategory category) async {
    final db = await _database;
    return await db.insert('categories', category.toMap());
  }

  Future<void> update(ScheduleCategory category) async {
    final db = await _database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
