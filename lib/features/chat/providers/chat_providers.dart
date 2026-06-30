import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/repositories/chat_repository.dart';
import 'package:moments/core/providers/powersync_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moments/core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'chat_providers.g.dart';

final _log = AppLogger('ChatProviders');

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

/// Stream messages for a specific conversation from PowerSync local SQLite
@riverpod
Stream<List<Message>> messagesStream(Ref ref, String conversationId) async* {
  final chatPowerSync = ref.watch(chatPowerSyncServiceProvider);
  final initialized = await chatPowerSync.ensureInitialized();
  if (!initialized) {
    throw Exception('PowerSync failed to initialize for chat messages.');
  }

  yield* chatPowerSync.watchMessages(conversationId);
}

/// Get last message for a conversation from PowerSync local SQLite
@Riverpod(keepAlive: true)
Future<Message?> lastMessage(Ref ref, String conversationId) async {
  final chatPowerSync = ref.watch(chatPowerSyncServiceProvider);
  final initialized = await chatPowerSync.ensureInitialized();
  if (!initialized) {
    throw Exception('PowerSync failed to initialize for last message.');
  }

  return chatPowerSync.getLastMessage(conversationId);
}

/// Get or create a conversation ID with a friend
/// Always returns a valid conversation ID (creates one if needed)
/// Use this when you need to ensure a conversation exists
@Riverpod(keepAlive: true)
Future<String> conversationId(Ref ref, String friendId) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'conv_id_$friendId';

  // 1. Fast path: cached conversation ID from prefs.
  final cachedId = prefs.getString(key);
  if (cachedId != null) return cachedId;

  // 2. Get or create from Supabase (idempotent RPC).
  final chatRepo = ref.watch(chatRepositoryProvider);
  final conversationId = await chatRepo.getOrCreateConversation(friendId);

  // 3. Cache for next time.
  await prefs.setString(key, conversationId);
  return conversationId;
}

/// Get all recent messages for all conversations from PowerSync local SQLite
@riverpod
Future<Map<String, Message>> recentMessages(Ref ref) async {
  final chatPowerSync = ref.watch(chatPowerSyncServiceProvider);
  final initialized = await chatPowerSync.ensureInitialized();
  if (!initialized) {
    throw Exception('PowerSync failed to initialize for recent messages.');
  }

  return chatPowerSync.getRecentMessagesMap();
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

/// Get list of recent conversations with details from PowerSync local SQLite
@riverpod
Stream<List<Map<String, dynamic>>> chatList(Ref ref) async* {
  final chatPowerSync = ref.watch(chatPowerSyncServiceProvider);
  final initialized = await chatPowerSync.ensureInitialized();
  if (!initialized) {
    throw Exception('PowerSync failed to initialize for chat list.');
  }

  yield* chatPowerSync.watchChatList();
}

/// Offline-first mark conversation as read
/// Updates local database immediately and relies on PowerSync upload queue
@riverpod
class MarkAsReadAction extends _$MarkAsReadAction {
  @override
  FutureOr<void> build() {}

  /// Mark all messages in conversation as read
  /// Returns immediately after local update.
  Future<void> markAsRead(String conversationId) async {
    final chatPowerSync = ref.read(chatPowerSyncServiceProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (currentUserId == null) return;

    // 1. Update local database immediately (instant UI feedback)
    await chatPowerSync.markConversationAsReadLocally(
      conversationId,
      currentUserId,
    );
    await chatPowerSync.updateConversationParticipantLastReadAt(
      conversationId,
      currentUserId,
    );

    _log.d('Marked conversation as read locally (PowerSync queued)');
  }
}
