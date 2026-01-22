import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moments/data/models/pending_action.dart';
import 'package:moments/core/services/pending_action_service.dart';

/// Processor for syncing queued offline actions when connectivity is restored
/// Handles execution of pending actions and error recovery
class SyncQueueProcessor {
  static final SyncQueueProcessor _instance = SyncQueueProcessor._internal();
  factory SyncQueueProcessor() => _instance;
  SyncQueueProcessor._internal();

  final _actionService = PendingActionService();
  final _supabase = Supabase.instance.client;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isProcessing = false;
  bool _isOnline = true;

  /// Initialize connectivity listener
  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    // Check initial connectivity
    Connectivity().checkConnectivity().then(_handleConnectivityChange);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    debugPrint('Connectivity changed: $_isOnline (was: $wasOnline)');

    // If we just came online, process the queue
    if (_isOnline && !wasOnline) {
      processQueue();
    }
  }

  /// Check if currently online
  bool get isOnline => _isOnline;

  /// Process all pending actions in the queue
  Future<SyncResult> processQueue() async {
    if (_isProcessing) {
      debugPrint('Queue processing already in progress');
      return SyncResult(processed: 0, failed: 0, remaining: 0);
    }

    if (!_isOnline) {
      debugPrint('Cannot process queue - offline');
      final remaining = await _actionService.getPendingCount();
      return SyncResult(processed: 0, failed: 0, remaining: remaining);
    }

    _isProcessing = true;
    int processed = 0;
    int failed = 0;

    try {
      final actions = await _actionService.getPendingActions();
      debugPrint('Processing ${actions.length} pending actions...');

      for (final action in actions) {
        // Check if still online
        if (!_isOnline) {
          debugPrint('Lost connectivity, pausing queue processing');
          break;
        }

        try {
          await _executeAction(action);
          await _actionService.removeAction(action.id);
          processed++;
          debugPrint(
            'Processed action: ${action.actionType.name} for ${action.entityId}',
          );
        } catch (e) {
          failed++;
          await _actionService.markFailed(action.id, e.toString());
          debugPrint('Failed action ${action.id}: $e');
        }
      }
    } finally {
      _isProcessing = false;
    }

    final remaining = await _actionService.getPendingCount();
    debugPrint(
      'Queue processing complete: $processed processed, $failed failed, $remaining remaining',
    );

    return SyncResult(
      processed: processed,
      failed: failed,
      remaining: remaining,
    );
  }

  /// Execute a single pending action
  Future<void> _executeAction(PendingAction action) async {
    switch (action.actionType) {
      case PendingActionType.deleteMoment:
        await _deleteMoment(action);
        break;
      case PendingActionType.toggleMomentPrivacy:
        await _toggleMomentPrivacy(action);
        break;
      case PendingActionType.toggleGroupPrivacy:
        await _toggleGroupPrivacy(action);
        break;
      case PendingActionType.addReaction:
        await _addReaction(action);
        break;
      case PendingActionType.removeReaction:
        await _removeReaction(action);
        break;
      case PendingActionType.editMessage:
        await _editMessage(action);
        break;
      case PendingActionType.deleteMessage:
        await _deleteMessage(action);
        break;
    }
  }

  // ============================================
  // ACTION EXECUTORS
  // ============================================

  Future<void> _deleteMoment(PendingAction action) async {
    await _supabase.from('moments').delete().eq('id', action.entityId);
  }

  Future<void> _toggleMomentPrivacy(PendingAction action) async {
    final isPrivate = action.payload?['is_private'] as bool? ?? false;
    await _supabase
        .from('moments')
        .update({'is_private': isPrivate})
        .eq('id', action.entityId);
  }

  Future<void> _toggleGroupPrivacy(PendingAction action) async {
    final isPrivate = action.payload?['is_private'] as bool? ?? false;
    final groupId = action.entityId;

    // Update the group
    await _supabase
        .from('moment_groups')
        .update({'is_private': isPrivate})
        .eq('id', groupId);

    // Also update all moments in the group owned by this user
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase
          .from('moments')
          .update({'is_private': isPrivate})
          .eq('moment_group_id', groupId)
          .eq('user_id', userId);
    }
  }

  Future<void> _addReaction(PendingAction action) async {
    final emoji = action.payload?['emoji'] as String?;
    final momentId = action.payload?['moment_id'] as String?;
    final userId = _supabase.auth.currentUser?.id;

    if (emoji == null || momentId == null || userId == null) return;

    await _supabase.from('moment_reactions').upsert({
      'moment_id': momentId,
      'user_id': userId,
      'emoji': emoji,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _removeReaction(PendingAction action) async {
    final reactionId = action.payload?['reaction_id'] as String?;
    if (reactionId == null) return;

    await _supabase.from('moment_reactions').delete().eq('id', reactionId);
  }

  Future<void> _editMessage(PendingAction action) async {
    final content = action.payload?['content'] as String?;
    if (content == null) return;

    await _supabase
        .from('messages')
        .update({
          'content': content,
          'is_edited': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', action.entityId);
  }

  Future<void> _deleteMessage(PendingAction action) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Soft delete - add to deleted_for array
    await _supabase.rpc(
      'soft_delete_message',
      params: {'message_id': action.entityId, 'user_id': userId},
    );
  }

  /// Dispose of connectivity listener
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}

/// Result of queue processing
class SyncResult {
  final int processed;
  final int failed;
  final int remaining;

  SyncResult({
    required this.processed,
    required this.failed,
    required this.remaining,
  });

  bool get hasRemaining => remaining > 0;
  bool get hadFailures => failed > 0;
  bool get isComplete => remaining == 0;
}
