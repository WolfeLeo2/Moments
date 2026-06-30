import 'package:moments/core/services/app_logger.dart';
import 'package:moments/core/services/powersync/chat_powersync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _log = AppLogger('NotificationRepository');

class NotificationRepository {
  final SupabaseClient _client;
  final ChatPowerSyncService _ps;

  NotificationRepository(this._client, this._ps);

  String? get _userId => _client.auth.currentUser?.id;

  // ── Reads (PowerSync local queries) ──────────────────────────────────────

  /// Live stream of all notifications for the current user, newest first.
  /// Backed by PowerSync — works offline, realtime when synced.
  Stream<List<Map<String, dynamic>>> watchNotifications() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);
    return _ps.watchQuery(
      'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC',
      parameters: [userId],
    );
  }

  /// Live count of unread notifications — local SQL, no RPC needed.
  Stream<int> watchUnreadCount() {
    final userId = _userId;
    if (userId == null) return Stream.value(0);
    return _ps
        .watchQuery(
          'SELECT COUNT(*) as count FROM notifications '
          'WHERE user_id = ? AND is_read = 0',
          parameters: [userId],
        )
        .map((rows) => rows.isEmpty ? 0 : (rows.first['count'] as int? ?? 0));
  }

  // ── Writes (PowerSync local writes → connector uploads async) ────────────

  /// Mark a single notification as read.
  Future<void> markAsRead(String id) async {
    _log.d('markAsRead $id');
    await _ps.execute(
      'UPDATE notifications SET is_read = 1 WHERE id = ?',
      [id],
    );
  }

  /// Mark all unread notifications as read.
  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null) return;
    _log.d('markAllAsRead for $userId');
    await _ps.execute(
      'UPDATE notifications SET is_read = 1 '
      'WHERE user_id = ? AND is_read = 0',
      [userId],
    );
  }

  /// Delete a notification (swipe-to-dismiss).
  Future<void> deleteNotification(String id) async {
    final userId = _userId;
    if (userId == null) return;
    _log.d('deleteNotification $id');
    await _ps.execute(
      'DELETE FROM notifications WHERE id = ? AND user_id = ?',
      [id, userId],
    );
  }
}
