import 'package:flutter/foundation.dart';
import 'package:moments/data/models/pending_action.dart';
import 'package:moments/core/services/pending_action_service.dart';
import 'package:moments/core/services/sync_queue_processor.dart';

/// Helper class to wrap operations with offline-first queueing
/// Use this instead of direct Supabase calls for supported operations
class OfflineActionHelper {
  static final OfflineActionHelper _instance = OfflineActionHelper._internal();
  factory OfflineActionHelper() => _instance;
  OfflineActionHelper._internal();

  final _actionService = PendingActionService();
  final _processor = SyncQueueProcessor();

  /// Queue a delete moment action
  /// If online, executes immediately; otherwise queues for later
  Future<void> deleteMoment(String momentId) async {
    if (_processor.isOnline) {
      // Try immediate execution
      try {
        await _executeImmediately(
          PendingActionType.deleteMoment,
          'moment',
          momentId,
        );
        return;
      } catch (e) {
        debugPrint('Immediate delete failed, queueing: $e');
      }
    }

    // Queue for later
    await _actionService.queueAction(
      actionType: PendingActionType.deleteMoment,
      entityType: 'moment',
      entityId: momentId,
      priority: ActionPriority.high,
    );
  }

  /// Queue a toggle moment privacy action
  Future<void> toggleMomentPrivacy(String momentId, bool isPrivate) async {
    // Remove any existing privacy toggle actions for this moment
    await _actionService.deduplicateActions(
      PendingActionType.toggleMomentPrivacy,
      'moment',
      momentId,
    );

    if (_processor.isOnline) {
      try {
        await _executeImmediately(
          PendingActionType.toggleMomentPrivacy,
          'moment',
          momentId,
          payload: {'is_private': isPrivate},
        );
        return;
      } catch (e) {
        debugPrint('Immediate privacy toggle failed, queueing: $e');
      }
    }

    await _actionService.queueAction(
      actionType: PendingActionType.toggleMomentPrivacy,
      entityType: 'moment',
      entityId: momentId,
      payload: {'is_private': isPrivate},
      priority: ActionPriority.high,
    );
  }

  /// Queue a toggle group privacy action
  Future<void> toggleGroupPrivacy(String groupId, bool isPrivate) async {
    await _actionService.deduplicateActions(
      PendingActionType.toggleGroupPrivacy,
      'moment_group',
      groupId,
    );

    if (_processor.isOnline) {
      try {
        await _executeImmediately(
          PendingActionType.toggleGroupPrivacy,
          'moment_group',
          groupId,
          payload: {'is_private': isPrivate},
        );
        return;
      } catch (e) {
        debugPrint('Immediate group privacy toggle failed, queueing: $e');
      }
    }

    await _actionService.queueAction(
      actionType: PendingActionType.toggleGroupPrivacy,
      entityType: 'moment_group',
      entityId: groupId,
      payload: {'is_private': isPrivate},
      priority: ActionPriority.high,
    );
  }

  /// Queue an add reaction action
  Future<void> addReaction(String momentId, String emoji) async {
    if (_processor.isOnline) {
      try {
        await _executeImmediately(
          PendingActionType.addReaction,
          'moment',
          momentId,
          payload: {'moment_id': momentId, 'emoji': emoji},
        );
        return;
      } catch (e) {
        debugPrint('Immediate add reaction failed, queueing: $e');
      }
    }

    await _actionService.queueAction(
      actionType: PendingActionType.addReaction,
      entityType: 'moment',
      entityId: momentId,
      payload: {'moment_id': momentId, 'emoji': emoji},
      priority: ActionPriority.medium,
    );
  }

  /// Queue a remove reaction action
  Future<void> removeReaction(String reactionId) async {
    if (_processor.isOnline) {
      try {
        await _executeImmediately(
          PendingActionType.removeReaction,
          'reaction',
          reactionId,
          payload: {'reaction_id': reactionId},
        );
        return;
      } catch (e) {
        debugPrint('Immediate remove reaction failed, queueing: $e');
      }
    }

    await _actionService.queueAction(
      actionType: PendingActionType.removeReaction,
      entityType: 'reaction',
      entityId: reactionId,
      payload: {'reaction_id': reactionId},
      priority: ActionPriority.medium,
    );
  }

  /// Queue an edit message action
  Future<void> editMessage(String messageId, String content) async {
    await _actionService.deduplicateActions(
      PendingActionType.editMessage,
      'message',
      messageId,
    );

    if (_processor.isOnline) {
      try {
        await _executeImmediately(
          PendingActionType.editMessage,
          'message',
          messageId,
          payload: {'content': content},
        );
        return;
      } catch (e) {
        debugPrint('Immediate edit message failed, queueing: $e');
      }
    }

    await _actionService.queueAction(
      actionType: PendingActionType.editMessage,
      entityType: 'message',
      entityId: messageId,
      payload: {'content': content},
      priority: ActionPriority.medium,
    );
  }

  /// Queue a delete message action
  Future<void> deleteMessage(String messageId) async {
    if (_processor.isOnline) {
      try {
        await _executeImmediately(
          PendingActionType.deleteMessage,
          'message',
          messageId,
        );
        return;
      } catch (e) {
        debugPrint('Immediate delete message failed, queueing: $e');
      }
    }

    await _actionService.queueAction(
      actionType: PendingActionType.deleteMessage,
      entityType: 'message',
      entityId: messageId,
      priority: ActionPriority.high,
    );
  }

  /// Get pending action count for UI display
  Future<int> getPendingCount() async {
    return _actionService.getPendingCount();
  }

  /// Force process queue (manual sync button)
  Future<SyncResult> forceSync() async {
    return _processor.processQueue();
  }

  /// Execute action immediately via the processor
  /// Queues the action and immediately processes it
  Future<void> _executeImmediately(
    PendingActionType actionType,
    String entityType,
    String entityId, {
    Map<String, dynamic>? payload,
  }) async {
    // Queue the action and immediately process
    await _actionService.queueAction(
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      priority: ActionPriority.high,
    );
    await _processor.processQueue();
  }
}
