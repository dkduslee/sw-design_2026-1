import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/schedule_entry.dart';
import '../models/schedule_category.dart';
import '../models/alarm_setting.dart';
import 'category_manager.dart';

class ScheduleManager {
  static final ScheduleManager _instance = ScheduleManager._internal();
  factory ScheduleManager() => _instance;
  ScheduleManager._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'my_timer.db');

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // CategoryManager에 DB 전달
    CategoryManager().setDatabase(db);

    // 기본 카테고리 삽입
    await CategoryManager().insertDefaults(db);

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // 카테고리 테이블
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        color INTEGER NOT NULL,
        alarm_hour INTEGER NOT NULL DEFAULT 8,
        alarm_minute INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 스케줄 항목 테이블 (카테고리 기반)
    await db.execute('''
      CREATE TABLE schedule_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        category_id INTEGER NOT NULL,
        category_name TEXT NOT NULL,
        memo TEXT,
        calendar_event_id TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // 알람 설정 테이블
    await db.execute('''
      CREATE TABLE alarm_settings (
        alarm_id INTEGER PRIMARY KEY AUTOINCREMENT,
        schedule_id INTEGER NOT NULL,
        alarm_time TEXT NOT NULL,
        message TEXT NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (schedule_id) REFERENCES schedule_entries(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 기존 DB가 있을 경우 새 테이블 추가
    await db.execute('DROP TABLE IF EXISTS schedule_entries');
    await db.execute('DROP TABLE IF EXISTS alarm_settings');
    await db.execute('DROP TABLE IF EXISTS categories');
    await _onCreate(db, newVersion);
  }

  // ── ScheduleEntry CRUD ──────────────────────────────────────────────

  Future<int> insertEntry(ScheduleEntry entry) async {
    final db = await database;
    return await db.insert(
      'schedule_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateEntry(ScheduleEntry entry) async {
    final db = await database;
    await db.update(
      'schedule_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> deleteEntry(int id) async {
    final db = await database;
    await db.delete('schedule_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<ScheduleEntry?> getEntryByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final maps = await db.query(
      'schedule_entries',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (maps.isEmpty) return null;
    return ScheduleEntry.fromMap(maps.first);
  }

  Future<List<ScheduleEntry>> getEntriesByMonth(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = month < 12
        ? '$year-${(month + 1).toString().padLeft(2, '0')}-01'
        : '${year + 1}-01-01';

    final maps = await db.query(
      'schedule_entries',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => ScheduleEntry.fromMap(m)).toList();
  }

  /// 반복 패턴 적용
  Future<void> applyRepeatPattern(
      DateTime startDate, List<ScheduleCategory> pattern, int weeks) async {
    final db = await database;
    final batch = db.batch();
    DateTime current = startDate;
    int idx = 0;

    for (int day = 0; day < weeks * 7; day++) {
      final cat = pattern[idx % pattern.length];
      final entry = ScheduleEntry(
        date: current,
        categoryId: cat.id!,
        categoryName: cat.name,
      );
      batch.insert(
        'schedule_entries',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      current = current.add(const Duration(days: 1));
      idx++;
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateCalendarEventId(int entryId, String eventId) async {
    final db = await database;
    await db.update(
      'schedule_entries',
      {'calendar_event_id': eventId},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  // ── AlarmSetting CRUD ───────────────────────────────────────────────

  Future<int> insertAlarmSetting(AlarmSetting alarm) async {
    final db = await database;
    return await db.insert('alarm_settings', alarm.toMap());
  }

  Future<void> updateAlarmSetting(AlarmSetting alarm) async {
    final db = await database;
    await db.update(
      'alarm_settings',
      alarm.toMap(),
      where: 'alarm_id = ?',
      whereArgs: [alarm.alarmId],
    );
  }

  Future<void> deleteAlarmByScheduleId(int scheduleId) async {
    final db = await database;
    await db.delete(
      'alarm_settings',
      where: 'schedule_id = ?',
      whereArgs: [scheduleId],
    );
  }

  Future<AlarmSetting?> getAlarmByScheduleId(int scheduleId) async {
    final db = await database;
    final maps = await db.query(
      'alarm_settings',
      where: 'schedule_id = ?',
      whereArgs: [scheduleId],
    );
    if (maps.isEmpty) return null;
    return AlarmSetting.fromMap(maps.first);
  }

  Future<List<AlarmSetting>> getAllAlarms() async {
    final db = await database;
    final maps = await db.query('alarm_settings', orderBy: 'alarm_time ASC');
    return maps.map((m) => AlarmSetting.fromMap(m)).toList();
  }
}
