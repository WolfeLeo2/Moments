import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:moments/core/providers/moments_providers.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/services/firebase_messaging_service.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/features/notifications/models/notification_item.dart';
import 'package:moments/features/notifications/presentation/widgets/notification_card.dart';
import 'package:moments/features/notifications/utils/notification_combiner.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  String _selectedFilter = 'All';
  static const _filters = ['All', 'Requests', 'Activity', 'System'];

  @override
  void initState() {
    super.initState();
    FirebaseMessagingService.cancelAllNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(notificationsListProvider.notifier).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    final friendRequestsAsync = ref.watch(pendingRequestsProvider);
    final collabInvitesAsync = ref.watch(pendingMomentInvitationsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/Left arrow.svg', width: 34.w, height: 34.h),
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
              physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              itemCount: _filters.length,
              separatorBuilder: (_, index) => const SizedBox(width: 3),
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
        data: (generalNotifications) => friendRequestsAsync.when(
          data: (friendRequests) => collabInvitesAsync.when(
            data: (collabInvites) {
              final all = combineNotifications(
                friendRequests,
                collabInvites,
                generalNotifications,
              );
              if (all.isEmpty) return _emptyAll();
              final filtered = filterNotifications(all, _selectedFilter);
              if (filtered.isEmpty) return _emptyFilter();
              return _buildList(filtered);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('Error loading invites')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Error loading requests')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildList(List<NotificationItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NotificationCard(
            key: ValueKey(item.id),
            item: item,
            onDismiss: (item.type == NotificationType.friendRequest ||
                    item.type == NotificationType.collaborationInvite)
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    ref.read(notificationsListProvider.notifier).removeNotification(item.id);
                  },
          ),
        );
      },
    );
  }

  Widget _emptyAll() {
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

  Widget _emptyFilter() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.envelope, size: 64, color: Colors.grey[300]),
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
}
