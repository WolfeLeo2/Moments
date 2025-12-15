import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/repositories/chat_repository.dart';
import 'package:moments/core/services/message_storage_service.dart';

part 'chat_providers.g.dart';

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
