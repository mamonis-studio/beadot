import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pattern_data.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'beadot.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE patterns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL,
            settings_json TEXT NOT NULL,
            grid_json TEXT NOT NULL,
            used_colors_json TEXT NOT NULL,
            original_photo_path TEXT NOT NULL,
            title TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE shopping_checks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pattern_id INTEGER NOT NULL,
            color_id TEXT NOT NULL,
            is_checked INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (pattern_id) REFERENCES patterns(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  /// Save a pattern and return its ID.
  static Future<int> savePattern(PatternData pattern) async {
    final db = await database;
    return db.insert('patterns', pattern.toDbMap());
  }

  /// Get all saved patterns, newest first.
  static Future<List<PatternData>> getAllPatterns() async {
    final db = await database;
    final maps = await db.query('patterns', orderBy: 'created_at DESC');
    return maps.map((m) => PatternData.fromDbMap(m)).toList();
  }

  /// Get a single pattern by ID.
  static Future<PatternData?> getPattern(int id) async {
    final db = await database;
    final maps = await db.query('patterns', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return PatternData.fromDbMap(maps.first);
  }

  /// Delete a pattern.
  static Future<void> deletePattern(int id) async {
    final db = await database;
    await db.delete('patterns', where: 'id = ?', whereArgs: [id]);
    await db.delete('shopping_checks', where: 'pattern_id = ?', whereArgs: [id]);
  }

  /// Get shopping check states for a pattern.
  static Future<Map<String, bool>> getShoppingChecks(int patternId) async {
    final db = await database;
    final maps = await db.query(
      'shopping_checks',
      where: 'pattern_id = ?',
      whereArgs: [patternId],
    );
    return {for (final m in maps) m['color_id'] as String: m['is_checked'] == 1};
  }

  /// Update shopping check state.
  static Future<void> setShoppingCheck(
    int patternId,
    String colorId,
    bool checked,
  ) async {
    final db = await database;
    final existing = await db.query(
      'shopping_checks',
      where: 'pattern_id = ? AND color_id = ?',
      whereArgs: [patternId, colorId],
    );
    if (existing.isEmpty) {
      await db.insert('shopping_checks', {
        'pattern_id': patternId,
        'color_id': colorId,
        'is_checked': checked ? 1 : 0,
      });
    } else {
      await db.update(
        'shopping_checks',
        {'is_checked': checked ? 1 : 0},
        where: 'pattern_id = ? AND color_id = ?',
        whereArgs: [patternId, colorId],
      );
    }
  }

  /// Get total pattern count.
  static Future<int> getPatternCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM patterns');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
