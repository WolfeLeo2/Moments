import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/database/database.dart';
import 'package:moments/core/providers/database_provider.dart';
import 'package:moments/core/services/app_logger.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/models/pending_action.dart';
import 'package:moments/data/models/reaction.dart';
import 'package:moments/data/repositories/chat_repository.dart';
import 'package:moments/features/chat/providers/chat_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'chat_offline_service.g.dart';

final _log = AppLogger('ChatOfflineService');
const _uuid = Uuid();

/// Provider for chat offline service
@Riverpod(keepAlive: true)
ChatOfflineService chatOfflineService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);
  return ChatOfflineService(db: db, chatRepo: chatRepo);
}

/// Comprehensive offline-first chat service
/// Handles: text messages, media messages, edits, deletes, reactions
class ChatOfflineService {
  final AppDatabase db;
  final ChatRepository chatRepo;

  Timer? _syncTimer;
  bool _isSyncing = false;
  int _retryAttempt = 0;
  static const int maxRetries = 5;
  bool _started = false;

  ChatOfflineService({required this.db, required this.chatRepo});

  // ============================================
  // LIFECYCLE
  // ============================================

  /// Start the background sync processor
  void start() {
    if (_started) return;
    _started = true;
    _log.d('Starting chat offline service');
    _scheduleSync();
  }

  /// Stop the background sync processor
  void stop() {
    _log.d('Stopping chat offline service');
    _syncTimer?.cancel();
    _syncTimer = null;
    _started = false;
  }

  /// Schedule next sync with exponential backoff
  void _scheduleSync() {
    _syncTimer?.cancel();

    // Exponential backoff: 5s, 10s, 20s, 40s, 80s (max)
    final delay = Duration(seconds: 5 * (1 << _retryAttempt.clamp(0, 4)));

    _syncTimer = Timer(delay, () => _processQueue());
  }

  // ============================================
  // OPTIMISTIC TEXT SENDING
  // ============================================

  /// Send a text message with optimistic UI
  /// Shows message immediately, syncs to server in background
  Future<void> sendTextOptimistic({
    required String conversationId,
    required String senderId,
    required String content,
    String? replyToMessageId,
    Message? replyToMessage,
  }) async {
    final localId = _uuid.v4();
    final now = DateTime.now();

    final optimisticMessage = Message(
      id: localId,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      messageType: MessageType.text,
      createdAt: now,
      updatedAt: now,
      replyToMessageId: replyToMessageId,
      replyToMessage: replyToMessage,
      sendStatus: MessageSendStatus.pending,
      localOnly: true,
    );

    // Save to Drift immediately (shows in UI instantly)
    await db.saveMessages([optimisticMessage.toCompanion()]);
    _log.d('Saved optimistic text message: $localId');

    // Send to server in background
    try {
      await db.updateMessageStatus(localId, MessageSendStatus.sending.name);

      final serverMessage = await chatRepo.sendMessage(
        conversationId: conversationId,
        content: content,
        replyToMessageId: replyToMessageId,
      );

      // Replace local with server message
      await db.deleteMessage(localId);
      await db.saveMessages([
        serverMessage
            .copyWith(sendStatus: MessageSendStatus.sent, localOnly: false)
            .toCompanion(),
      ]);

      _log.d('Text message synced: ${serverMessage.id}');
    } catch (e) {
      _log.w('Failed to send text message: $localId', error: e);
      await db.updateMessageStatus(localId, MessageSendStatus.failed.name);
    }
  }

  // ============================================
  // OPTIMISTIC MEDIA SENDING
  // ============================================

  /// Send an image message with optimistic UI
  /// Shows local preview immediately, uploads in background
  Future<void> sendImageOptimistic({
    required String conversationId,
    required String senderId,
    required String localPath,
    Map<String, dynamic>? metadata,
  }) async {
    final localId = _uuid.v4();
    final now = DateTime.now();

    final message = Message(
      id: localId,
      conversationId: conversationId,
      senderId: senderId,
      content: 'Image',
      messageType: MessageType.image,
      localMediaPath: localPath,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
      sendStatus: MessageSendStatus.pending,
      localOnly: true,
    );

    // Save locally for instant UI
    await db.saveMessages([message.toCompanion()]);
    _log.d('Saved optimistic image message: $localId');

    // Try to upload immediately
    await _uploadMediaMessage(message);
  }

  /// Send an audio message with optimistic UI
  Future<void> sendAudioOptimistic({
    required String conversationId,
    required String senderId,
    required String localPath,
    required int durationMs,
  }) async {
    final localId = _uuid.v4();
    final now = DateTime.now();

    final message = Message(
      id: localId,
      conversationId: conversationId,
      senderId: senderId,
      content: 'Voice note',
      messageType: MessageType.audio,
      localMediaPath: localPath,
      metadata: {'duration_ms': durationMs},
      createdAt: now,
      updatedAt: now,
      sendStatus: MessageSendStatus.pending,
      localOnly: true,
    );

    await db.saveMessages([message.toCompanion()]);
    _log.d('Saved optimistic audio message: $localId');

    await _uploadMediaMessage(message);
  }

