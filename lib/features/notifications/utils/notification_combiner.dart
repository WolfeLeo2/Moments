import 'package:moments/data/models/friendship.dart';
import 'package:moments/data/models/moment_contributor.dart';
import 'package:moments/features/notifications/models/notification_item.dart';

/// Maps the notification type string from the DB/PS row to [NotificationType].
NotificationType notificationTypeFromString(String? typeStr) {
  switch (typeStr) {
    case 'friend_request':
      return NotificationType.friendRequest;
    case 'moment_invite':
    case 'collaboration_invite':
      return NotificationType.momentInvite;
    case 'moment_like':
      return NotificationType.momentLike;
    case 'new_moment_group':
    case 'new_moment_post':
      return NotificationType.newMoment;
    case 'system':
      return NotificationType.system;
    case 'promo':
      return NotificationType.promo;
    default:
      return NotificationType.other;
  }
}

/// Merges friend-request rows, collab-invite rows, and general PS notification
/// rows into a single de-duplicated, newest-first list.
///
/// Chat messages and friend_request rows from the general list are dropped —
/// they're surfaced via the friend-requests source and the chat badge.
List<NotificationItem> combineNotifications(
  List<Friendship> friendRequests,
  List<MomentContributor> collabInvites,
  List<Map<String, dynamic>> generalNotifications,
) {
  final items = <NotificationItem>[];

  for (final req in friendRequests) {
    items.add(
      NotificationItem(
        id: req.id,
        type: NotificationType.friendRequest,
        title: 'Friend Request',
        body: 'sent you a friend request',
        createdAt: req.requestedAt,
        isRead: false,
        data: req,
      ),
    );
  }

  for (final invite in collabInvites) {
    items.add(
      NotificationItem(
        id: invite.id,
        type: NotificationType.collaborationInvite,
        title: invite.groupTitle ?? 'Moment Group',
        body: 'invited you to collaborate',
        createdAt: invite.invitedAt,
        isRead: false,
        actorName: invite.inviterUsername,
        actorAvatarUrl: invite.inviterAvatarUrl,
        groupTitle: invite.groupTitle,
        data: invite,
      ),
    );
  }

  for (final notif in generalNotifications) {
    final typeStr = notif['type'] as String?;
    // Deduplicate with the friend-request source; skip chat messages.
    if (typeStr == 'message' ||
        typeStr == 'chat_message' ||
        typeStr == 'friend_request') {
      continue;
    }

    // PowerSync stores booleans as SQLite integers (0/1).
    final isRead = switch (notif['is_read']) {
      final bool b => b,
      final int i => i != 0,
      _ => false,
    };

    items.add(
      NotificationItem(
        id: notif['id'] as String,
        type: notificationTypeFromString(typeStr),
        title: notif['title'] as String? ?? 'Notification',
        body: notif['body'] as String? ?? '',
        createdAt: DateTime.parse(notif['created_at'] as String),
        isRead: isRead,
        actorName: notif['actor_name'] as String?,
        actorAvatarUrl: notif['actor_avatar_url'] as String?,
        data: notif,
      ),
    );
  }

  // De-duplicate by id, sort newest first.
  final seen = <String>{};
  final deduped = <NotificationItem>[];
  for (final item in items) {
    if (seen.add(item.id)) deduped.add(item);
  }
  deduped.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return deduped;
}

/// Client-side filter applied by the chip bar.
List<NotificationItem> filterNotifications(
  List<NotificationItem> items,
  String filter,
) {
  switch (filter) {
    case 'Requests':
      return items
          .where(
            (n) =>
                n.type == NotificationType.friendRequest ||
                n.type == NotificationType.collaborationInvite,
          )
          .toList();
    case 'Activity':
      return items
          .where(
            (n) =>
                n.type == NotificationType.momentLike ||
                n.type == NotificationType.newMoment ||
                n.type == NotificationType.momentInvite,
          )
          .toList();
    case 'System':
      return items
          .where(
            (n) =>
                n.type == NotificationType.system ||
                n.type == NotificationType.promo ||
                n.type == NotificationType.other,
          )
          .toList();
    default:
      return items;
  }
}
