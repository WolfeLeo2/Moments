import 'dart:async';
import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/models/reaction.dart';
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
    final currentUserId = _client.auth.currentUser?.id;

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .asyncMap((data) async {
          final messages = (data as List)
              .map((json) => Message.fromJson(json as Map<String, dynamic>))
              .where((msg) {
                // Filter out hard-deleted messages
                if (msg.isDeleted && msg.deletedFor != 'everyone') return false;
                // Filter out messages deleted for this specific user
                if (msg.deletedFor == currentUserId) return false;
                return true;
              })
              .toList();

          if (messages.isEmpty) return messages;

          // Collections IDs for bulk fetching
          final messageIds = messages.map((m) => m.id).toList();
          final replyIds = messages
              .where(
                (m) => m.replyToMessageId != null && m.replyToMessage == null,
              )
              .map((m) => m.replyToMessageId!)
              .toSet() // Deduplicate
              .toList();

          // Fetch all replies and reactions in parallel batch requests
          final futures = <Future<dynamic>>[];

          // 1. Fetch replies
          if (replyIds.isNotEmpty) {
            futures.add(
              _client.from('messages').select().filter('id', 'in', replyIds),
            );
          } else {
            futures.add(Future.value([]));
          }

          // 2. Fetch reactions
          if (messageIds.isNotEmpty) {
            futures.add(
              _client
                  .from('message_reactions')
                  .select()
                  .filter('message_id', 'in', messageIds),
            );
          } else {
            futures.add(Future.value([]));
          }

          final results = await Future.wait(futures);
          final repliesList = results[0] as List;
          final reactionsList = results[1] as List;

          // Build Maps for O(1) Lookup
          final replyMap = {
            for (var item in repliesList)
              item['id'] as String: Message.fromJson(
                item as Map<String, dynamic>,
              ),
          };

          final reactionsMap = <String, List<Reaction>>{};
          for (var item in reactionsList) {
            final reaction = Reaction.fromJson(item as Map<String, dynamic>);
            if (!reactionsMap.containsKey(reaction.messageId)) {
              reactionsMap[reaction.messageId] = [];
            }
            reactionsMap[reaction.messageId]!.add(reaction);
          }

          // Enrich messages
          return messages.map((msg) {
            var enrichedMsg = msg;

            // Add reply
            if (msg.replyToMessageId != null &&
                replyMap.containsKey(msg.replyToMessageId)) {
              enrichedMsg = enrichedMsg.copyWith(
                replyToMessage: replyMap[msg.replyToMessageId],
              );
            }

            // Add reactions
            if (reactionsMap.containsKey(msg.id)) {
              enrichedMsg = enrichedMsg.copyWith(
                reactions: reactionsMap[msg.id],
              );
            }

            return enrichedMsg;
          }).toList();
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

  /// Send a text message (with optional reply)
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    String? replyToMessageId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final messageData = {
      'conversation_id': conversationId,
      'sender_id': userId,
      'content': content,
      'message_type': 'text',
    };

    if (replyToMessageId != null) {
      messageData['reply_to_message_id'] = replyToMessageId;
    }

    final response = await _client
        .from('messages')
        .insert(messageData)
        .select()
        .single();

    return Message.fromJson(response);
  }

  /// Edit a message (only own messages, within 15 minutes)
  Future<void> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Fetch the message to check ownership and time
    final message = await _client
        .from('messages')
        .select()
        .eq('id', messageId)
        .single();

    if (message['sender_id'] != userId) {
      throw Exception('You can only edit your own messages');
    }

    final createdAt = DateTime.parse(message['created_at'] as String);
    final timeSinceSent = DateTime.now().difference(createdAt);
    if (timeSinceSent.inMinutes > 15) {
      throw Exception('Messages can only be edited within 15 minutes');
    }

    await _client
        .from('messages')
        .update({
          'content': newContent,
          'is_edited': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', messageId);
  }

  /// Delete a message for self only
  Future<void> deleteMessageForSelf(String messageId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('messages')
        .update({
          'deleted_for': userId, // Store the user ID who deleted it
        })
        .eq('id', messageId);
  }

  /// Delete a message for everyone (only own messages)
  Future<void> deleteMessageForEveryone(String messageId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify ownership
    final message = await _client
        .from('messages')
        .select()
        .eq('id', messageId)
        .single();

    if (message['sender_id'] != userId) {
      throw Exception('You can only delete your own messages for everyone');
    }

    // Also delete all reactions for this message
    await _client
        .from('message_reactions')
        .delete()
        .eq('message_id', messageId);

    await _client
        .from('messages')
        .update({
          'is_deleted': true,
          'deleted_for': 'everyone',
          'content': '', // Clear content for privacy, but keep record
        })
        .eq('id', messageId);
  }

  /// Add a reaction to a message
  Future<void> addReaction(String messageId, String emoji) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Check if user already reacted with this emoji
    final existing = await _client
        .from('message_reactions')
        .select()
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .eq('emoji', emoji)
        .maybeSingle();

    if (existing != null) {
      // Already reacted with this emoji, remove it (toggle)
      await _client.from('message_reactions').delete().eq('id', existing['id']);
    } else {
      // Remove any existing reaction from this user on this message
      await _client
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId);

      // Add new reaction
      await _client.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
      });
    }

    // Touch the message to trigger a stream update
    await _client
        .from('messages')
        .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', messageId);
  }

  /// Remove a reaction from a message
  Future<void> removeReaction(String messageId, String emoji) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('message_reactions')
        .delete()
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .eq('emoji', emoji);

    // Touch the message to trigger a stream update
    await _client
        .from('messages')
        .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', messageId);
  }

  /// Get reactions for a message
  Future<List<Map<String, dynamic>>> getReactionsForMessage(
    String messageId,
  ) async {
    final response = await _client
        .from('message_reactions')
        .select('id, user_id, emoji, created_at')
        .eq('message_id', messageId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch a single message by ID with its reply data
  Future<Message?> getMessageById(String messageId) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('id', messageId)
          .maybeSingle();

      if (response == null) return null;
      return Message.fromJson(response);
    } catch (e) {
      return null;
    }
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
        // Check if friend is in this conversation
        final friendParticipation = await _client
            .from('conversation_participants')
            .select()
            .eq('conversation_id', conversationId)
            .eq('user_id', friendId)
            .maybeSingle();

        if (friendParticipation != null) {
          return conversationId;
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
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
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
