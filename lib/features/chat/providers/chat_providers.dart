import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/repositories/chat_repository.dart';

/// Chat repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

/// Stream messages for a specific conversation
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((
  ref,
  conversationId,
) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.streamMessages(conversationId);
});

/// Get last message for a conversation
final lastMessageProvider = FutureProvider.family<Message?, String>((
  ref,
  conversationId,
) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.getLastMessage(conversationId);
});

/// Get conversation ID with a friend
final conversationWithFriendProvider = FutureProvider.family<String?, String>((
  ref,
  friendId,
) async {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.getConversationWithFriend(friendId);
});
