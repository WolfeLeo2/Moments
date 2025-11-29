import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/repositories/chat_repository.dart';

part 'chat_providers.g.dart';

/// Chat repository provider
@riverpod
ChatRepository chatRepository(Ref ref) {
  return ChatRepository();
}

/// Conversation cache to prevent reloading when navigating back to chat
@riverpod
class ConversationCache extends _$ConversationCache {
  @override
  Map<String, String> build() => {};

  String? getCachedConversationId(String friendId) {
    return state[friendId];
  }

  void cacheConversationId(String friendId, String conversationId) {
    state = {...state, friendId: conversationId};
  }

  void clearCache() {
    state = {};
  }
}

/// Stream messages for a specific conversation
@riverpod
Stream<List<Message>> messagesStream(Ref ref, String conversationId) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.streamMessages(conversationId);
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
/// Handles caching and fetching conversation ID
@riverpod
Future<String> conversationId(Ref ref, String friendId) async {
  // Check cache first
  final cachedId = ref
      .read(conversationCacheProvider.notifier)
      .getCachedConversationId(friendId);
  if (cachedId != null) {
    return cachedId;
  }

  // Fetch from repository
  final chatRepo = ref.watch(chatRepositoryProvider);
  final conversationId = await chatRepo.getOrCreateConversation(friendId);

  // Update cache
  ref
      .read(conversationCacheProvider.notifier)
      .cacheConversationId(friendId, conversationId);

  return conversationId;
}
