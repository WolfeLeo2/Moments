enum NotificationType {
  friendRequest,
  collaborationInvite,
  newMoment,
  momentLike,
  momentInvite,
  system,
  promo,
  other,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? actorName;
  final String? actorAvatarUrl;
  final String? groupTitle;
  final dynamic data;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.actorName,
    this.actorAvatarUrl,
    this.groupTitle,
    this.data,
  });

  NotificationItem copyWith({String? actorName, String? actorAvatarUrl}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead,
      actorName: actorName ?? this.actorName,
      actorAvatarUrl: actorAvatarUrl ?? this.actorAvatarUrl,
      groupTitle: groupTitle,
      data: data,
    );
  }
}
