import 'dart:async';
import 'dart:io';
import 'package:flutter/painting.dart';
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

  /// Get all conversations with their last message for the current user
  Future<List<Map<String, dynamic>>> getRecentConversations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // 1. Get all conversation IDs for the user
    final participants = await _client
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', userId);

    if (participants.isEmpty) return [];

    final conversationIds = participants
        .map((p) => p['conversation_id'] as String)
        .toList();

    // 2. Fetch last message for each conversation
    // We use Future.wait to fetch them in parallel
    final futures = conversationIds.map((conversationId) async {
      try {
        final response = await _client
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          // Fetch other participant
          final otherParticipantResponse = await _client
              .from('conversation_participants')
              .select('user_id')
              .eq('conversation_id', conversationId)
              .neq('user_id', userId)
              .maybeSingle();

          // Fetch unread count
          final unreadCount = await _client
              .from('messages')
              .count(CountOption.exact)
              .eq('conversation_id', conversationId)
              .neq('sender_id', userId)
              .eq('is_read', false);

          if (otherParticipantResponse != null) {
            return {
              'conversationId': conversationId,
              'lastMessage': Message.fromJson(response),
              'otherUserId': otherParticipantResponse['user_id'] as String,
              'unreadCount': unreadCount,
            };
          }
        }
      } catch (e) {
        print('Error fetching last message for $conversationId: $e');
      }
      return null;
    });

    final results = await Future.wait(futures);
    final conversations = results.whereType<Map<String, dynamic>>().toList();

    // Sort by last message time (newest first)
    conversations.sort((a, b) {
      final msgA = a['lastMessage'] as Message;
      final msgB = b['lastMessage'] as Message;
      return msgB.createdAt.compareTo(msgA.createdAt);
    });

    return conversations;
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

    // Update last_read_at for the participant
    await _client
        .from('conversation_participants')
        .update({'last_read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('user_id', userId);

    // Mark all messages from the OTHER user as read
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId)
        .eq('is_read', false);
  }

  /// Upload a file to Supabase Storage
  Future<String> uploadFile(File file, String path) async {
    try {
      await _client.storage.from('chat_attachments').upload(path, file);
      final publicUrl = _client.storage
          .from('chat_attachments')
          .getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('❌ [CHAT REPO] Error uploading file: $e');
      rethrow;
    }
  }

  /// Send an audio message
  Future<Message> sendAudioMessage({
    required String conversationId,
    required String audioPath,
    required int durationMs,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Upload audio file to storage
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '$conversationId/$fileName';

      await _client.storage
          .from('chat_attachments')
          .upload(
            filePath,
            File(audioPath),
            fileOptions: const FileOptions(contentType: 'audio/mp4'),
          );

      final mediaUrl = _client.storage
          .from('chat_attachments')
          .getPublicUrl(filePath);

      // Create message in database
      final response = await _client
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': currentUserId,
            'content': 'Voice message ($durationMs ms)',
            'message_type': 'audio',
            'media_url': mediaUrl,
            'metadata': {'duration_ms': durationMs},
          })
          .select()
          .single();

      return Message.fromJson(response);
    } catch (e) {
      print('❌ [CHAT REPO] Error sending audio message: $e');
      rethrow;
    }
  }

  /// Send an image message
  Future<Message> sendImageMessage({
    required String conversationId,
    required String imagePath,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Calculate image dimensions
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final image = await decodeImageFromList(bytes);
    final metadata = {'width': image.width, 'height': image.height};

    // 2. Upload image file
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = '$conversationId/$fileName';

    final mediaUrl = await uploadFile(file, storagePath);

    // 3. Create message record
    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'content': 'Image', // Fallback text
          'message_type': 'image',
          'media_url': mediaUrl,
          'metadata': metadata,
        })
        .select()
        .single();

    return Message.fromJson(response);
  }

  /// Send a video message
  Future<Message> sendVideoMessage({
    required String conversationId,
    required String videoPath,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // 1. Upload video file
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final storagePath = '$conversationId/$fileName';
    final file = File(videoPath);

    final mediaUrl = await uploadFile(file, storagePath);

    // 2. Create message record
    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'content': 'Video', // Fallback text
          'message_type': 'video',
          'media_url': mediaUrl,
        })
        .select()
        .single();

    return Message.fromJson(response);
  }

  /// Send typing indicator
  Future<void> sendTyping(String conversationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final channel = _client.channel('chat:$conversationId');

    try {
      await channel.sendBroadcastMessage(
        event: 'typing',
        payload: {'user_id': userId},
      );
    } catch (e) {
      // Silently ignore typing indicator errors
    }
  }

  /// Subscribe to typing indicators
  Stream<String> subscribeToTyping(String conversationId) {
    final controller = StreamController<String>.broadcast();
    final userId = _client.auth.currentUser?.id;

    final channel = _client.channel('chat:$conversationId');

    channel
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            // The payload structure is: {event: typing, payload: {user_id: ...}, type: broadcast}
            // Extract from the nested 'payload' object
            final nestedPayload = payload['payload'] as Map<String, dynamic>?;
            final typingUserId = nestedPayload?['user_id'] as String?;

            if (typingUserId != null && typingUserId != userId) {
              controller.add(typingUserId);
            }
          },
        )
        .subscribe();

    return controller.stream;
  }

  /// Stream unread message count
  Stream<int> streamUnreadCount() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(0);

    final controller = StreamController<int>();

    Future<void> fetch() async {
      try {
        final count = await _client.rpc('get_unread_chat_count');
        if (!controller.isClosed) controller.add(count as int);
      } catch (e) {
        print('Error fetching unread chat count: $e');
      }
    }

    // Initial fetch
    fetch();

    // Listen for changes in messages table
    // Note: We listen to all message changes because we can't easily filter
    // by "messages for me" without a join in the filter.
    // This might be noisy but ensures accuracy.
    final channel = _client.channel('public:messages_count');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) => fetch(),
        )
        .subscribe();

    controller.onCancel = () async {
      await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }

  /// Stream that emits when conversations list might have changed
  Stream<void> streamConversationsChanged() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(null);

    final controller = StreamController<void>();

    // Listen for new messages (which might create new conversations or update last message)
    final channel = _client.channel('public:conversations_list');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            if (!controller.isClosed) controller.add(null);
          },
        )
        .subscribe();

    controller.onCancel = () async {
      await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }
}
