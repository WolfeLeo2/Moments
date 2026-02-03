import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/data/models/profile.dart';
import 'package:moments/core/providers/moments_providers.dart';
import 'package:moments/features/feed/presentation/widgets/feed_post_card.dart';
import 'package:moments/features/feed/presentation/widgets/friends_bar.dart';
import 'package:moments/widgets/blurred_app_bar.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/features/social/presentation/friends_page.dart';
import 'package:moments/features/profile/profile_page.dart';
import 'package:moments/features/notifications/presentation/notifications_page.dart';

/// Instagram-style feed page showing moments in chronological order
/// Groups moments by moment_group_id for carousel display
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String? _filterByUserId; // Filter feed by specific friend

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showFriendsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FriendsPage()),
    );
  }

  void _showProfilePage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  void _showNotificationsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
  }

  void _onFriendTap(Profile friend) {
    setState(() {
      _filterByUserId = _filterByUserId == friend.id ? null : friend.id;
    });
  }

  /// Groups moments by moment_group_id
  /// Returns a list of moment groups (each group is a list of moments)
  List<List<Moment>> _groupMoments(List<Moment> moments) {
    // Sort by timestamp descending (newest first)
    final sortedMoments = List<Moment>.from(moments)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Group by moment_group_id
    final Map<String?, List<Moment>> groups = {};

    for (final moment in sortedMoments) {
      final groupKey = moment.momentGroupId ?? moment.id; // Use moment id if no group
      groups.putIfAbsent(groupKey, () => []);
      groups[groupKey]!.add(moment);
    }

    // Convert to list and sort groups by the newest moment in each group
    final groupsList = groups.values.toList();
    groupsList.sort((a, b) => b.first.timestamp.compareTo(a.first.timestamp));

    return groupsList;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final momentsAsync = ref.watch(momentsStreamProvider);
    final profile = ref.watch(currentUserProfileProvider);
    final notificationCount = ref.watch(notificationCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: BlurredAppBar(
        title: 'Feed',
        profileImageUrl: profile.value?.avatarUrl,
        notificationCount: notificationCount.value ?? 0,
        onFriendsPressed: _showFriendsPage,
        onProfilePressed: _showProfilePage,
        onNotificationsPressed: _showNotificationsPage,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(momentsStreamProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppTheme.primaryBlue,
        child: momentsAsync.when(
          data: (moments) => _buildFeed(moments),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildFeed(List<Moment> moments) {
    if (moments.isEmpty) {
      return _buildEmptyState();
    }

    // Filter by user if selected
    var filteredMoments = moments;
    if (_filterByUserId != null) {
      filteredMoments = moments.where((m) => m.userId == _filterByUserId).toList();
    }

    // Group moments
    final momentGroups = _groupMoments(filteredMoments);

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Friends bar at top with search
        SliverToBoxAdapter(
          child: FriendsBar(
            onFriendTap: _onFriendTap,
          ),
        ),

        // Filter indicator
        if (_filterByUserId != null)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Showing moments from selected friend',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _filterByUserId = null);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),

        // Divider
        SliverToBoxAdapter(
          child: Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ),

        // Feed posts
        if (momentGroups.isEmpty && _filterByUserId != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No moments from this friend yet',
                  style: TextStyle(color: AppTheme.textGray),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final momentGroup = momentGroups[index];
                return FeedPostCard(
                  moments: momentGroup,
                  onLocationTap: () => _navigateToMapForMoment(momentGroup.first),
                );
              },
              childCount: momentGroups.length,
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  void _navigateToMapForMoment(Moment moment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to ${moment.location} on map'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: FriendsBar(),
        ),
        SliverToBoxAdapter(
          child: Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildShimmerPost(),
            childCount: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerPost() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Image shimmer
          Container(
            width: double.infinity,
            height: 375,
            color: Colors.grey[200],
          ),
          // Actions shimmer
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 48,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No moments yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture your first moment to see it here!\nYour friends\' moments will also appear.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textGray,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.emergencyRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textGray,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(momentsStreamProvider),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