  /// Send a video message with optimistic UI
  Future<void> sendVideoOptimistic({
    required String conversationId,
    required String senderId,
    required String localPath,
  }) async {
    final localId = _uuid.v4();
    final now = DateTime.now();

    final message = Message(
      id: localId,
      conversationId: conversationId,
      senderId: senderId,
      content: 'Video',
      messageType: MessageType.video,
      localMediaPath: localPath,
      createdAt: now,
      updatedAt: now,
      sendStatus: MessageSendStatus.pending,
      localOnly: true,
    );

    await db.saveMessages([message.toCompanion()]);
    _log.d('Saved optimistic video message: $localId');

    await _uploadMediaMessage(message);
  }

  /// Upload a media message to server
  Future<void> _uploadMediaMessage(Message message) async {
    try {
      // Update status to sending
      await db.updateMessageStatus(message.id, MessageSendStatus.sending.name);

      Message serverMessage;

      switch (message.messageType) {
        case MessageType.image:
          serverMessage = await chatRepo.sendImageMessage(
            conversationId: message.conversationId,
            imagePath: message.localMediaPath!,
          );
          break;
        case MessageType.audio:
          final durationMs = message.metadata?['duration_ms'] as int? ?? 0;
          serverMessage = await chatRepo.sendAudioMessage(
            conversationId: message.conversationId,
            audioPath: message.localMediaPath!,
            durationMs: durationMs,
          );
          break;
        case MessageType.video:
          serverMessage = await chatRepo.sendVideoMessage(
            conversationId: message.conversationId,
            videoPath: message.localMediaPath!,
          );
          break;
        default:
          throw Exception('Unsupported media type: ${message.messageType}');
      }

      // Success - replace local with server message
      await db.deleteMessage(message.id);
      await db.saveMessages([
        serverMessage
            .copyWith(sendStatus: MessageSendStatus.sent, localOnly: false)
            .toCompanion(),
      ]);

      _log.d('Media message uploaded: ${serverMessage.id}');
    } catch (e) {
      _log.w('Failed to upload media message: ${message.id}', error: e);
      await db.updateMessageStatus(message.id, MessageSendStatus.failed.name);
    }
  }

  // ============================================
  // OPTIMISTIC EDIT
  // ============================================

  /// Edit a message with optimistic UI
  Future<void> editMessageOptimistic({
    required String messageId,
    required String newContent,
  }) async {
    // 1. Update locally immediately
    await db.updateMessageContent(messageId, newContent);
    _log.d('Updated message content locally: $messageId');

    // 2. Try to sync to server
    try {
      await chatRepo.editMessage(messageId: messageId, newContent: newContent);
      _log.d('Message edit synced to server: $messageId');
    } catch (e) {
      _log.w('Failed to sync message edit, queuing for retry', error: e);

      // Queue for later sync
      await db.queuePendingAction(
        PendingActionsCompanion.insert(
          id: _uuid.v4(),
          actionType: PendingActionType.editMessage.name,
          entityType: 'message',
          entityId: messageId,
          payload: Value(jsonEncode({'content': newContent})),
          createdAt: DateTime.now().toIso8601String(),
          priority: const Value('medium'),
        ),
      );
    }
  }

  // ============================================
  // OPTIMISTIC DELETE
  // ============================================

  /// Delete a message for self with optimistic UI
  Future<void> deleteForSelfOptimistic({
    required String messageId,
    required String currentUserId,
  }) async {
    // 1. Mark deleted locally
    await db.markMessageDeletedLocally(messageId, deletedFor: currentUserId);
    _log.d('Marked message deleted for self locally: $messageId');

    // 2. Try to sync to server
    try {
      await chatRepo.deleteMessageForSelf(messageId);
      _log.d('Delete for self synced to server: $messageId');
    } catch (e) {
      _log.w('Failed to sync delete for self, queuing for retry', error: e);

      await db.queuePendingAction(
        PendingActionsCompanion.insert(
          id: _uuid.v4(),
          actionType: PendingActionType.deleteMessage.name,
          entityType: 'message',
          entityId: messageId,
          payload: Value(jsonEncode({'userId': currentUserId})),
          createdAt: DateTime.now().toIso8601String(),
          priority: const Value('high'),
        ),
      );
    }
  }

