import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_rural.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create bus timetables table
    await db.execute('''
      CREATE TABLE bus_timetables (
        id TEXT PRIMARY KEY,
        from_location TEXT NOT NULL,
        to_location TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        bus_type TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        synced_at TEXT
      )
    ''');

    // Create sync metadata table to track last sync time
    await db.execute('''
      CREATE TABLE sync_metadata (
        id INTEGER PRIMARY KEY,
        last_sync TEXT NOT NULL
      )
    ''');
  }

  // Save bus timetables to local database
  Future<void> saveBusTimetables(List<Map<String, dynamic>> timetables) async {
    final db = await database;
    final batch = db.batch();

    // Clear old data
    batch.delete('bus_timetables');

    // Insert new data
    for (var timetable in timetables) {
      batch.insert(
        'bus_timetables',
        {
          'id': timetable['_id'] ?? timetable['id'],
          'from_location': timetable['from'],
          'to_location': timetable['to'],
          'start_time': timetable['startTime'],
          'end_time': timetable['endTime'],
          'bus_type': timetable['busType'],
          'created_at': timetable['createdAt'],
          'updated_at': timetable['updatedAt'],
          'synced_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    await updateLastSync();
  }

  // Get all bus timetables from local database
  Future<List<Map<String, dynamic>>> getBusTimetables({
    String? from,
    String? to,
    String? startTime,
    String? busType,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (from != null && from.isNotEmpty) {
      whereClause += 'from_location LIKE ?';
      whereArgs.add('%$from%');
    }

    if (to != null && to.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'to_location LIKE ?';
      whereArgs.add('%$to%');
    }

    if (startTime != null && startTime.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'start_time >= ?';
      whereArgs.add(startTime);
    }

    if (busType != null && busType.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'bus_type = ?';
      whereArgs.add(busType);
    }

    final results = await db.query(
      'bus_timetables',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'start_time ASC',
    );

    return results;
  }

  // Update last sync time
  Future<void> updateLastSync() async {
    final db = await database;
    await db.delete('sync_metadata');
    await db.insert('sync_metadata', {
      'id': 1,
      'last_sync': DateTime.now().toIso8601String(),
    });
  }

  // Get last sync time
  Future<DateTime?> getLastSync() async {
    final db = await database;
    final results = await db.query('sync_metadata', limit: 1);
    
    if (results.isEmpty) return null;
    return DateTime.parse(results.first['last_sync'] as String);
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // DEBUG: Get count of cached timetables
  Future<int> getCachedTimetablesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM bus_timetables');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // DEBUG: Clear all cached data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('bus_timetables');
    await db.delete('sync_metadata');
  }
}