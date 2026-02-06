import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/models/pending_action.dart';
import 'package:moments/data/repositories/chat_repository.dart';
import 'package:moments/core/database/database.dart';
import 'package:moments/core/providers/database_provider.dart';
import 'package:moments/core/services/app_logger.dart';
import 'package:moments/core/providers/sync_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

part 'chat_providers.g.dart';

final _log = AppLogger('ChatProviders');
const _uuid = Uuid();

/// Tracks the currently active chat conversation ID
/// Used to suppress notifications when the user is already viewing the chat
@Riverpod(keepAlive: true)
class CurrentChatId extends _$CurrentChatId {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

/// Chat repository provider - singleton
@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) {
  return ChatRepository();
}

/// Stream messages for a specific conversation with Drift reactive storage
@riverpod
Stream<List<Message>> messagesStream(Ref ref, String conversationId) async* {
  final db = ref.watch(appDatabaseProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);

  // 1. Yield cached data from Drift immediately for instant UI
  final storedEntries = await db.getMessages(conversationId);
  if (storedEntries.isNotEmpty) {
    yield storedEntries.map((e) => e.toModel()).toList();
  }

  // 2. Start listening to Drift's reactive stream (updates automatically when DB changes)
  final driftStream = db
      .watchMessages(conversationId)
      .map((entries) => entries.map((e) => e.toModel()).toList());

  // 3. Also subscribe to Supabase realtime and save to Drift with smart merge
  // Smart merge preserves local sendStatus for pending/sending messages
  chatRepo
      .streamMessages(conversationId)
      .listen(
        (messages) {
          db.saveMessagesWithMerge(
            messages.map((m) => m.toCompanion()).toList(),
          );
        },
        onError: (e) {
          _log.w(
            'Realtime stream error for conversation $conversationId',
            error: e,
          );
          // Stream errors don't break Drift - local data still works
        },
      );

  // 4. Yield from Drift reactive stream (auto-updates when messages saved)
  await for (final messages in driftStream) {
    yield messages;
  }
}

/// Get last message for a conversation
/// First checks Drift for instant display, then validates with Supabase
@Riverpod(keepAlive: true)
Future<Message?> lastMessage(Ref ref, String conversationId) async {
  final db = ref.watch(appDatabaseProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);

  // 1. First try to get from Drift (instant, offline-capable)
  final localEntry = await db.getLastMessage(conversationId);
  final localMessage = localEntry?.toModel();

  // 2. Also fetch from Supabase in background to ensure we have latest
  try {
    final networkMessage = await chatRepo.getLastMessage(conversationId);

    // If network has a newer message, save it and return it
    if (networkMessage != null) {
      // Save to Drift
      await db.saveMessages([networkMessage.toCompanion()]);

      // Return whichever is newer
      if (localMessage == null ||
          networkMessage.createdAt.isAfter(localMessage.createdAt)) {
        return networkMessage;
      }
    }
  } catch (e) {
    // Network error - that's fine, use local data
    _log.d('Network fetch failed for lastMessage, using local: $e');
  }

  // Return local message (may be null if no messages exist)
  return localMessage;
}

/// Get or create a conversation ID with a friend
/// Always returns a valid conversation ID (creates one if needed)
/// Use this when you need to ensure a conversation exists
@Riverpod(keepAlive: true)
Future<String> conversationId(Ref ref, String friendId) async {
  final db = ref.watch(appDatabaseProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);

  // 1. Try to get cached conversation ID from Drift
  final cachedId = await db.getCachedConversationId(friendId);
  if (cachedId != null) {
    return cachedId;
  }

  // 2. Get or create from Supabase
  final conversationId = await chatRepo.getOrCreateConversation(friendId);

  // 3. Cache it in Drift for next time
  await db.cacheConversationId(friendId, conversationId);

  return conversationId;
}

/// Get all recent messages for all conversations
/// This is optimized to fetch all at once instead of N+1 requests
@riverpod
Future<Map<String, Message>> recentMessages(Ref ref) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  final conversations = await chatRepo.getRecentConversations();
  return {
    for (final c in conversations)
      if (c['lastMessage'] != null)
        c['conversationId'] as String: c['lastMessage'] as Message,
  };
}

/// Show send button state for each conversation
@riverpod
class ShowSendButton extends _$ShowSendButton {
  @override
  bool build(String conversationId) => false;

  void toggle() => state = !state;
  void show() => state = true;
  void hide() => state = false;
}

/// Typing users state for each conversation
/// Maps user ID to timestamp of last typing event
@riverpod
class TypingUsers extends _$TypingUsers {
  @override
  Map<String, DateTime> build(String conversationId) => {};

  void addTypingUser(String userId) {
    state = {...state, userId: DateTime.now()};
  }

  void removeTypingUser(String userId) {
    final updated = Map<String, DateTime>.from(state);
    updated.remove(userId);
    state = updated;
  }