  /// Delete a message for everyone with optimistic UI
  Future<void> deleteForEveryoneOptimistic({required String messageId}) async {
    // 1. Mark deleted locally
    await db.markMessageDeletedLocally(messageId, deletedFor: 'everyone');
    _log.d('Marked message deleted for everyone locally: $messageId');

    // 2. Try to sync to server
    try {
      await chatRepo.deleteMessageForEveryone(messageId);
      _log.d('Delete for everyone synced to server: $messageId');
    } catch (e) {
      _log.w('Failed to sync delete for everyone, queuing for retry', error: e);

      await db.queuePendingAction(
        PendingActionsCompanion.insert(
          id: _uuid.v4(),
          actionType: PendingActionType.deleteMessageForEveryone.name,
          entityType: 'message',
          entityId: messageId,
          createdAt: DateTime.now().toIso8601String(),
          priority: const Value('high'),
        ),
      );
    }
  }

  // ============================================
  // OPTIMISTIC REACTIONS
  // ============================================

  /// Add a reaction with optimistic UI
  Future<void> addReactionOptimistic({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    // 1. Get current message
    final entry = await db.getMessageById(messageId);
    if (entry == null) return;

    final message = entry.toModel();

    // 2. Update reactions locally
    final reactions = List<Reaction>.from(message.reactions);

    // Remove existing reaction from this user (if any)
    reactions.removeWhere((r) => r.userId == userId);

    // Add new reaction
    reactions.add(
      Reaction(
        id: _uuid.v4(),
        messageId: messageId,
        userId: userId,
        emoji: emoji,
        createdAt: DateTime.now(),
      ),
    );

    // 3. Save to database
    final reactionsJson = jsonEncode(reactions.map((r) => r.toJson()).toList());
    await db.updateMessageReactions(messageId, reactionsJson);
    _log.d('Added reaction locally: $emoji on $messageId');

    // 4. Try to sync to server
    try {
      await chatRepo.addReaction(messageId, emoji);
      _log.d('Reaction synced to server');
    } catch (e) {
      _log.w('Failed to sync reaction, queuing for retry', error: e);

      await db.queuePendingAction(
        PendingActionsCompanion.insert(
          id: _uuid.v4(),
          actionType: PendingActionType.addReaction.name,
          entityType: 'message',
          entityId: messageId,
          payload: Value(jsonEncode({'emoji': emoji})),
          createdAt: DateTime.now().toIso8601String(),
          priority: const Value('low'),
        ),
      );
    }
  }

  /// Remove a reaction with optimistic UI
  Future<void> removeReactionOptimistic({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    // 1. Get current message
    final entry = await db.getMessageById(messageId);
    if (entry == null) return;

    final message = entry.toModel();

    // 2. Remove reaction locally
    final reactions = List<Reaction>.from(message.reactions);
    reactions.removeWhere((r) => r.userId == userId && r.emoji == emoji);

    // 3. Save to database
    final reactionsJson = reactions.isEmpty
        ? null
        : jsonEncode(reactions.map((r) => r.toJson()).toList());
    await db.updateMessageReactions(messageId, reactionsJson ?? '[]');
    _log.d('Removed reaction locally: $emoji on $messageId');

    // 4. Try to sync to server
    try {
      await chatRepo.removeReaction(messageId, emoji);
      _log.d('Reaction removal synced to server');
    } catch (e) {
      _log.w('Failed to sync reaction removal, queuing for retry', error: e);

      await db.queuePendingAction(
        PendingActionsCompanion.insert(
          id: _uuid.v4(),
          actionType: PendingActionType.removeReaction.name,
          entityType: 'message',
          entityId: messageId,
          payload: Value(jsonEncode({'emoji': emoji})),
          createdAt: DateTime.now().toIso8601String(),
          priority: const Value('low'),
        ),
      );
    }
  }

  // ============================================
  // QUEUE PROCESSING
  // ============================================

  /// Process all pending operations
  Future<void> _processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final hasNetwork = await _hasNetwork();
      if (!hasNetwork) {
        _log.d('No network detected, skipping chat sync');
        return;
      }
      // 1. Process pending text messages
      await _processTextMessages();

      // 2. Process pending media messages
      await _processMediaMessages();

      // 3. Process pending actions (edits, deletes, reactions)
      await _processPendingActions();

      // Check if all succeeded
      final pendingMessages = await db.getPendingMessages();
      final pendingMedia = await db.getPendingMediaMessages();
      final pendingActions = await db.getPendingActionCount();

      if (pendingMessages.isEmpty &&
          pendingMedia.isEmpty &&
          pendingActions == 0) {
        _retryAttempt = 0;
      } else {
        _retryAttempt = (_retryAttempt + 1).clamp(0, maxRetries);
      }
    } catch (e) {
      _log.e('Error processing queue', error: e);
      _retryAttempt = (_retryAttempt + 1).clamp(0, maxRetries);
    } finally {
      _isSyncing = false;
      _scheduleSync();
    }
  }

