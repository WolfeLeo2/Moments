import 'package:moments/core/services/app_logger.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:moments/core/services/chat_encryption_service.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/data/models/reaction.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _log = AppLogger('ChatRepository');

/// Repository for chat operations
class ChatRepository {
  final SupabaseClient _client;
  final ChatEncryptionService _encryption = ChatEncryptionService.instance;

  ChatRepository(this._client);

  /// Get or create a 1-on-1 conversation with a friend
  /// Uses optimized RPC that does everything in a single DB call
  Future<String> getOrCreateConversation(String friendId) async {
    try {
      final result = await _client.rpc(
        'get_or_create_conversation',
        params: {'p_friend_id': friendId},
      );
      return result as String;
    } catch (e) {
      _log.e('Error in getOrCreateConversation', error: e);
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
        .order('created_at', ascending: false)
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
              .map((msg) {
                // Decrypt message content
                if (msg.messageType == MessageType.text) {
                  return msg.copyWith(
                    content: _encryption.decrypt(
                      msg.content,
                      msg.conversationId,
                    ),
                  );
                }
                return msg;
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
  /// Uses optimized RPC - single query instead of 3N queries
  Future<List<Map<String, dynamic>>> getRecentConversations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final result = await _client.rpc('get_recent_conversations');

      if (result == null) return [];

      // Transform RPC result to expected format
      return (result as List).map((row) {
        final createdAt = DateTime.parse(
          row['last_message_created_at'] as String,
        );
        final conversationId = row['conversation_id'] as String;
        final rawContent = row['last_message_content'] as String;
        final msgType = row['last_message_type'] as String? ?? 'text';
        final content = msgType == 'text'
            ? _encryption.decrypt(rawContent, conversationId)
            : rawContent;

        return {
          'conversationId': conversationId,
          'otherUserId': row['other_user_id'] as String,
          'lastMessage': Message(
            id: row['last_message_id'] as String,
            conversationId: conversationId,
            senderId: row['last_message_sender_id'] as String,
            content: content,
            messageType: MessageType.fromString(msgType),
            createdAt: createdAt,
            updatedAt: createdAt, // Use createdAt as fallback
            isRead: row['last_message_is_read'] as bool? ?? false,
          ),
          'unreadCount': row['unread_count'] as int? ?? 0,
        };
      }).toList();
    } catch (e) {
      _log.e('Error fetching recent conversations', error: e);
      rethrow;
    }
  }

  /// Send a message (with optional reply and message type)
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    String? replyToMessageId,
    String messageType = 'text',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Only encrypt text messages; GIF/sticker URLs should not be encrypted
    final messageContent = messageType == 'text'
        ? _encryption.encrypt(content, conversationId)
        : content;

    final messageData = {
      'conversation_id': conversationId,
      'sender_id': userId,
      'content': messageContent,
      'message_type': messageType,
    };

    if (replyToMessageId != null) {
      messageData['reply_to_message_id'] = replyToMessageId;
    }

    final response = await _client
        .from('messages')
        .insert(messageData)
        .select()
        .single();

    return Message.fromJson(response).copyWith(content: content);
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

    final conversationId = message['conversation_id'] as String;
    final encryptedContent = _encryption.encrypt(newContent, conversationId);

    await _client
        .from('messages')
        .update({
          'content': encryptedContent,
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
      final msg = Message.fromJson(response);
      if (msg.messageType == MessageType.text) {
        return msg.copyWith(
          content: _encryption.decrypt(msg.content, msg.conversationId),
        );
      }
      return msg;
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
      final msg = Message.fromJson(response);
      if (msg.messageType == MessageType.text) {
        return msg.copyWith(
          content: _encryption.decrypt(msg.content, msg.conversationId),
        );
      }
      return msg;
    } catch (e) {
      return null;
    }
  }

  /// Get conversation ID for a friend (if exists)
  /// Uses optimized RPC - single query instead of N+1
  Future<String?> getConversationWithFriend(String friendId) async {
    try {
      final result = await _client.rpc(
        'get_conversation_with_friend',
        params: {'p_friend_id': friendId},
      );
      return result as String?;
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

  /// Mark messages as delivered when fetching them
  /// Returns number of messages marked as delivered
  Future<int> markMessagesDelivered(String conversationId) async {
    try {
      final result = await _client.rpc(
        'mark_messages_delivered',
        params: {'p_conversation_id': conversationId},
      );
      return result as int? ?? 0;
    } catch (e) {
      _log.e('Failed to mark messages as delivered: $e');
      return 0;
    }
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
      _log.e('Error uploading file: $e');
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
      _log.e('Error sending audio message: $e');
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
        _log.e('Error fetching unread chat count: $e');
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
