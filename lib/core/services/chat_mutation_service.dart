import 'dart:io';

import 'package:moments/core/providers/powersync_provider.dart';
import 'package:moments/core/services/app_logger.dart';
import 'package:moments/core/services/powersync/chat_powersync_service.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/models/reaction.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'chat_mutation_service.g.dart';

final _log = AppLogger('ChatMutationService');
const _uuid = Uuid();

/// Provider for chat mutation service.
@Riverpod(keepAlive: true)
ChatMutationService chatMutationService(Ref ref) {
  final chatPowerSync = ref.watch(chatPowerSyncServiceProvider);
  return ChatMutationService(chatPowerSync: chatPowerSync);
}

/// PowerSync-first chat mutation service.
///
/// Chat DB mutations are written locally and synced by PowerSync.
/// Media uploads are handled in the PowerSync connector uploadData path.
class ChatMutationService {
  final ChatPowerSyncService chatPowerSync;

  bool _started = false;

  bool get isStarted => _started;

  ChatMutationService({required this.chatPowerSync});

  // ============================================
  // LIFECYCLE
  // ============================================

  void start() {
    if (_started) return;
    _started = true;
    _log.d('Starting chat mutation service (PowerSync-managed sync)');
  }

  void stop() {
    _log.d('Stopping chat mutation service');
    _started = false;
  }

  // ============================================
  // OPTIMISTIC SEND
  // ============================================

  Future<void> sendTextOptimistic({
    required String conversationId,
    required String senderId,
    required String content,
    String? replyToMessageId,
    Message? replyToMessage,
    MessageType messageType = MessageType.text,
  }) async {
    _requireStarted();
    await _ensurePowerSyncReady();

    final localId = _uuid.v4();
    final now = DateTime.now();

    final message = Message(
      id: localId,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      messageType: messageType,
      createdAt: now,
      updatedAt: now,
      replyToMessageId: replyToMessageId,
      replyToMessage: replyToMessage,
      sendStatus: MessageSendStatus.pending,
      localOnly: true,
    );

    await chatPowerSync.upsertLocalMessage(message);
    _log.d('Queued optimistic ${messageType.name} message: $localId');
  }

  Future<void> sendImageOptimistic({
    required String conversationId,
    required String senderId,
    required String localPath,
    Map<String, dynamic>? metadata,
  }) async {
    _requireStarted();
    await _queueMediaOptimistic(
      conversationId: conversationId,
      senderId: senderId,
      localPath: localPath,
      messageType: MessageType.image,
      content: 'Image',
      metadata: metadata,
    );
  }

  Future<void> sendAudioOptimistic({
    required String conversationId,
    required String senderId,
    required String localPath,
    required int durationMs,
  }) async {
    _requireStarted();
    await _queueMediaOptimistic(
      conversationId: conversationId,
      senderId: senderId,
      localPath: localPath,
      messageType: MessageType.audio,
      content: 'Voice note',
      metadata: {'duration_ms': durationMs},
    );
  }

  Future<void> sendVideoOptimistic({
    required String conversationId,
    required String senderId,
    required String localPath,
  }) async {
    _requireStarted();
    await _queueMediaOptimistic(
      conversationId: conversationId,
      senderId: senderId,
      localPath: localPath,
      messageType: MessageType.video,
      content: 'Video',
    );
  }

  Future<void> _queueMediaOptimistic({
    required String conversationId,
    required String senderId,
    required String localPath,
    required MessageType messageType,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    _requireStarted();
    await _ensurePowerSyncReady();

    final localId = _uuid.v4();
    final now = DateTime.now();

    final message = Message(
      id: localId,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      messageType: messageType,
      localMediaPath: localPath,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
      sendStatus: MessageSendStatus.pending,
      localOnly: true,
    );

    await chatPowerSync.upsertLocalMessage(message);
    _log.d('Queued optimistic ${messageType.name} message: $localId');
  }

  // ============================================
  // OPTIMISTIC MUTATIONS
  // ============================================

  Future<void> editMessageOptimistic({
    required String messageId,
    required String newContent,
  }) async {
    _requireStarted();
    await _ensurePowerSyncReady();

    await chatPowerSync.updateMessageContent(messageId, newContent);
    _log.d('Queued optimistic edit for message: $messageId');
  }

  Future<void> deleteForSelfOptimistic({
    required String messageId,
    required String currentUserId,
  }) async {
    _requireStarted();
    await _ensurePowerSyncReady();

    await chatPowerSync.markMessageDeletedForSelf(messageId, currentUserId);
    _log.d('Queued delete-for-self for message: $messageId');
  }

  Future<void> deleteForEveryoneOptimistic({required String messageId}) async {
    _requireStarted();
    await _ensurePowerSyncReady();

    await chatPowerSync.markMessageDeletedForEveryone(messageId);
    _log.d('Queued delete-for-everyone for message: $messageId');
  }

  Future<void> addReactionOptimistic({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    _requireStarted();
    await _ensurePowerSyncReady();

    final reaction = Reaction(
      id: _uuid.v4(),
      messageId: messageId,
      userId: userId,
      emoji: emoji,
      createdAt: DateTime.now(),
    );

    // PowerSync-backed UI source of truth.
    await chatPowerSync.removeUserReactionsForMessage(
      messageId: messageId,
      userId: userId,
    );
    await chatPowerSync.upsertReaction(reaction);

    _log.d('Queued optimistic reaction add on $messageId');
  }

  Future<void> removeReactionOptimistic({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    _requireStarted();
    await _ensurePowerSyncReady();

    await chatPowerSync.removeReaction(
      messageId: messageId,
      userId: userId,
      emoji: emoji,
    );

    _log.d('Queued optimistic reaction removal on $messageId');
  }

  // ============================================
  // MANUAL OPERATIONS
  // ============================================

  /// Kept for API compatibility. PowerSync runs continuous upload/download sync.
  Future<void> syncNow() async {
    _requireStarted();
    await _ensurePowerSyncReady();
  }

  /// Retry a failed message by re-queuing a full local upsert into PowerSync.
  Future<bool> retryMessage(String messageId) async {
    _requireStarted();
    await _ensurePowerSyncReady();

    final message = await chatPowerSync.getMessageById(messageId);
    if (message == null) return false;

    if (message.sendStatus != MessageSendStatus.failed) return false;

    if (_isMediaMessage(message.messageType)) {
      final localPath = message.localMediaPath;
      if (localPath == null || localPath.isEmpty) return false;
      if (!await File(localPath).exists()) return false;
    }

    final retried = message.copyWith(
      sendStatus: MessageSendStatus.pending,
      localOnly: true,
      updatedAt: DateTime.now(),
    );

    await chatPowerSync.upsertLocalMessage(retried);
    _log.d('Re-queued failed message: $messageId');
    return true;
  }

  /// Number of queued PowerSync CRUD operations.
  Future<int> getPendingCount() async {
    _requireStarted();
    await _ensurePowerSyncReady();
    return chatPowerSync.getUploadQueueCount();
  }

  void _requireStarted() {
    if (_started) return;
    throw StateError(
      'ChatMutationService.start() must be called before operations.',
    );
  }

  Future<void> _ensurePowerSyncReady() async {
    final ok = await chatPowerSync.ensureInitialized();
    if (!ok) {
      throw Exception('PowerSync is not initialized for chat operations.');
    }
  }

  bool _isMediaMessage(MessageType type) {
    return type == MessageType.image ||
        type == MessageType.audio ||
        type == MessageType.video;
  }
}
