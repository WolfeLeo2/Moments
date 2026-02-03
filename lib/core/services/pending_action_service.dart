import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:moments/data/models/pending_action.dart';
import 'package:moments/core/database/database.dart';

/// Service for managing pending offline actions using Drift
/// Handles queueing actions when offline and retrieving them for sync
class PendingActionService {
  final AppDatabase _database;
  final _uuid = const Uuid();

  /// Creates a PendingActionService with the required database dependency.
  PendingActionService(this._database);

  /// Queue a new action for offline sync
  /// Returns the action ID
  Future<String> queueAction({
    required PendingActionType actionType,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? payload,
    ActionPriority priority = ActionPriority.medium,
  }) async {
    final id = _uuid.v4();

    final action = PendingAction(
      id: id,
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      createdAt: DateTime.now().toUtc(),
      priority: priority,
    );

    await _database.queuePendingAction(action.toCompanion());
    debugPrint('Queued action: ${actionType.name} for $entityType:$entityId');

    return id;
  }

  /// Get all pending actions ordered by priority (high first) then by creation time
  Future<List<PendingAction>> getPendingActions() async {
    final entries = await _database.getPendingActions();
    return entries.map((e) => e.toModel()).toList();
  }

  /// Get count of pending actions
  Future<int> getPendingCount() async {
    return _database.getPendingActionCount();
  }

  /// Get actions for a specific entity (to check if already queued)
  Future<List<PendingAction>> getActionsForEntity(
    String entityType,
    String entityId,
  ) async {
    final entries = await _database.getActionsForEntity(entityType, entityId);
    return entries.map((e) => e.toModel()).toList();
  }

  /// Mark action as failed with error, increment retry count
  Future<void> markFailed(String actionId, String error) async {
    await _database.markActionFailed(actionId, error);
  }

  /// Remove a successfully processed action
  Future<void> removeAction(String actionId) async {
    await _database.removePendingAction(actionId);
  }

  /// Remove all actions for an entity (e.g., when entity is deleted)
  Future<void> removeActionsForEntity(
    String entityType,
    String entityId,
  ) async {
    await _database.removeActionsForEntity(entityType, entityId);
  }

  /// Clear all pending actions (use with caution)
  Future<void> clearAll() async {
    await _database.clearAllPendingActions();
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
    final entries = await _database.getActionsForEntity(entityType, entityId);
    final matching = entries.where((e) => e.actionType == actionType.name).toList();
    
    if (matching.length <= 1) return;

    // Sort by created time descending (keep newest)
    matching.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Remove all but the newest
    for (int i = 1; i < matching.length; i++) {
      await _database.removePendingAction(matching[i].id);
    }

    debugPrint(
      'Deduplicated ${matching.length - 1} actions for $entityType:$entityId',
    );
  }
}
