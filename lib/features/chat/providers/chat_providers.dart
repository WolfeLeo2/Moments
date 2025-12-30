import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/repositories/chat_repository.dart';
import 'package:moments/core/services/message_storage_service.dart';
import 'package:moments/core/services/chat_list_cache_service.dart';

part 'chat_providers.g.dart';

/// Tracks the currently active chat conversation ID
/// Used to suppress notifications when the user is already viewing the chat
@riverpod
class CurrentChatId extends _$CurrentChatId {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

/// Message storage service provider
@riverpod
MessageStorageService messageStorage(Ref ref) {
  return MessageStorageService();
}

/// Chat repository provider (original, simple version)
@riverpod
ChatRepository chatRepository(Ref ref) {
  return ChatRepository();
}

/// Stream messages for a specific conversation with persistent storage
@riverpod
Stream<List<Message>> messagesStream(Ref ref, String conversationId) async* {
  final storage = ref.watch(messageStorageProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);

  // 1. Load stored messages immediately for instant UI
  final storedMessages = await storage.getMessages(conversationId);
  if (storedMessages.isNotEmpty) {
    yield storedMessages;
  }

  // 2. Subscribe to Supabase realtime stream and update storage
  await for (final messages in chatRepo.streamMessages(conversationId)) {
    // Save to persistent storage
    storage.saveMessages(conversationId, messages);
    yield messages;
  }
}

/// Get last message for a conversation
/// First checks SQLite for instant display, then validates with Supabase
/// Uses keepAlive to prevent rebuilds when navigating away
@Riverpod(keepAlive: true)
Future<Message?> lastMessage(Ref ref, String conversationId) async {
  final storage = ref.watch(messageStorageProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);

  // 1. First try to get from local SQLite storage (instant, offline-capable)
  final localMessage = await storage.getLastMessage(conversationId);

  // 2. Also fetch from Supabase in background to ensure we have latest
  // This will update the cache for next time
  try {
    final networkMessage = await chatRepo.getLastMessage(conversationId);

    // If network has a newer message, save it and return it
    if (networkMessage != null) {
      // Save to local storage
      await storage.saveMessages(conversationId, [networkMessage]);

      // Return whichever is newer
      if (localMessage == null ||
          networkMessage.createdAt.isAfter(localMessage.createdAt)) {
        return networkMessage;
      }
    }
  } catch (e) {
    // Network error - that's fine, use local data
    debugPrint('lastMessage: Network fetch failed, using local: $e');
  }

  // Return local message (may be null if no messages exist)
  return localMessage;
}

/// Get conversation ID with a friend
/// Uses SQLite cache for instant display, validates with network in background
/// Uses keepAlive to prevent rebuilds when navigating away
@Riverpod(keepAlive: true)
Future<String?> conversationWithFriend(Ref ref, String friendId) async {
  final storage = ref.watch(messageStorageProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);

  // 1. First try to get cached conversation ID (instant, offline-capable)
  final cachedConversationId = await storage.getCachedConversationId(friendId);
  if (cachedConversationId != null) {
    return cachedConversationId;
  }

  // 2. If not cached, fetch from Supabase
  try {
    final conversationId = await chatRepo.getConversationWithFriend(friendId);

    // Cache it for next time
    if (conversationId != null) {
      await storage.cacheConversationId(friendId, conversationId);
    }

    return conversationId;
  } catch (e) {
    debugPrint('conversationWithFriend: Network fetch failed: $e');
    return null;
  }
}

/// Get all recent messages for all conversations
/// This is optimized to fetch all at once instead of N+1 requests
@riverpod
Future<Map<String, Message>> recentMessages(Ref ref) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  // This method must be added to ChatRepository
  final conversations = await chatRepo.getRecentConversations();
  return {
    for (final c in conversations)
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

/// Async conversation ID provider
/// Gets or creates a conversation with a friend
/// Cached locally to persist across app restarts
@Riverpod(keepAlive: true)
Future<String> conversationId(Ref ref, String friendId) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  final storage = ref.watch(messageStorageProvider);

  // 1. Try to get cached conversation ID first
  final cachedId = await storage.getCachedConversationId(friendId);
  if (cachedId != null) {
    return cachedId;
  }

  // 2. Fetch from Supabase if not cached
  final conversationId = await chatRepo.getOrCreateConversation(friendId);

  // 3. Cache it for next time
  await storage.cacheConversationId(friendId, conversationId);

  return conversationId;
}

/// Get list of recent conversations with details (Realtime)
/// Yields cached data immediately for instant UI, then updates with fresh data
@riverpod
Stream<List<Map<String, dynamic>>> chatList(Ref ref) async* {
  final chatRepo = ref.watch(chatRepositoryProvider);
  final cacheService = ChatListCacheService();

  // 1. Yield cached data immediately for instant UI
  final cachedData = await cacheService.loadChatList();
  if (cachedData != null && cachedData.isNotEmpty) {
    yield cachedData;
  }

  // 2. Fetch fresh data and update cache
  try {
    final freshData = await chatRepo.getRecentConversations();
    if (freshData.isNotEmpty) {
      await cacheService.saveChatList(freshData);
    }
    yield freshData;
  } catch (e) {
    // If network fails and we have cached data, we already yielded it
    // If no cached data, rethrow to show error
    if (cachedData == null || cachedData.isEmpty) {
      rethrow;
    }
    debugPrint('chatList: Network failed, using cached data: $e');
  }

  // 3. Listen for realtime updates and save to cache
  await for (final _ in chatRepo.streamConversationsChanged()) {
    try {
      final updatedData = await chatRepo.getRecentConversations();
      if (updatedData.isNotEmpty) {
        await cacheService.saveChatList(updatedData);
      }
      yield updatedData;
    } catch (e) {
      debugPrint('chatList: Error in stream update: $e');
    }
  }
}
