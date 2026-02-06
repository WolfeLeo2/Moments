import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/core/providers/moments_providers.dart';
import 'package:moments/features/feed/presentation/widgets/memory_card.dart';
import 'package:moments/features/feed/presentation/widgets/chapter_header.dart';
import 'package:moments/features/feed/presentation/widgets/timeline_connector.dart';
import 'package:moments/widgets/blurred_app_bar.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/features/social/presentation/friends_page.dart';
import 'package:moments/features/profile/profile_page.dart';
import 'package:moments/features/notifications/presentation/notifications_page.dart';

/// Memory Lane - An emotional, timeline-based view of memories
/// Replaces the traditional feed with a journal-like experience
class MemoryLanePage extends ConsumerStatefulWidget {
  const MemoryLanePage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<MemoryLanePage> createState() => _MemoryLanePageState();
}

class _MemoryLanePageState extends ConsumerState<MemoryLanePage>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
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

  /// Groups moments into temporal chapters
  Map<String, List<Moment>> _groupIntoChapters(List<Moment> moments) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    final chapters = <String, List<Moment>>{
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Last Week': [],
      'This Month': [],
      'Last Month': [],
    };

    // For older moments, group by season/year
    final olderChapters = <String, List<Moment>>{};

    for (final moment in moments) {
      final momentDate = DateTime(
        moment.timestamp.year,
        moment.timestamp.month,
        moment.timestamp.day,
      );

      if (momentDate.isAtSameMomentAs(today)) {
        chapters['Today']!.add(moment);
      } else if (momentDate.isAtSameMomentAs(yesterday)) {
        chapters['Yesterday']!.add(moment);
      } else if (momentDate.isAfter(thisWeekStart) ||
          momentDate.isAtSameMomentAs(thisWeekStart)) {
        chapters['This Week']!.add(moment);
      } else if (momentDate.isAfter(lastWeekStart) ||
          momentDate.isAtSameMomentAs(lastWeekStart)) {
        chapters['Last Week']!.add(moment);
      } else if (momentDate.isAfter(thisMonthStart) ||
          momentDate.isAtSameMomentAs(thisMonthStart)) {
        chapters['This Month']!.add(moment);
      } else if (momentDate.isAfter(lastMonthStart) ||
          momentDate.isAtSameMomentAs(lastMonthStart)) {
        chapters['Last Month']!.add(moment);
      } else {
        // Group by season + year for older moments
        final chapterName = _getSeasonalChapter(moment.timestamp);
        olderChapters.putIfAbsent(chapterName, () => []);
        olderChapters[chapterName]!.add(moment);
      }
    }

    // Remove empty recent chapters
    chapters.removeWhere((key, value) => value.isEmpty);

    // Sort older chapters by date descending
    final sortedOlderKeys = olderChapters.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final key in sortedOlderKeys) {
      chapters[key] = olderChapters[key]!;
    }

    return chapters;
  }

  /// Returns a seasonal chapter name like "Summer 2023" or "Two winters ago"
  String _getSeasonalChapter(DateTime date) {
    final now = DateTime.now();
    final yearsAgo = now.year - date.year;
    final season = _getSeason(date.month);

    if (yearsAgo == 0) {
      return season;
    } else if (yearsAgo == 1) {
      return 'Last $season';
    } else if (yearsAgo == 2) {
      return 'Two ${season.toLowerCase()}s ago';
    } else {
      return '$season ${date.year}';
    }
  }

  String _getSeason(int month) {
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Fall';
    return 'Winter';
  }

  /// Group consecutive moments by location for "cluster" display
  List<List<Moment>> _clusterByLocation(List<Moment> moments) {
    if (moments.isEmpty) return [];

    // Sort by timestamp descending
    final sorted = List<Moment>.from(moments)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final clusters = <List<Moment>>[];
    List<Moment> currentCluster = [sorted.first];

    for (var i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final previous = sorted[i - 1];

      // Cluster if same momentGroupId, same location, or within 30 min
      final timeDiff = previous.timestamp.difference(current.timestamp).inMinutes.abs();
      final sameGroup = current.momentGroupId != null &&
          current.momentGroupId == previous.momentGroupId;
      final sameLocation = current.location == previous.location;

      if (sameGroup || (sameLocation && timeDiff < 30)) {
        currentCluster.add(current);
      } else {
        clusters.add(currentCluster);
        currentCluster = [current];
      }
    }

    if (currentCluster.isNotEmpty) {
      clusters.add(currentCluster);
    }

    return clusters;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final momentsAsync = ref.watch(momentsStreamProvider);
    final profile = ref.watch(currentUserProfileProvider);
    final notificationCount = ref.watch(notificationCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      extendBodyBehindAppBar: false,
      appBar: BlurredAppBar(
        title: 'Memory Lane',
        profileImageUrl: profile.value?.avatarUrl,
        notificationCount: notificationCount.value ?? 0,
        onFriendsPressed: _showFriendsPage,
        onProfilePressed: _showProfilePage,
        onNotificationsPressed: _showNotificationsPage,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(momentsStreamProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppTheme.dustyRose,
        child: momentsAsync.when(
          data: (moments) => _buildTimeline(moments),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildTimeline(List<Moment> moments) {
    if (moments.isEmpty) {
      return _buildEmptyState();
    }

    final chapters = _groupIntoChapters(moments);
    final chapterKeys = chapters.keys.toList();

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // Anniversary memories at top (if any)
        ..._buildAnniversarySection(moments),

        // Timeline content
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chapterName = chapterKeys[index];
                final chapterMoments = chapters[chapterName]!;
                final clusters = _clusterByLocation(chapterMoments);

                return _buildChapterSection(chapterName, clusters, index == 0);
              },
              childCount: chapterKeys.length,
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 120),
        ),
      ],
    );
  }

  List<Widget> _buildAnniversarySection(List<Moment> moments) {
    final anniversaries = moments.where((m) => AppTheme.isAnniversary(m.timestamp)).toList();

    if (anniversaries.isEmpty) return [];

    final yearsAgo = DateTime.now().year - anniversaries.first.timestamp.year;

    return [
      SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.dustyRose.withOpacity(0.15),
                AppTheme.amberGold.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.dustyRose.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppTheme.amberGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    yearsAgo == 1 ? 'One year ago today' : '$yearsAgo years ago today',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: anniversaries.take(5).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final moment = anniversaries[index];
                    return _buildMiniMemoryCard(moment);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildMiniMemoryCard(Moment moment) {
    return GestureDetector(
      onTap: () => _openMemoryDetail(moment),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: moment.imageUrl != null
              ? Image.network(
                  moment.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.dustyRose.withOpacity(0.2),
                    child: const Icon(Icons.photo, color: AppTheme.dustyRose),
                  ),
                )
              : Container(
                  color: AppTheme.dustyRose.withOpacity(0.2),
                  child: const Icon(Icons.photo, color: AppTheme.dustyRose),
                ),
        ),
      ),
    );
  }

  Widget _buildChapterSection(
    String chapterName,
    List<List<Moment>> clusters,
    bool isFirst,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chapter header
        ChapterHeader(
          title: chapterName,
          isFirst: isFirst,
        ),

        // Memory clusters with timeline
        ...clusters.asMap().entries.map((entry) {
          final isLast = entry.key == clusters.length - 1;
          final cluster = entry.value;

          return TimelineConnector(
            isLast: isLast,
            child: MemoryCard(
              moments: cluster,
              onTap: () => _openMemoryDetail(cluster.first),
            ),
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }

  void _openMemoryDetail(Moment moment) {
    HapticFeedback.lightImpact();
    // TODO: Navigate to full memory view / relive experience
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening memory: ${moment.title}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.twilightBlue,
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildShimmerCard(),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 8, right: 16),
            decoration: BoxDecoration(
              color: AppTheme.dustyRose.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          // Card shimmer
          Expanded(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.dustyRose.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 56,
                color: AppTheme.dustyRose,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your story begins here',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Capture your first moment and\nstart building your memory lane',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textGray,
                  ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.sageGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppTheme.sageGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: AppTheme.sageGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Capture a moment',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.sageGreen,
                        ),
                  ),
                ],
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
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: AppTheme.dustyRose,
            ),
            const SizedBox(height: 24),
            Text(
              'Couldn\'t load memories',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textDark,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textGray,
                  ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => ref.invalidate(momentsStreamProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.twilightBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
