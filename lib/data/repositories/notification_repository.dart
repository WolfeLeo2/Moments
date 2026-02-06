import 'package:moments/core/services/app_logger.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../sources/supabase_config.dart';

final _log = AppLogger('NotificationRepository');

class NotificationRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get the count of unread notifications
  Future<int> getUnreadCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final count = await _client.rpc('get_unread_notification_count');
      return count as int;
    } catch (e) {
      _log.e('Error fetching notification count: $e');
      return 0;
    }
  }

  /// Stream of unread notification count
  Stream<int> streamUnreadCount() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('NotificationRepository: No user, returning 0 count');
      return Stream.value(0);
    }

    final controller = StreamController<int>();

    void fetch() {
      debugPrint('NotificationRepository: Fetching unread count for $userId');
      getUnreadCount().then((c) {
        debugPrint('NotificationRepository: Unread count = $c');
        if (!controller.isClosed) controller.add(c);
      });
    }

    // Initial fetch
    fetch();

    // Listen for ALL changes in notifications table (simpler, more reliable)
    // Filter is checked in callback to ensure it works with Supabase Realtime
    debugPrint(
      'NotificationRepository: Setting up realtime channel for notifications',
    );
    final channel = _client.channel('notification-changes-$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            // Check if this change affects the current user
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;
            final affectedUserId = newRecord['user_id'] ?? oldRecord['user_id'];

            debugPrint(
              'NotificationRepository: Realtime change detected for user $affectedUserId',
            );

            if (affectedUserId == userId) {
              debugPrint(
                'NotificationRepository: Change is for current user, refetching count',
              );
              fetch();
            }
          },
        )
        .subscribe((status, _) {
          debugPrint('NotificationRepository: Channel status = $status');
        });

    controller.onCancel = () async {
      debugPrint('NotificationRepository: Closing notification count stream');
      await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', userId);
  }

  /// Get notifications with pagination support
  /// [limit] - Number of notifications to fetch (default 30)
  /// [offset] - Number of notifications to skip for pagination (default 0)
  /// Returns notifications ordered by created_at descending
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 30,
    int offset = 0,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    debugPrint('NotificationRepository: Fetching notifications for $userId (limit: $limit, offset: $offset)');

    final response = await _client
        .from('notifications')
        .select('*, actor:actor_id(username, display_name, avatar_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('NotificationRepository: Cannot delete, user not logged in');
      return;
    }

    debugPrint(
      'NotificationRepository: Deleting notification $notificationId for user $userId',
    );

    try {
      await _client
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);
      debugPrint('NotificationRepository: Delete successful');
    } catch (e) {
      debugPrint('NotificationRepository: Delete failed: $e');
      rethrow;
    }
  }
}
