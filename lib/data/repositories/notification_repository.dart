import 'package:moments/core/services/app_logger.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

final _log = AppLogger('NotificationRepository');

class NotificationRepository {
  final SupabaseClient _client;

  NotificationRepository(this._client);

  // Reusable stream infrastructure to prevent channel leaks
  StreamController<int>? _countController;
  RealtimeChannel? _countChannel;

  /// Get the count of unread notifications.
  /// Returns null on error so callers can distinguish 'zero' from 'fetch failed'.
  Future<int?> getUnreadCount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final count = await _client.rpc('get_unread_notification_count');
      return count as int;
    } catch (e) {
      _log.e('Error fetching notification count: $e');
      return null;
    }
  }

  /// Manually trigger a re-fetch of the unread count.
  /// Call this after mutations (markAllAsRead, markAsRead, delete) to ensure
  /// the count updates even if the realtime event is missed.
  void refreshCount() {
    if (_countController != null && !_countController!.isClosed) {
      _log.d('NotificationRepository: Manual refreshCount triggered');
      getUnreadCount().then((c) {
        // Only emit if we got a real value (skip on error to keep last-known count)
        if (c != null &&
            _countController != null &&
            !_countController!.isClosed) {
          _countController!.add(c);
        }
      });
    }
  }

  /// Stream of unread notification count.
  /// Reuses a single broadcast StreamController and Supabase Realtime channel
  /// to prevent leaks on repeated calls.
  Stream<int> streamUnreadCount() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _log.d('NotificationRepository: No user, returning 0 count');
      return Stream.value(0);
    }

    // Reuse existing stream if available
    if (_countController != null && !_countController!.isClosed) {
      // Still trigger a fresh fetch so new listeners get current data
      refreshCount();
      return _countController!.stream;
    }

    final controller = StreamController<int>.broadcast();
    _countController = controller;

    void fetch() {
      _log.d('NotificationRepository: Fetching unread count for $userId');
      getUnreadCount().then((c) {
        _log.d('NotificationRepository: Unread count = $c');
        // Only emit non-null values (skip on error to preserve last-known count)
        if (c != null && !controller.isClosed) controller.add(c);
      });
    }

    // Initial fetch
    fetch();

    // Listen for ALL changes in notifications table (simpler, more reliable)
    _log.d(
      'NotificationRepository: Setting up realtime channel for notifications',
    );
    final channel = _client.channel('notification-changes-$userId');
    _countChannel = channel;
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;
            final affectedUserId = newRecord['user_id'] ?? oldRecord['user_id'];

            _log.d(
              'NotificationRepository: Realtime change detected for user $affectedUserId',
            );

            if (affectedUserId == userId) {
              _log.d(
                'NotificationRepository: Change is for current user, refetching count',
              );
              fetch();
            }
          },
        )
        .subscribe((status, _) {
          _log.d('NotificationRepository: Channel status = $status');
        });

    controller.onCancel = () async {
      _log.d('NotificationRepository: Closing notification count stream');
      if (_countChannel != null) {
        await _client.removeChannel(_countChannel!);
        _countChannel = null;
      }
      _countController = null;
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

    // Explicitly refresh the count stream so badge updates immediately
    refreshCount();
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

    // Explicitly refresh the count stream so badge updates immediately
    refreshCount();
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

    _log.d(
      'NotificationRepository: Fetching notifications for $userId (limit: $limit, offset: $offset)',
    );

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
      _log.d('NotificationRepository: Cannot delete, user not logged in');
      return;
    }

    _log.d(
      'NotificationRepository: Deleting notification $notificationId for user $userId',
    );

    try {
      await _client
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);
      _log.d('NotificationRepository: Delete successful');

      // Refresh count after deletion
      refreshCount();
    } catch (e) {
      _log.e('NotificationRepository: Delete failed: $e');
      rethrow;
    }
  }
}
