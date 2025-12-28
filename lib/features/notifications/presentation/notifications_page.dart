import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/providers/moments_providers.dart';
import 'package:moments/core/utils/extensions.dart';
import 'package:moments/data/models/friendship.dart';
import 'package:moments/data/models/moment_contributor.dart';
import 'package:moments/core/services/avatar_cache_service.dart';
import 'package:moments/core/widgets/time_ago_text.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:moments/core/services/firebase_messaging_service.dart';

enum NotificationType {
  friendRequest,
  collaborationInvite,
  newMoment,
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

  NotificationItem({
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
}

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Requests', 'System'];

  @override
  void initState() {
    super.initState();

    // Clear all local notifications from the phone panel when opening this page
    FirebaseMessagingService.cancelAllNotifications();

    // Mark all as read when opening the page
    // We delay slightly to ensure the UI builds first
    Future.delayed(Duration.zero, () {
      ref.read(notificationsListProvider.notifier).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch all sources
    final friendRequestsAsync = ref.watch(pendingRequestsProvider);
    final collaborationInvitesAsync = ref.watch(
      pendingMomentInvitationsStreamProvider,
    );
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/Left arrow.svg',
            width: 34.w,
            height: 34.h,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          // Only show "Mark all as read" if there are notifications
          if (notificationsAsync.value?.isNotEmpty == true)
            TextButton(
              onPressed: () async {
                await ref
                    .read(notificationsListProvider.notifier)
                    .markAllAsRead();
              },
              child: const Text(
                'Mark all as read',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = filter);
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.primaryBlue,
                  showCheckmark: false,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.grey[200]!,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: notificationsAsync.when(
        data: (generalNotifications) {
          return friendRequestsAsync.when(
            data: (friendRequests) {
              return collaborationInvitesAsync.when(
                data: (collabInvites) {
                  // Combine all notifications
                  // We need to fetch profiles for friend requests to show names/avatars
                  // Since we can't do async in build, we should probably have a provider that does this join.
                  // Or we can use the 'friendProfile' provider for each item in the list.
                  // But _combineNotifications is synchronous.
                  // Let's modify _NotificationCard to fetch the profile if it's missing.

                  final allNotifications = _combineNotifications(
                    friendRequests,
                    collabInvites,
                    generalNotifications,
                  );

                  if (allNotifications.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Filter notifications based on selection
                  List<NotificationItem> filteredItems = allNotifications;
                  if (_selectedFilter == 'Requests') {
                    filteredItems = allNotifications
                        .where(
                          (n) =>
                              n.type == NotificationType.friendRequest ||
                              n.type == NotificationType.collaborationInvite,
                        )
                        .toList();
                  } else if (_selectedFilter == 'System') {
                    filteredItems = allNotifications
                        .where(
                          (n) =>
                              n.type == NotificationType.system ||
                              n.type == NotificationType.promo ||
                              n.type == NotificationType.other,
                        )
                        .toList();
                  }

                  return _buildNotificationList(filteredItems);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const Center(child: Text('Error loading invites')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Error loading requests')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading notifications: $e')),
      ),
    );
  }

  List<NotificationItem> _combineNotifications(
    List<Friendship> friendRequests,
    List<MomentContributor> collabInvites,
    List<Map<String, dynamic>> generalNotifications,
  ) {
    final items = <NotificationItem>[];

    // Friend Requests
    for (final req in friendRequests) {
      items.add(
        NotificationItem(
          id: req.id,
          type: NotificationType.friendRequest,
          title: 'Friend Request',
          body:
              'sent you a friend request', // We need the sender name, usually fetched separately or included
          createdAt: req.requestedAt,
          isRead: false, // Requests are always "unread" until acted upon
          data: req,
        ),
      );
    }

    // Collaboration Invites
    for (final invite in collabInvites) {
      items.add(
        NotificationItem(
          id: invite.id,
          type: NotificationType.collaborationInvite,
          title: 'Collaboration Invite',
          body: 'invited you to join a moment',
          createdAt: invite.invitedAt,
          isRead: false,
          data: invite,
        ),
      );
    }

    // General Notifications
    for (final notif in generalNotifications) {
      NotificationType type = NotificationType.other;
      final typeStr = notif['type'] as String?;

      // Skip chat messages as they appear in the chat list
      if (typeStr == 'message' || typeStr == 'chat_message') continue;

      // Skip friend requests as they are handled by the pendingRequestsProvider
      // This prevents duplication and ensures we have the correct Friendship ID for actions
      if (typeStr == 'friend_request') continue;

      if (typeStr == 'system') type = NotificationType.system;
      if (typeStr == 'promo') type = NotificationType.promo;
      if (typeStr == 'moment_invite') type = NotificationType.momentInvite;
      if (typeStr == 'new_moment_group' || typeStr == 'new_moment_post')
        type = NotificationType.newMoment;

      // Extract actor details
      final actor = notif['actor'] as Map<String, dynamic>?;
      final actorName =
          actor?['display_name'] as String? ?? actor?['username'] as String?;
      final actorAvatarUrl = actor?['avatar_url'] as String?;

      final isRead = notif['is_read'] as bool? ?? false;

      // Skip read notifications (User wants them dismissed/cleared when read)
      if (isRead) continue;

      items.add(
        NotificationItem(
          id: notif['id'] as String,
          type: type,
          title: notif['title'] as String? ?? 'Notification',
          body: notif['body'] as String? ?? '',
          createdAt: DateTime.parse(notif['created_at'] as String),
          isRead: isRead,
          actorName: actorName,
          actorAvatarUrl: actorAvatarUrl,
          data: notif,
        ),
      );
    }

    // Sort by date descending
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/notification.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            repeat: false,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll let you know when something happens!',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No notifications in this category',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        return _NotificationCard(item: item);
      },
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationItem item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If it's a friend request and we don't have actor details, fetch them
    if (item.type == NotificationType.friendRequest && item.actorName == null) {
      final request = item.data as Friendship;
      final profileAsync = ref.watch(friendProfileProvider(request.userId));

      return profileAsync.when(
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();

          // Create a new item with profile details
          final enrichedItem = NotificationItem(
            id: item.id,
            type: item.type,
            title: item.title,
            body: item.body,
            createdAt: item.createdAt,
            isRead: item.isRead,
            actorName: profile.displayName ?? profile.username,
            actorAvatarUrl: profile.avatarUrl,
            data: item.data,
          );

          return _buildCardContent(context, ref, enrichedItem);
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
      );
    }

    return _buildCardContent(context, ref, item);
  }

  Widget _buildCardContent(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (item.type != NotificationType.friendRequest) {
          ref.read(notificationsListProvider.notifier).markAsRead(item.id);
        }
      },
      child: GestureDetector(
        onTap: () {
          if (item.type == NotificationType.newMoment ||
              item.type == NotificationType.momentInvite) {
            final relatedId = item.data is Map ? item.data['related_id'] : null;
            if (relatedId != null) {
              Navigator.pop(context);
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.isRead
                ? Colors.white
                : AppTheme.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: item.isRead
                  ? Colors.grey[200]!
                  : AppTheme.primaryBlue.withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          height: 1.4,
                          fontFamily: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.fontFamily,
                        ),
                        children: [
                          if (item.actorName != null)
                            TextSpan(
                              text: '${item.actorName} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          TextSpan(text: _getBodyText(item)),
                          const TextSpan(text: '  '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: TimeAgoText(
                              dateTime: item.createdAt,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.type == NotificationType.friendRequest)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _buildFriendRequestActions(context, ref, item),
                      ),
                  ],
                ),
              ),
              if (!item.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBodyText(NotificationItem item) {
    if (item.actorName != null && item.body.startsWith(item.actorName!)) {
      return item.body.substring(item.actorName!.length).trim();
    }
    return item.body;
  }

  Widget _buildAvatar(NotificationItem item) {
    if (item.actorAvatarUrl != null && item.actorAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(item.actorAvatarUrl!),
        backgroundColor: Colors.grey[200],
      );
    }
    return _buildIcon(item.type);
  }

  Widget _buildIcon(NotificationType type) {
    dynamic icon;
    Color color;
    Color bg;

    switch (type) {
      case NotificationType.friendRequest:
        icon = HugeIcons.strokeRoundedUserAdd01;
        color = AppTheme.primaryBlue;
        bg = AppTheme.primaryBlue.withOpacity(0.1);
        break;
      case NotificationType.collaborationInvite:
      case NotificationType.momentInvite:
        icon = HugeIcons.strokeRoundedImageAdd02;
        color = AppTheme.electricPurple;
        bg = AppTheme.electricPurple.withOpacity(0.1);
        break;
      case NotificationType.newMoment:
        icon = HugeIcons.strokeRoundedImage01;
        color = Colors.green;
        bg = Colors.green.withOpacity(0.1);
        break;
      case NotificationType.system:
        icon = HugeIcons.strokeRoundedNotification01;
        color = Colors.orange;
        bg = Colors.orange.withOpacity(0.1);
        break;
      case NotificationType.promo:
        icon = HugeIcons.strokeRoundedGift;
        color = AppTheme.neonPink;
        bg = AppTheme.neonPink.withOpacity(0.1);
        break;
      default:
        icon = HugeIcons.strokeRoundedNotification01;
        color = Colors.grey;
        bg = Colors.grey.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: HugeIcon(icon: icon, color: color, size: 24),
    );
  }

  Widget _buildFriendRequestActions(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) {
    final request = item.data as Friendship;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              try {
                await ref
                    .read(friendRequestProvider.notifier)
                    .acceptRequest(request.id);
                if (context.mounted) {
                  context.showSuccessSnackBar('Friend request accepted!');
                  ref.invalidate(friendsListProvider);
                  ref.invalidate(pendingRequestsProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  context.showErrorSnackBar('Failed to accept request');
                }
              }
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 0),
              minimumSize: const Size(0, 32),
            ),
            child: const Text(
              'Accept',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              try {
                await ref
                    .read(friendRequestProvider.notifier)
                    .rejectRequest(request.id);
                if (context.mounted) {
                  context.showSuccessSnackBar('Friend request declined');
                  ref.invalidate(pendingRequestsProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  context.showErrorSnackBar('Failed to decline request');
                }
              }
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 0),
              minimumSize: const Size(0, 32),
            ),
            child: Text(
              'Decline',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