  void clearOldTypingIndicators(Duration timeout) {
    final now = DateTime.now();
    final updated = Map<String, DateTime>.from(state);
    updated.removeWhere(
      (userId, timestamp) => now.difference(timestamp) > timeout,
    );
    if (updated.length != state.length) {
      state = updated;
    }
  }
}

/// Recording state for each conversation
@riverpod
class IsRecording extends _$IsRecording {
  @override
  bool build(String conversationId) => false;

  void start() => state = true;
  void stop() => state = false;
}

/// Get list of recent conversations with details (Realtime)
/// Yields cached data immediately for instant UI, then updates with fresh data
@riverpod
Stream<List<Map<String, dynamic>>> chatList(Ref ref) async* {
  final chatRepo = ref.watch(chatRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);

  // 1. Yield cached data immediately from Drift
  final cachedEntries = await db.loadChatList();
  if (cachedEntries.isNotEmpty) {
    final cachedData = cachedEntries
        .map((entry) {
          Message? lastMessage;
          if (entry.lastMessageJson != null) {
            try {
              lastMessage = Message.fromJson(
                jsonDecode(entry.lastMessageJson!),
              );
            } catch (_) {}
          }
          return {
            'conversationId': entry.conversationId,
            'otherUserId': entry.otherUserId,
            'unreadCount': entry.unreadCount,
            'lastMessage': lastMessage,
          };
        })
        .where((m) => m['lastMessage'] != null)
        .toList();
    if (cachedData.isNotEmpty) {
      yield cachedData;
    }
  }

  // 2. Fetch fresh data and update Drift cache
  try {
    final freshData = await chatRepo.getRecentConversations();
    if (freshData.isNotEmpty) {
      final entries = freshData.map((conv) {
        final message = conv['lastMessage'] as Message;
        return ChatListCacheCompanion.insert(
          conversationId: conv['conversationId'] as String,
          otherUserId: conv['otherUserId'] as String,
          unreadCount: Value(conv['unreadCount'] as int? ?? 0),
          lastMessageJson: Value(jsonEncode(message.toJson())),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }).toList();
      await db.saveChatList(entries);
    }
    yield freshData;
  } catch (e) {
    // Log sync error
    ref
        .read(syncStateProvider.notifier)
        .addError('chat', 'Failed to load chat list', details: e.toString());
    if (cachedEntries.isEmpty) {
      rethrow;
    }
    _log.w('Network failed for chatList, using cached data', error: e);
  }

  // 3. Listen for realtime updates and save to Drift
  await for (final _ in chatRepo.streamConversationsChanged()) {
    try {
      final updatedData = await chatRepo.getRecentConversations();
      if (updatedData.isNotEmpty) {
        final entries = updatedData.map((conv) {
          final message = conv['lastMessage'] as Message;
          return ChatListCacheCompanion.insert(
            conversationId: conv['conversationId'] as String,
            otherUserId: conv['otherUserId'] as String,
            unreadCount: Value(conv['unreadCount'] as int? ?? 0),
            lastMessageJson: Value(jsonEncode(message.toJson())),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }).toList();
        await db.saveChatList(entries);
      }
      yield updatedData;
    } catch (e) {
      ref
          .read(syncStateProvider.notifier)
          .addError(
            'chat',
            'Failed to refresh chat list',
            details: e.toString(),
          );
      _log.w('Error in chatList stream update', error: e);
    }
  }
}

/// Offline-first mark conversation as read
/// Updates local database immediately, then syncs to server in background
@riverpod
class MarkAsReadAction extends _$MarkAsReadAction {
  @override
  FutureOr<void> build() {}

  /// Mark all messages in conversation as read
  /// Returns immediately after local update - server sync is fire-and-forget
  Future<void> markAsRead(String conversationId) async {
    final db = ref.read(appDatabaseProvider);
    final chatRepo = ref.read(chatRepositoryProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (currentUserId == null) return;

    // 1. Update local database immediately (instant UI feedback)
    final updated = await db.markConversationAsReadLocally(
      conversationId,
      currentUserId,
    );
    _log.d('Marked $updated messages as read locally');

    // 2. Update unread count in chat list cache
    await db.updateChatListUnreadCount(conversationId, 0);

    // 3. Sync to server in background (fire-and-forget)
    // Queue as pending action in case of failure
    try {
      await chatRepo.markAsRead(conversationId);
      _log.d('Synced read status to server');
    } catch (e) {
      _log.w('Failed to sync read status, queuing for retry', error: e);
      // Queue for later retry
      await db.queuePendingAction(
        PendingActionsCompanion.insert(
          id: _uuid.v4(),
          actionType: PendingActionType.markAsRead.name,
          entityType: 'conversation',
          entityId: conversationId,
          payload: const Value(null),
          createdAt: DateTime.now().toIso8601String(),
          priority: const Value('low'),
        ),
      );
    }
  }
}
