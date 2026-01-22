import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:moments/data/models/pending_action.dart';

/// Service for managing pending offline actions in SQLite
/// Handles queueing actions when offline and retrieving them for sync
class PendingActionService {
  static final PendingActionService _instance =
      PendingActionService._internal();
  factory PendingActionService() => _instance;
  PendingActionService._internal();

  static const String _dbName = 'pending_actions.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'pending_actions';
  static const int _maxRetries = 5;

  Database? _database;
  final _uuid = const Uuid();

  /// Initialize the database
  Future<Database> _initDatabase() async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            action_type TEXT NOT NULL,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            payload TEXT,
            created_at TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0,
            last_error TEXT,
            priority TEXT DEFAULT 'medium'
          )
        ''');

        // Index for efficient priority-based retrieval
        await db.execute('''
          CREATE INDEX idx_priority ON $_tableName(priority, created_at)
        ''');
      },
    );

    return _database!;
  }

  /// Queue a new action for offline sync
  /// Returns the action ID
  Future<String> queueAction({
    required PendingActionType actionType,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? payload,
    ActionPriority priority = ActionPriority.medium,
  }) async {
    final db = await _initDatabase();
    final id = _uuid.v4();

    final action = PendingAction(
      id: id,
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      // Always store as UTC
      createdAt: DateTime.now().toUtc(),
      priority: priority,
    );

    await db.insert(_tableName, action.toRow());
    debugPrint('Queued action: ${actionType.name} for $entityType:$entityId');

    return id;
  }

  /// Get all pending actions ordered by priority (high first) then by creation time
  Future<List<PendingAction>> getPendingActions() async {
    final db = await _initDatabase();

    // Order: high priority first, then by creation time (oldest first)
    final rows = await db.query(
      _tableName,
      orderBy: '''
        CASE priority 
          WHEN 'high' THEN 1 
          WHEN 'medium' THEN 2 
          WHEN 'low' THEN 3 
        END,
        created_at ASC
      ''',
    );

    return rows.map((row) => PendingAction.fromRow(row)).toList();
  }

  /// Get count of pending actions
  Future<int> getPendingCount() async {
    final db = await _initDatabase();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get actions for a specific entity (to check if already queued)
  Future<List<PendingAction>> getActionsForEntity(
    String entityType,
    String entityId,
  ) async {
    final db = await _initDatabase();
    final rows = await db.query(
      _tableName,
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
    );
    return rows.map((row) => PendingAction.fromRow(row)).toList();
  }

  /// Mark action as failed with error, increment retry count
  Future<void> markFailed(String actionId, String error) async {
    final db = await _initDatabase();

    // Get current retry count
    final rows = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [actionId],
    );

    if (rows.isEmpty) return;

    final currentRetry = rows.first['retry_count'] as int? ?? 0;

    if (currentRetry >= _maxRetries - 1) {
      // Max retries reached, remove the action
      await removeAction(actionId);
      debugPrint('Action $actionId exceeded max retries, removed');
    } else {
      // Increment retry count
      await db.update(
        _tableName,
        {'retry_count': currentRetry + 1, 'last_error': error},
        where: 'id = ?',
        whereArgs: [actionId],
      );
    }
  }

  /// Remove a successfully processed action
  Future<void> removeAction(String actionId) async {
    final db = await _initDatabase();
    await db.delete(_tableName, where: 'id = ?', whereArgs: [actionId]);
  }

  /// Remove all actions for an entity (e.g., when entity is deleted)
  Future<void> removeActionsForEntity(
    String entityType,
    String entityId,
  ) async {
    final db = await _initDatabase();
    await db.delete(
      _tableName,
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
    );
  }

  /// Clear all pending actions (use with caution)
  Future<void> clearAll() async {
    final db = await _initDatabase();
    await db.delete(_tableName);
  }

  /// Check if there are any pending actions
  Future<bool> hasPendingActions() async {
    return (await getPendingCount()) > 0;
  }

  /// Deduplicate actions - remove older duplicate actions for same entity/action
  /// This prevents queuing multiple identical actions
  Future<void> deduplicateActions(
    PendingActionType actionType,
    String entityType,
    String entityId,
  ) async {
    final db = await _initDatabase();

    // Get all matching actions
    final rows = await db.query(
      _tableName,
      where: 'action_type = ? AND entity_type = ? AND entity_id = ?',
      whereArgs: [actionType.name, entityType, entityId],
      orderBy: 'created_at DESC', // Keep the newest
    );

    if (rows.length <= 1) return;

    // Remove all but the newest
    final idsToRemove = rows.skip(1).map((r) => r['id'] as String).toList();
    for (final id in idsToRemove) {
      await removeAction(id);
    }

    debugPrint(
      'Deduplicated ${idsToRemove.length} actions for $entityType:$entityId',
    );
  }
}
