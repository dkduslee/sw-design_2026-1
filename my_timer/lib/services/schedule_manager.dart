import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shift_schedule.dart';
import '../models/alarm_setting.dart';
import '../models/shift_type.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shift_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        shift_type TEXT NOT NULL,
        memo TEXT,
        calendar_event_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE alarm_settings (
        alarm_id INTEGER PRIMARY KEY AUTOINCREMENT,
        schedule_id INTEGER NOT NULL,
        alarm_time TEXT NOT NULL,
        message TEXT NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (schedule_id) REFERENCES shift_schedules(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── ShiftSchedule CRUD ──────────────────────────────────────────────

  Future<int> insertSchedule(ShiftSchedule schedule) async {
    final db = await database;
    return await db.insert(
      'shift_schedules',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSchedule(ShiftSchedule schedule) async {
    final db = await database;
    await db.update(
      'shift_schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<void> deleteSchedule(int id) async {
    final db = await database;
    await db.delete(
      'shift_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ShiftSchedule?> getScheduleByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final maps = await db.query(
      'shift_schedules',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (maps.isEmpty) return null;
    return ShiftSchedule.fromMap(maps.first);
  }

  Future<List<ShiftSchedule>> getSchedulesByMonth(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = month < 12
        ? '$year-${(month + 1).toString().padLeft(2, '0')}-01'
        : '${year + 1}-01-01';

    final maps = await db.query(
      'shift_schedules',
      where: 'date >= ? AND date < ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return maps.map((m) => ShiftSchedule.fromMap(m)).toList();
  }

  /// 반복 패턴 자동 적용 (예: 주야비휴 4일 순환)
  Future<void> applyRepeatPattern(
      DateTime startDate, List<ShiftType> pattern, int weeks) async {
    final db = await database;
    final batch = db.batch();
    DateTime current = startDate;
    int idx = 0;

    for (int day = 0; day < weeks * 7; day++) {
      final shiftType = pattern[idx % pattern.length];
      final schedule = ShiftSchedule(
        date: current,
        shiftType: shiftType,
      );
      batch.insert(
        'shift_schedules',
        schedule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      current = current.add(const Duration(days: 1));
      idx++;
    }
    await batch.commit(noResult: true);
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

  Future<void> updateCalendarEventId(int scheduleId, String eventId) async {
    final db = await database;
    await db.update(
      'shift_schedules',
      {'calendar_event_id': eventId},
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }
}
