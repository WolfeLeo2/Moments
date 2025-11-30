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
@riverpod
Future<Message?> lastMessage(Ref ref, String conversationId) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.getLastMessage(conversationId);
}

/// Get conversation ID with a friend
@riverpod
Future<String?> conversationWithFriend(Ref ref, String friendId) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.getConversationWithFriend(friendId);
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
/// Uses local storage cache to prevent unnecessary network calls
@riverpod
Future<String> conversationId(Ref ref, String friendId) async {
  final storage = ref.watch(messageStorageProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);

  // 1. Try local storage first (Instant load)
  final cachedId = await storage.getConversationId(friendId);
  if (cachedId != null) return cachedId;

  // 2. Network fallback (First time only)
  final id = await chatRepo.getOrCreateConversation(friendId);

  // 3. Save for next time
  await storage.saveConversationId(friendId, id);

  return id;
}
