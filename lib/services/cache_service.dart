import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/models.dart';

/// Service for local caching using SQLite
/// Provides offline support for event passes and pending actions
class CacheService {
  static Database? _database;
  static const String _dbName = 'event_attendance.db';
  static const int _dbVersion = 1;

  // Table names
  static const String _tableEventPasses = 'event_passes';
  static const String _tablePendingActions = 'pending_actions';
  static const String _tableAppSettings = 'app_settings';

  /// Get database instance (singleton pattern)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Event passes table
    await db.execute('''
      CREATE TABLE $_tableEventPasses (
        pass_id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL,
        registration_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        event_data TEXT NOT NULL,
        pass_data TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    // Pending actions table (for offline mode)
    await db.execute('''
      CREATE TABLE $_tablePendingActions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        action_data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // App settings table
    await db.execute('''
      CREATE TABLE $_tableAppSettings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes
    await db.execute(
        'CREATE INDEX idx_event_passes_event_id ON $_tableEventPasses(event_id)');
    await db.execute(
        'CREATE INDEX idx_event_passes_user_id ON $_tableEventPasses(user_id)');
    await db.execute(
        'CREATE INDEX idx_pending_actions_created_at ON $_tablePendingActions(created_at)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations
  }

  // Event Pass Caching Methods

  /// Cache an event pass for offline access
  Future<void> cacheEventPass(EventPass pass, Event event) async {
    final db = await database;
    await db.insert(
      _tableEventPasses,
      {
        'pass_id': pass.passId,
        'event_id': pass.eventId,
        'registration_id': pass.registrationId,
        'user_id': pass.userId,
        'event_data': jsonEncode(event.toJson()),
        'pass_data': jsonEncode(pass.toJson()),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all cached event passes for a user
  Future<List<Map<String, dynamic>>> getCachedPasses(String userId) async {
    final db = await database;
    final results = await db.query(
      _tableEventPasses,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'cached_at DESC',
    );

    return results.map((row) {
      return {
        'pass': EventPass.fromJson(jsonDecode(row['pass_data'] as String)),
        'event': Event.fromJson(jsonDecode(row['event_data'] as String)),
        'cachedAt': DateTime.fromMillisecondsSinceEpoch(row['cached_at'] as int),
      };
    }).toList();
  }

  /// Get a specific cached event pass
  Future<Map<String, dynamic>?> getCachedPass(String passId) async {
    final db = await database;
    final results = await db.query(
      _tableEventPasses,
      where: 'pass_id = ?',
      whereArgs: [passId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final row = results.first;
    return {
      'pass': EventPass.fromJson(jsonDecode(row['pass_data'] as String)),
      'event': Event.fromJson(jsonDecode(row['event_data'] as String)),
      'cachedAt': DateTime.fromMillisecondsSinceEpoch(row['cached_at'] as int),
    };
  }

  /// Delete a cached event pass
  Future<void> deleteCachedPass(String passId) async {
    final db = await database;
    await db.delete(
      _tableEventPasses,
      where: 'pass_id = ?',
      whereArgs: [passId],
    );
  }

  /// Clear all cached event passes
  Future<void> clearPassCache() async {
    final db = await database;
    await db.delete(_tableEventPasses);
  }

  /// Get count of cached passes
  Future<int> getCachedPassCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableEventPasses');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Pending Actions Methods (for offline mode)

  /// Add a pending action to the queue
  Future<int> addPendingAction(String actionType, Map<String, dynamic> actionData) async {
    final db = await database;
    return await db.insert(_tablePendingActions, {
      'action_type': actionType,
      'action_data': jsonEncode(actionData),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'retry_count': 0,
    });
  }

  /// Get all pending actions
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await database;
    final results = await db.query(
      _tablePendingActions,
      orderBy: 'created_at ASC',
    );

    return results.map((row) {
      return {
        'id': row['id'],
        'actionType': row['action_type'],
        'actionData': jsonDecode(row['action_data'] as String),
        'createdAt': DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        'retryCount': row['retry_count'],
      };
    }).toList();
  }

  /// Delete a pending action
  Future<void> deletePendingAction(int id) async {
    final db = await database;
    await db.delete(
      _tablePendingActions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Increment retry count for a pending action
  Future<void> incrementRetryCount(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $_tablePendingActions SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  /// Clear all pending actions
  Future<void> clearPendingActions() async {
    final db = await database;
    await db.delete(_tablePendingActions);
  }

  /// Get count of pending actions
  Future<int> getPendingActionCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tablePendingActions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // App Settings Methods

  /// Save an app setting
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      _tableAppSettings,
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get an app setting
  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      _tableAppSettings,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  /// Delete an app setting
  Future<void> deleteSetting(String key) async {
    final db = await database;
    await db.delete(
      _tableAppSettings,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  /// Clear all app settings
  Future<void> clearSettings() async {
    final db = await database;
    await db.delete(_tableAppSettings);
  }

  // Utility Methods

  /// Clear all cached data (passes, actions, settings)
  Future<void> clearCache() async {
    await clearPassCache();
    await clearPendingActions();
    await clearSettings();
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    final file = await databaseFactory.openDatabase(path);
    await file.close();
    // Note: Actual file size calculation would require platform-specific code
    return 0; // Placeholder
  }
}

/// Exception thrown when cache operations fail
class CacheException implements Exception {
  final String message;

  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}
