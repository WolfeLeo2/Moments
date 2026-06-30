import 'package:moments/core/services/app_logger.dart';
import 'dart:async';
import 'package:moments/data/sources/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _log = AppLogger('ChatRepository');

/// Repository for chat operations that are NOT owned by PowerSync.
///
/// All message reads/writes (send/edit/delete/react/mark-read) go through
/// [ChatMutationService] + PowerSync local SQLite. This repository is reduced
/// to the things PowerSync can't do:
///  - `get_or_create_conversation` RPC (server-side conversation creation)
///  - ephemeral realtime typing indicators (never synced/persisted)
///  - the unread-count realtime stream (RPC + postgres-changes)
///
/// ponytail: direct-Supabase message CRUD removed (C3/C4) — it was dead code
/// duplicating the PowerSync path and racing it on the same rows.
class ChatRepository {
  final SupabaseClient _client = SupabaseConfig.client;
  final Map<String, RealtimeChannel> _typingChannels = {};

  RealtimeChannel _getOrCreateTypingChannel(String conversationId) {
    return _typingChannels.putIfAbsent(conversationId, () {
      final channel = _client.channel('chat:$conversationId');
      channel.subscribe((status, _) {
        _log.d('Typing channel [$conversationId] status: $status');
      });
      return channel;
    });
  }

  /// Dispose a typing channel when the conversation screen is closed.
  Future<void> closeTypingChannel(String conversationId) async {
    final channel = _typingChannels.remove(conversationId);
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }

  /// Get or create a 1-on-1 conversation with a friend.
  /// Uses an RPC that does everything in a single DB call.
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

  /// Send typing indicator (ephemeral realtime broadcast — never persisted).
  Future<void> sendTyping(String conversationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final channel = _getOrCreateTypingChannel(conversationId);

    try {
      await channel.sendBroadcastMessage(
        event: 'typing',
        payload: {'user_id': userId},
      );
    } catch (e) {
      // Silently ignore typing indicator errors
    }
  }

  /// Subscribe to typing indicators.
  Stream<String> subscribeToTyping(String conversationId) {
    final controller = StreamController<String>.broadcast();
    final userId = _client.auth.currentUser?.id;

    final channel = _getOrCreateTypingChannel(conversationId);

    channel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final nestedPayload = payload['payload'] as Map<String, dynamic>?;
        final typingUserId = nestedPayload?['user_id'] as String?;

        if (typingUserId != null && typingUserId != userId) {
          controller.add(typingUserId);
        }
      },
    );

    controller.onCancel = () async {
      await closeTypingChannel(conversationId);
      await controller.close();
    };

    return controller.stream;
  }

  /// Stream unread message count (RPC + postgres-changes).
  /// ponytail: kept on Supabase for now; becomes a local PowerSync count query
  /// once notifications/unread move fully local (see code_review.md M13/D7).
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

    fetch();

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
}
