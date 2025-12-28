import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../sources/supabase_config.dart';

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
      print('Error fetching notification count: $e');
      return 0;
    }
  }

  /// Stream of unread notification count
  Stream<int> streamUnreadCount() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(0);

    final controller = StreamController<int>();

    void fetch() {
      getUnreadCount().then((c) {
        if (!controller.isClosed) controller.add(c);
      });
    }

    // Initial fetch
    fetch();

    // Listen for changes in notifications table for this user
    final channel = _client.channel('public:notifications:$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => fetch(),
        )
        .subscribe();

    controller.onCancel = () async {
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

  /// Get all notifications (last 24 hours)
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('notifications')
        .select('*, actor:actor_id(username, display_name, avatar_url)')
        .eq('user_id', userId)
        .gt(
          'created_at',
          DateTime.now().subtract(const Duration(hours: 24)).toIso8601String(),
        )
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
