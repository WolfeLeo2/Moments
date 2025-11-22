import 'package:moments/data/models/message.dart';
import 'package:moments/data/sources/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for chat operations
class ChatRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get or create a 1-on-1 conversation with a friend
  Future<String> getOrCreateConversation(String friendId) async {
    try {
      print(
        '🔵 [CHAT REPO] getOrCreateConversation started for friend: $friendId',
      );
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ [CHAT REPO] User not authenticated');
        throw Exception('User not authenticated');
      }
      print('✅ [CHAT REPO] Current User ID: $userId');

      // Check if conversation already exists between these two users
      print('🔍 [CHAT REPO] Checking existing conversations...');
      final existingConversations = await _client
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', userId);

      print(
        '📊 [CHAT REPO] Found ${existingConversations.length} conversations for current user',
      );

      if (existingConversations.isNotEmpty) {
        // Check each conversation to see if it's with this friend
        for (final row in existingConversations) {
          final conversationId = row['conversation_id'] as String;

          // Get all participants in this conversation
          final participants = await _client
              .from('conversation_participants')
              .select('user_id')
              .eq('conversation_id', conversationId);

          // Check if it's a 1-on-1 with this friend
          if (participants.length == 2) {
            final userIds = participants
                .map((p) => p['user_id'] as String)
                .toList();
            if (userIds.contains(userId) && userIds.contains(friendId)) {
              print(
                '✅ [CHAT REPO] Found existing conversation: $conversationId',
              );
              return conversationId;
            }
          }
        }
      }

      print(
        '📝 [CHAT REPO] No existing conversation found. Creating new one...',
      );
      // Create new conversation
      final conversation = await _client
          .from('conversations')
          .insert({})
          .select()
          .single();

      final conversationId = conversation['id'] as String;
      print('✅ [CHAT REPO] Created conversation record: $conversationId');

      // Add both users as participants
      print('📝 [CHAT REPO] Adding participants...');

      // Try adding participants one by one to debug RLS better if batch fails
      try {
        print('📝 [CHAT REPO] Adding current user ($userId)...');
        await _client.from('conversation_participants').insert({
          'conversation_id': conversationId,
          'user_id': userId,
        });
        print('✅ [CHAT REPO] Added current user');

        print('📝 [CHAT REPO] Adding friend ($friendId)...');
        await _client.from('conversation_participants').insert({
          'conversation_id': conversationId,
          'user_id': friendId,
        });
        print('✅ [CHAT REPO] Added friend');
      } catch (e) {
        print('❌ [CHAT REPO] Failed to add participants: $e');
        // Clean up the conversation if we failed to add participants
        // await _client.from('conversations').delete().eq('id', conversationId);
        rethrow;
      }

      return conversationId;
    } catch (e, stack) {
      print('❌ [CHAT REPO] Error in getOrCreateConversation: $e');
      print('📚 [CHAT REPO] Stack trace: $stack');
      rethrow;
    }
  }

  /// Stream messages in a conversation (real-time)
  Stream<List<Message>> streamMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) {
          return (data as List)
              .map((json) => Message.fromJson(json as Map<String, dynamic>))
              .where((msg) => !msg.isDeleted)
              .toList();
        });
  }

  /// Send a text message
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'content': content,
          'message_type': 'text',
        })
        .select()
        .single();

    return Message.fromJson(response);
  }

  /// Get the last message in a conversation
  Future<Message?> getLastMessage(String conversationId) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return Message.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get conversation ID for a friend (if exists)
  Future<String?> getConversationWithFriend(String friendId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final myConversations = await _client
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', userId);

      for (final row in myConversations) {
        final conversationId = row['conversation_id'] as String;

        final participants = await _client
            .from('conversation_participants')
            .select('user_id')
            .eq('conversation_id', conversationId);

        if (participants.length == 2) {
          final userIds = participants
              .map((p) => p['user_id'] as String)
              .toList();
          if (userIds.contains(userId) && userIds.contains(friendId)) {
            return conversationId;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('conversation_participants')
        .update({'last_read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);
  }
}