  Future<bool> _hasNetwork() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Process pending text messages
  Future<void> _processTextMessages() async {
    final pendingMessages = await db.getPendingMessages();

    for (final entry in pendingMessages) {
      final message = entry.toModel();

      // Skip media messages (handled separately)
      if (message.messageType != MessageType.text) continue;

      try {
        await db.updateMessageStatus(
          message.id,
          MessageSendStatus.sending.name,
        );

        final serverMessage = await chatRepo.sendMessage(
          conversationId: message.conversationId,
          content: message.content,
          replyToMessageId: message.replyToMessageId,
        );

        await db.deleteMessage(message.id);
        await db.saveMessages([
          serverMessage
              .copyWith(sendStatus: MessageSendStatus.sent, localOnly: false)
              .toCompanion(),
        ]);

        _log.d('Text message synced: ${serverMessage.id}');
      } catch (e) {
        _log.w('Failed to sync text message: ${message.id}', error: e);
        await db.updateMessageStatus(message.id, MessageSendStatus.failed.name);
      }
    }
  }

  /// Process pending media messages
  Future<void> _processMediaMessages() async {
    final pendingMedia = await db.getPendingMediaMessages();

    for (final entry in pendingMedia) {
      final message = entry.toModel();

      // Check if local file still exists
      if (message.localMediaPath == null) {
        await db.updateMessageStatus(message.id, MessageSendStatus.failed.name);
        continue;
      }

      final file = File(message.localMediaPath!);
      if (!await file.exists()) {
        _log.w('Local media file not found: ${message.localMediaPath}');
        await db.updateMessageStatus(message.id, MessageSendStatus.failed.name);
        continue;
      }

      await _uploadMediaMessage(message);
    }
  }

  /// Process pending actions (edits, deletes, reactions)
  Future<void> _processPendingActions() async {
    final entries = await db.getPendingActions();

    for (final entry in entries) {
      try {
        await _processAction(entry);
        await db.removePendingAction(entry.id);
        _log.d('Processed pending action: ${entry.actionType}');
      } catch (e) {
        _log.w('Failed to process action: ${entry.id}', error: e);
        await db.markActionFailed(entry.id, e.toString());
      }
    }
  }

  /// Process a single pending action
  Future<void> _processAction(PendingActionEntry entry) async {
    final payload = entry.payload != null
        ? jsonDecode(entry.payload!) as Map<String, dynamic>
        : null;

    switch (entry.actionType) {
      case 'editMessage':
        final content = payload?['content'] as String?;
        if (content != null) {
          await chatRepo.editMessage(
            messageId: entry.entityId,
            newContent: content,
          );
        }
        break;

      case 'deleteMessage':
        await chatRepo.deleteMessageForSelf(entry.entityId);
        break;

      case 'deleteMessageForEveryone':
        await chatRepo.deleteMessageForEveryone(entry.entityId);
        break;

      case 'addReaction':
        final emoji = payload?['emoji'] as String?;
        if (emoji != null) {
          await chatRepo.addReaction(entry.entityId, emoji);
        }
        break;

      case 'removeReaction':
        final emoji = payload?['emoji'] as String?;
        if (emoji != null) {
          await chatRepo.removeReaction(entry.entityId, emoji);
        }
        break;

      case 'markAsRead':
        await chatRepo.markAsRead(entry.entityId);
        break;

      default:
        _log.w('Unknown action type: ${entry.actionType}');
    }
  }

  // ============================================
  // MANUAL OPERATIONS
  // ============================================

  /// Force immediate queue processing
  Future<void> syncNow() async {
    _syncTimer?.cancel();
    await _processQueue();
  }

  /// Retry a specific failed message
  Future<bool> retryMessage(String messageId) async {
    try {
      final entry = await db.getMessageById(messageId);
      if (entry == null) return false;

      final message = entry.toModel();
      if (message.sendStatus != MessageSendStatus.failed) return false;

      if (message.messageType == MessageType.text) {
        await db.updateMessageStatus(
          message.id,
          MessageSendStatus.sending.name,
        );

        final serverMessage = await chatRepo.sendMessage(
          conversationId: message.conversationId,
          content: message.content,
          replyToMessageId: message.replyToMessageId,
        );

        await db.deleteMessage(message.id);
        await db.saveMessages([
          serverMessage
              .copyWith(sendStatus: MessageSendStatus.sent, localOnly: false)
              .toCompanion(),
        ]);
      } else {
        await _uploadMediaMessage(message);
      }

      return true;
    } catch (e) {
      _log.e('Error retrying message', error: e);
      return false;
    }
  }

  /// Get count of all pending operations
  Future<int> getPendingCount() async {
    final textMessages = await db.getPendingMessages();
    final mediaMessages = await db.getPendingMediaMessages();
    final actions = await db.getPendingActionCount();

    return textMessages.length + mediaMessages.length + actions;
  }
}
