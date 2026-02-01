import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/providers/moments_providers.dart';
import 'package:moments/core/utils/extensions.dart';
import 'package:moments/data/models/friendship.dart';
import 'package:moments/data/models/moment_contributor.dart';
import 'package:moments/core/widgets/time_ago_text.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:moments/core/services/firebase_messaging_service.dart';
import 'package:moments/features/moments/presentation/moment_details_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:moments/features/map/providers/map_control_provider.dart';
import 'package:moments/data/models/moment.dart';

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

/// Configuration for notification type styling
class _NotificationTypeConfig {
  final Color accentColor;
  final Color backgroundColor;
  final dynamic icon; // HugeIcons use a special type
  final String label;

  const _NotificationTypeConfig({
    required this.accentColor,
    required this.backgroundColor,
    required this.icon,
    required this.label,
  });

  static _NotificationTypeConfig forType(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return _NotificationTypeConfig(
          accentColor: AppTheme.primaryBlue,
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
          icon: HugeIcons.strokeRoundedUserAdd01,
          label: 'Friend Request',
        );
      case NotificationType.collaborationInvite:
      case NotificationType.momentInvite:
        return _NotificationTypeConfig(
          accentColor: AppTheme.electricPurple,
          backgroundColor: AppTheme.electricPurple.withValues(alpha: 0.08),
          icon: HugeIcons.strokeRoundedUserGroup,
          label: 'Collaboration',
        );
      case NotificationType.momentLike:
        return _NotificationTypeConfig(
          accentColor: const Color(0xFFE91E63),
          backgroundColor: const Color(0xFFE91E63).withValues(alpha: 0.08),
          icon: HugeIcons.strokeRoundedFavourite,
          label: 'Reaction',
        );
      case NotificationType.newMoment:
        return _NotificationTypeConfig(
          accentColor: const Color(0xFF4CAF50),
          backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.08),
          icon: HugeIcons.strokeRoundedImage01,
          label: 'New Moment',
        );
      case NotificationType.system:
        return _NotificationTypeConfig(
          accentColor: const Color(0xFFFF9800),
          backgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.08),
          icon: HugeIcons.strokeRoundedAlert02,
          label: 'System',
        );
      case NotificationType.promo:
        return _NotificationTypeConfig(
          accentColor: AppTheme.neonPink,
          backgroundColor: AppTheme.neonPink.withValues(alpha: 0.08),
          icon: HugeIcons.strokeRoundedGift,
          label: 'Promo',
        );
      case NotificationType.other:
        return _NotificationTypeConfig(
          accentColor: Colors.grey,
          backgroundColor: Colors.grey.withValues(alpha: 0.08),
          icon: HugeIcons.strokeRoundedNotification01,
          label: 'Notification',
        );
    }
  }
}

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Requests', 'Activity', 'System'];

  // Track dismissed items for animation
  final Set<String> _dismissedIds = {};

  @override
  void initState() {
    super.initState();
    FirebaseMessagingService.cancelAllNotifications();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(notificationsListProvider);
      ref.read(notificationsListProvider.notifier).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            height: 46,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 3),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return FilterChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilter = filter);
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.primaryBlue,
                  showCheckmark: true,
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : Colors.grey[500]!,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  final allNotifications = _combineNotifications(
                    friendRequests,
                    collabInvites,
                    generalNotifications,
                  );

                  if (allNotifications.isEmpty) {
                    return _buildEmptyState();
                  }

                  final filteredItems = _filterNotifications(allNotifications);

                  if (filteredItems.isEmpty) {
                    return _buildEmptyFilterState();
                  }

                  return _buildNotificationList(filteredItems);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error loading invites')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading requests')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<NotificationItem> _filterNotifications(List<NotificationItem> items) {
    switch (_selectedFilter) {
      case 'Requests':
        return items
            .where((n) =>
                n.type == NotificationType.friendRequest ||
                n.type == NotificationType.collaborationInvite)
            .toList();
      case 'Activity':
        return items
            .where((n) =>
                n.type == NotificationType.momentLike ||
                n.type == NotificationType.newMoment ||
                n.type == NotificationType.momentInvite)
            .toList();
      case 'System':
        return items
            .where((n) =>
                n.type == NotificationType.system ||
                n.type == NotificationType.promo ||
                n.type == NotificationType.other)
            .toList();
      default:
        return items;
    }
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
          body: 'sent you a friend request',
          createdAt: req.requestedAt,
          isRead: false,
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

    // General Notifications
    for (final notif in generalNotifications) {
      NotificationType type = NotificationType.other;
      final typeStr = notif['type'] as String?;

      // Skip chat messages and friend requests (handled separately)
      if (typeStr == 'message' || typeStr == 'chat_message') continue;
      if (typeStr == 'friend_request') continue;

      if (typeStr == 'system') type = NotificationType.system;
      if (typeStr == 'promo') type = NotificationType.promo;
      if (typeStr == 'moment_invite') type = NotificationType.momentInvite;
      if (typeStr == 'moment_like') type = NotificationType.momentLike;
      if (typeStr == 'new_moment_group' || typeStr == 'new_moment_post') {
        type = NotificationType.newMoment;
      }

      final actor = notif['actor'] as Map<String, dynamic>?;
      final actorName =
          actor?['display_name'] as String? ?? actor?['username'] as String?;
      final actorAvatarUrl = actor?['avatar_url'] as String?;
      final isRead = notif['is_read'] as bool? ?? false;

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

    // Deduplicate by ID
    final seenIds = <String>{};
    final deduplicatedItems = <NotificationItem>[];
    for (final item in items) {
      if (!seenIds.contains(item.id) && !_dismissedIds.contains(item.id)) {
        seenIds.add(item.id);
        deduplicatedItems.add(item);
      }
    }

    deduplicatedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return deduplicatedItems;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/notification.json',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
            repeat: false,
          ),
          const SizedBox(height: 20),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No notifications right now',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInbox,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing here',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No notifications in this category',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationItem> items) {
    final notifier = ref.read(notificationsListProvider.notifier);
    
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        // Load more when near the bottom
        if (scrollInfo is ScrollEndNotification) {
          final maxScroll = scrollInfo.metrics.maxScrollExtent;
          final currentScroll = scrollInfo.metrics.pixels;
          // Trigger load more when 200px from bottom
          if (maxScroll - currentScroll <= 200 && notifier.hasMore && !notifier.isLoadingMore) {
            notifier.loadMore();
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length + (notifier.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the bottom
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          
          final item = items[index];
          final config = _NotificationTypeConfig.forType(item.type);
          final requiresAction = item.type == NotificationType.friendRequest ||
              item.type == NotificationType.collaborationInvite;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NotificationCard(
              key: ValueKey(item.id),
              item: item,
              config: config,
              requiresAction: requiresAction,
              onDismiss: requiresAction
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      setState(() => _dismissedIds.add(item.id));
                      ref
                          .read(notificationsListProvider.notifier)
                          .removeNotification(item.id);
                    },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationItem item;
  final _NotificationTypeConfig config;
  final bool requiresAction;
  final VoidCallback? onDismiss;

  const _NotificationCard({
    super.key,
    required this.item,
    required this.config,
    required this.requiresAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch profile for friend requests if needed
    if (item.type == NotificationType.friendRequest && item.actorName == null) {
      final request = item.data as Friendship;
      final profileAsync = ref.watch(friendProfileProvider(request.userId));

      return profileAsync.when(
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();

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

          return _buildCard(context, ref, enrichedItem);
        },
        loading: () => _buildLoadingCard(),
        error: (_, __) => const SizedBox.shrink(),
      );
    }

    return _buildCard(context, ref, item);
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, NotificationItem item) {
    final cardContent = _buildCardContent(context, ref, item);

    // Wrap with Dismissible for non-action notifications
    if (!requiresAction && onDismiss != null) {
      return Dismissible(
        key: ValueKey('dismiss_${item.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss!(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedDelete02,
            color: Colors.white,
            size: 24,
          ),
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildCardContent(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) {
    return GestureDetector(
      onTap: () => _handleTap(context, ref, item),
      child: Container(
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : config.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? Colors.grey.shade200
                : config.accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar or Icon
                  _buildAvatar(item),
                  const SizedBox(width: 12),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type label badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: config.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            config.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: config.accentColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Main text
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                              height: 1.4,
                            ),
                            children: [
                              if (item.actorName != null)
                                TextSpan(
                                  text: '${item.actorName} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              TextSpan(
                                text: _getBodyText(item),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Group title for collab invites
                        if (item.type == NotificationType.collaborationInvite &&
                            item.groupTitle != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedFolder01,
                                size: 14,
                                color: config.accentColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.groupTitle!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: config.accentColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        // Time
                        TimeAgoText(
                          dateTime: item.createdAt,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Unread indicator
                  if (!item.isRead)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: config.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
            // Action buttons for requests
            if (requiresAction) _buildActionButtons(context, ref, item),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(NotificationItem item) {
    if (item.actorAvatarUrl != null && item.actorAvatarUrl!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: config.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            item.actorAvatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildIconAvatar(),
          ),
        ),
      );
    }
    return _buildIconAvatar();
  }

  Widget _buildIconAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: config.accentColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: HugeIcon(
          icon: config.icon,
          color: config.accentColor,
          size: 24,
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

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Accept',
              isPrimary: true,
              color: config.accentColor,
              onPressed: () => _handleAccept(context, ref, item),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              label: 'Decline',
              isPrimary: false,
              color: Colors.grey,
              onPressed: () => _handleDecline(context, ref, item),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, NotificationItem item) {
    // Mark as read
    if (!item.isRead) {
      ref.read(notificationsListProvider.notifier).markAsRead(item.id);
    }

    // Navigate based on type
    if (item.type == NotificationType.momentLike) {
      final relatedId = item.data is Map ? item.data['related_id'] : null;
      if (relatedId != null) {
        _navigateToMomentDetails(context, ref, relatedId.toString());
      }
    } else if (item.type == NotificationType.newMoment) {
      final relatedId = item.data is Map ? item.data['related_id'] : null;
      if (relatedId != null) {
        _navigateToMomentOnMap(context, ref, relatedId.toString());
      }
    } else if (item.type == NotificationType.momentInvite) {
      final relatedId = item.data is Map ? item.data['related_id'] : null;
      if (relatedId != null) {
        _navigateToMomentOnMap(context, ref, relatedId.toString());
      }
    }
  }

  Future<void> _navigateToMomentOnMap(
    BuildContext context,
    WidgetRef ref,
    String momentId,
  ) async {
    try {
      final repo = ref.read(momentRepositoryProvider);
      final moment = await repo.getMomentById(momentId);

      if (moment != null && context.mounted) {
        Navigator.pop(context);
        ref
            .read(mapCameraTargetProvider.notifier)
            .setTarget(LatLng(moment.latitude, moment.longitude));
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Could not find moment location');
      }
    }
  }

  Future<void> _navigateToMomentDetails(
    BuildContext context,
    WidgetRef ref,
    String momentId,
  ) async {
    try {
      final repo = ref.read(momentRepositoryProvider);
      final moment = await repo.getMomentById(momentId);

      if (moment != null && context.mounted) {
        List<Moment> moments;
        int initialPage = 0;

        if (moment.momentGroupId != null) {
          moments = await repo.getMomentsByGroup(moment.momentGroupId!);
          initialPage = moments.indexWhere((m) => m.id == momentId);
          if (initialPage < 0) initialPage = 0;
        } else {
          moments = [moment];
        }

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MomentDetailsPage(
                locationName: moment.location,
                moments: moments,
                initialPage: initialPage,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorSnackBar('Could not load moment');
      }
    }
  }

  Future<void> _handleAccept(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    HapticFeedback.mediumImpact();

    if (item.type == NotificationType.friendRequest) {
      final request = item.data as Friendship;
      try {
        await ref.read(friendRequestProvider.notifier).acceptRequest(request.id);
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
    } else if (item.type == NotificationType.collaborationInvite) {
      final invite = item.data as MomentContributor;
      try {
        await ref.read(momentRepositoryProvider).acceptInvitation(invite.id);
        if (context.mounted) {
          context.showSuccessSnackBar('Joined moment group!');

          // Navigate to the moment
          try {
            final moments = await ref
                .read(momentRepositoryProvider)
                .getMomentsByGroup(invite.momentId);

            if (context.mounted && moments.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MomentDetailsPage(
                    locationName: moments.first.location,
                    moments: moments,
                  ),
                ),
              );
            }
          } catch (_) {}
        }
      } catch (e) {
        if (context.mounted) {
          context.showErrorSnackBar('Failed to join group');
        }
      }
    }
  }

  Future<void> _handleDecline(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    HapticFeedback.lightImpact();

    if (item.type == NotificationType.friendRequest) {
      final request = item.data as Friendship;
      try {
        await ref.read(friendRequestProvider.notifier).rejectRequest(request.id);
        if (context.mounted) {
          context.showSuccessSnackBar('Request declined');
          ref.invalidate(pendingRequestsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          context.showErrorSnackBar('Failed to decline request');
        }
      }
    } else if (item.type == NotificationType.collaborationInvite) {
      final invite = item.data as MomentContributor;
      try {
        await ref.read(momentRepositoryProvider).removeContributor(invite.id);
        if (context.mounted) {
          context.showSuccessSnackBar('Invite declined');
        }
      } catch (e) {
        if (context.mounted) {
          context.showErrorSnackBar('Failed to decline invite');
        }
      }
    }
  }
}

/// Styled action button for accept/decline
class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? color : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
