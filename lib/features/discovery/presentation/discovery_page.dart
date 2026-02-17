import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/moment.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../widgets/offline_image.dart';
import '../../moments/presentation/moment_details_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import 'all_moments_page.dart';
import 'all_friends_page.dart';
import 'all_locations_page.dart';

/// Discovery page — browse all moments from the user and friends.
///
/// Sections:
/// - Greeting header with stats
/// - Recent moments horizontal strip
/// - Location-based moment groups (2-column grid)
class DiscoveryPage extends ConsumerStatefulWidget {
  const DiscoveryPage({
    super.key,
    this.scrollController,
    this.viewLabel,
    this.pullDownMenuItems,
  });

  final ScrollController? scrollController;
  final String? viewLabel;
  final List<PullDownMenuEntry> Function()? pullDownMenuItems;

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage>
    with AutomaticKeepAliveClientMixin {
  AuthService get _authService => ref.read(authServiceProvider);

  /// Resolved signed URLs: mediaPath → signedUrl
  final Map<String, String> _signedUrls = {};

  /// Active filter tab index: 0 = All, 1 = Photos, 2 = Videos, 3 = Audio
  int _activeFilter = 0;
  static const _filterLabels = ['All', 'Photos', 'Videos', 'Audio'];

  @override
  bool get wantKeepAlive => true;

  /// Resolve mediaPath → signed URL for moments that have null imageUrl
  Future<void> _resolveSignedUrls(List<Moment> moments) async {
    final pathsToResolve = <String>{};
    for (final m in moments) {
      if (m.imageUrl != null && m.imageUrl!.isNotEmpty) continue;
      // Skip if local file is available
      if (m.localMediaPath != null && m.localMediaPath!.isNotEmpty) continue;
      final path = m.mediaType == 'video' ? m.thumbnailPath : m.mediaPath;
      if (path != null && path.isNotEmpty && !_signedUrls.containsKey(path)) {
        pathsToResolve.add(path);
      }
    }
    if (pathsToResolve.isEmpty) return;

    final urls = await SignedUrlCache.getSignedUrlsBatch(
      pathsToResolve.toList(),
    );
    if (mounted && urls.isNotEmpty) {
      setState(() => _signedUrls.addAll(urls));
    }
  }

  /// Get the best available image URL for a moment
  String? _getImageUrl(Moment moment) {
    if (moment.imageUrl != null && moment.imageUrl!.isNotEmpty) {
      return moment.imageUrl;
    }
    final path = moment.mediaType == 'video'
        ? moment.thumbnailPath
        : moment.mediaPath;
    if (path != null && _signedUrls.containsKey(path)) {
      return _signedUrls[path];
    }
    return null;
  }

  // ─── Greeting SliverAppBar ──────────────────────────────────────

  Widget _buildGreetingSliverAppBar(
    String firstName,
    String? avatarUrl,
    int notificationCount,
  ) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return SliverAppBar(
      pinned: false,
      floating: false,
      expandedHeight: 110,
      backgroundColor: AppTheme.backgroundBeige,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: [
        Badge(
          isLabelVisible: notificationCount > 0,
          label: Text(
            '$notificationCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: AppTheme.coralPink,
          child: IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedNotification01,
              color: Colors.black87,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$greeting, $firstName',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: 'GoogleSansFlex',
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark.withValues(alpha: 0.8),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                widget.pullDownMenuItems != null
                    ? PullDownButton(
                        itemBuilder: (context) => widget.pullDownMenuItems!(),
                        buttonBuilder: (context, showMenu) => GestureDetector(
                          onTap: showMenu,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.viewLabel ?? 'DISCOVER',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'GoogleSansFlex',
                                      fontVariations: const [
                                        FontVariation('wght', 900),
                                        FontVariation('opsz', 12),
                                      ],
                                      color: AppTheme.textDark,
                                      letterSpacing: -0.8,
                                      height: 1.1,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                CupertinoIcons.chevron_down,
                                size: 18,
                                color: AppTheme.textDark,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Text(
                        'DISCOVER',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontFamily: 'GoogleSansFlex',
                              color: AppTheme.textDark,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                      ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      title: null,
    );
  }

  Widget _buildStatsRow(List<Moment> moments) {
    final locations = moments
        .map((m) => m.location.split(',').first.trim())
        .toSet();
    final photoCount = moments.where((m) => m.mediaType != 'video').length;
    final videoCount = moments.where((m) => m.mediaType == 'video').length;

    return Row(
      children: [
        _buildStatChip(
          icon: CupertinoIcons.photo_on_rectangle,
          value: '$photoCount',
          label: 'photos',
        ),
        const SizedBox(width: 10),
        if (videoCount > 0) ...[
          _buildStatChip(
            icon: CupertinoIcons.videocam,
            value: '$videoCount',
            label: 'videos',
          ),
          const SizedBox(width: 10),
        ],
        _buildStatChip(
          icon: CupertinoIcons.location,
          value: '${locations.length}',
          label: 'places',
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGray.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.primaryBlue),
          const SizedBox(width: 5),
          Text(
            '$value $label',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Weekly Recap Card ──────────────────────────────────────────

  Widget _buildWeeklyRecapCard(List<Moment> moments) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekMoments = moments
        .where((m) => m.createdAt.isAfter(weekStart))
        .toList();
    final weekLocations = thisWeekMoments
        .map((m) => m.location.split(',').first.trim())
        .toSet();

    if (thisWeekMoments.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue.withValues(alpha: 0.08),
              AppTheme.dustyRose.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THIS WEEK',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppTheme.primaryBlue.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'You captured ',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textDark,
                      height: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: '${thisWeekMoments.length}',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryBlue,
                      height: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: thisWeekMoments.length == 1 ? ' moment' : ' moments',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textDark,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (weekLocations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.location_solid,
                    size: 12,
                    color: AppTheme.textGray,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Across ${weekLocations.length} '
                      '${weekLocations.length == 1 ? 'place' : 'places'}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Mini preview strip of this week's moments
            if (thisWeekMoments.length > 1) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: thisWeekMoments.take(6).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final m = thisWeekMoments[index];
                    return GestureDetector(
                      onTap: () => _openMomentGroup(m),
                      child: Container(
                        width: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildMomentImage(m, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Filter Tabs ────────────────────────────────────────────────

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filterLabels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final isActive = index == _activeFilter;
            return GestureDetector(
              onTap: () {
                HapticService.lightTap();
                setState(() => _activeFilter = index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryBlue : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : AppTheme.borderGray.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _filterLabels[index],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppTheme.textGray,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Apply the current filter to a list of moments
  List<Moment> _applyFilter(List<Moment> moments) {
    switch (_activeFilter) {
      case 1: // Photos
        return moments.where((m) => m.mediaType != 'video').toList();
      case 2: // Videos
        return moments.where((m) => m.mediaType == 'video').toList();
      case 3: // Audio
        return moments.where((m) => m.audioPath != null).toList();
      default: // All
        return moments;
    }
  }

  // ─── Throwback Card ──────────────────────────────────────────────

  Widget _buildThrowbackCard(List<Moment> moments) {
    // Find moments from more than 7 days ago
    final now = DateTime.now();
    final oldMoments = moments
        .where((m) => now.difference(m.createdAt).inDays >= 7)
        .toList();
    if (oldMoments.isEmpty) return const SizedBox.shrink();

    // Rotate daily: pick a different throwback each day using day-of-year
    // as a seed into the old moments list. This gives variety without
    // needing server state.
    oldMoments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final throwback = oldMoments[dayOfYear % oldMoments.length];
    final daysAgo = now.difference(throwback.createdAt).inDays;
    final location = throwback.location.split(',').first.trim();
    final timeLabel = daysAgo >= 365
        ? '${(daysAgo / 365).floor()} year${(daysAgo / 365).floor() > 1 ? 's' : ''} ago'
        : daysAgo >= 30
        ? '${(daysAgo / 30).floor()} month${(daysAgo / 30).floor() > 1 ? 's' : ''} ago'
        : '$daysAgo days ago';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: GestureDetector(
        onTap: () => _openMomentGroup(throwback),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Thumbnail
              SizedBox(
                width: 120,
                child: _buildMomentImage(throwback, fit: BoxFit.cover),
              ),
              // Text content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.sunsetOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '✨ THROWBACK',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppTheme.sunsetOrange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        throwback.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.time,
                            size: 11,
                            color: AppTheme.textGray,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            timeLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textGray,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            CupertinoIcons.location_solid,
                            size: 10,
                            color: AppTheme.textGray,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Top Destinations Strip ─────────────────────────────────────

  Widget _buildTopDestinations(List<Moment> moments) {
    // Group by location and sort by count
    final locationMap = <String, List<Moment>>{};
    for (final m in moments) {
      final loc = m.location.split(',').first.trim();
      locationMap.putIfAbsent(loc, () => []).add(m);
    }
    final sortedLocations = locationMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    // Take top 5 locations
    final topLocations = sortedLocations.take(5).toList();
    if (topLocations.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Top Destinations'),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: topLocations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = topLocations[index];
              final locName = entry.key;
              final locMoments = entry.value;
              locMoments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final cover = locMoments.first;
              final count = locMoments.length;

              return GestureDetector(
                onTap: () => _onMomentGroupTapped(locMoments),
                child: Container(
                  width: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMomentImage(cover, fit: BoxFit.cover),
                      // Scrim
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.4, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Rank badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: index == 0
                                ? AppTheme.sunsetOrange
                                : Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: index == 0
                                    ? Colors.white
                                    : AppTheme.textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Info
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              locName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$count moment${count == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Moments Together (Collaborative) ───────────────────────────

  Widget _buildMomentsTogetherSection(List<Moment> moments) {
    // Find moments that have contributors (collaborative)
    final userMap = <String, List<Moment>>{};
    final currentUserId = _authService.currentUser?.id;
    for (final m in moments) {
      final uid = m.userId ?? 'unknown';
      if (uid != currentUserId) {
        userMap.putIfAbsent(uid, () => []).add(m);
      }
    }

    if (userMap.isEmpty) return const SizedBox.shrink();

    final friends = ref.watch(friendsListProvider).value ?? [];
    final avatarService = ref.watch(avatarCacheServiceProvider);

    // Get friend entries with their moments — up to 4 friends
    final friendEntries = userMap.entries.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Moments Together'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar stack row
                Row(
                  children: [
                    // Overlapping avatar stack
                    SizedBox(
                      height: 40,
                      width: 24.0 * friendEntries.length + 16,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: friendEntries.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final userId = entry.value.key;
                          final avatarUrl = avatarService.getAvatarUrlSync(
                            userId,
                          );
                          final friend = friends
                              .where((f) => f.id == userId)
                              .firstOrNull;
                          final name =
                              friend?.displayName ?? friend?.username ?? '?';

                          return Positioned(
                            left: idx * 24.0,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.primaryBlue
                                    .withValues(alpha: 0.15),
                                foregroundImage: avatarService
                                    .getAvatarImageProvider(avatarUrl),
                                child: avatarUrl == null
                                    ? _avatarFallback(name)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${userMap.values.fold<int>(0, (sum, list) => sum + list.length)} shared moments',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'with ${userMap.length} '
                            '${userMap.length == 1 ? 'friend' : 'friends'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: AppTheme.textGray.withValues(alpha: 0.4),
                    ),
                  ],
                ),
                // Mini thumbnails row
                const SizedBox(height: 14),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: userMap.values
                        .expand((list) => list)
                        .take(8)
                        .length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final allFriendMoments =
                          userMap.values.expand((list) => list).toList()..sort(
                            (a, b) => b.createdAt.compareTo(a.createdAt),
                          );
                      final m = allFriendMoments[index];
                      return GestureDetector(
                        onTap: () => _openMomentGroup(m),
                        child: Container(
                          width: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _buildMomentImage(m, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title, {
    bool showChevron = false,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 0.5,
            color: AppTheme.borderGray.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppTheme.textGray,
                ),
              ),
              if (showChevron) ...[
                const Spacer(),
                Text(
                  'See all',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 12,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }

  // ─── Featured hero card ─────────────────────────────────────────

  Widget _buildFeaturedCard(Moment moment) {
    final location = moment.location.split(',').first.trim();
    final timeAgo = _formatTimeAgo(moment.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => _openMomentGroup(moment),
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMomentImage(moment, fit: BoxFit.cover),
              // Gradient scrim
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),
              // Editorial text overlay
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LATEST',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      moment.title,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  Widget _buildRecentSection(
    List<Moment> moments, {
    required List<Moment> allMoments,
  }) {
    // Skip the first one (used in featured card)
    final recent = moments.skip(1).take(10).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Recent',
          showChevron: true,
          onTap: () => _navigateToAllMoments('Recent', allMoments),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _buildRecentCard(recent[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCard(Moment moment) {
    final location = moment.location.split(',').first.trim();

    return GestureDetector(
      onTap: () => _openMomentGroup(moment),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: _buildMomentImage(
                  moment,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moment.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 10,
                        color: AppTheme.textGray,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Friends / User groups ──────────────────────────────────────

  Widget _buildFriendsSection(List<Moment> moments) {
    // Group moments by userId
    final userMap = <String, List<Moment>>{};
    for (final m in moments) {
      final uid = m.userId ?? 'unknown';
      userMap.putIfAbsent(uid, () => []).add(m);
    }

    // Sort by most recent moment per user
    final sortedUsers = userMap.entries.toList()
      ..sort((a, b) {
        final aDate = a.value.first.createdAt;
        final bDate = b.value.first.createdAt;
        return bDate.compareTo(aDate);
      });

    if (sortedUsers.length <= 1) return const SizedBox.shrink();

    final friends = ref.watch(friendsListProvider).value ?? [];
    final avatarService = ref.watch(avatarCacheServiceProvider);
    final currentUserId = _authService.currentUser?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'By Friends',
          showChevron: true,
          onTap: () => _navigateToAllFriends(moments),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: sortedUsers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final entry = sortedUsers[index];
              final userId = entry.key;
              final userMoments = entry.value;
              final cover = userMoments.first;

              // Resolve name
              String displayName;
              if (userId == currentUserId) {
                displayName = 'You';
              } else {
                final friend = friends.where((f) => f.id == userId).firstOrNull;
                displayName =
                    friend?.displayName ?? friend?.username ?? 'Friend';
              }

              // Avatar URL
              final avatarUrl = avatarService.getAvatarUrlSync(userId);

              return GestureDetector(
                onTap: () => _onMomentGroupTapped(userMoments),
                child: SizedBox(
                  width: 140,
                  child: Column(
                    children: [
                      // Avatar (using CircleAvatar)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryBlue.withValues(
                            alpha: 0.15,
                          ),
                          foregroundImage: avatarService.getAvatarImageProvider(
                            avatarUrl,
                          ),
                          child: avatarUrl == null
                              ? _avatarFallback(displayName)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Name
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${userMoments.length} moment${userMoments.length == 1 ? '' : 's'}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textGray,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Cover thumbnail
                      Expanded(
                        child: Container(
                          width: 140,
                          decoration: ShapeDecoration(
                            shape: const RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            shadows: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildMomentImage(cover, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: AppTheme.primaryBlue.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }

  // ─── Location groups ────────────────────────────────────────────

  Widget _buildLocationGroupsHeader(List<Moment> moments) {
    return _buildSectionHeader(
      'By Location',
      showChevron: true,
      onTap: () => _navigateToAllLocations(moments),
    );
  }

  /// Groups moments by location (first part of address), then by momentGroupId
  /// within the same location, sorted by most recent first.
  SliverPadding _buildLocationGroups(List<Moment> moments) {
    // Group by location (first part of the comma-separated address)
    final locationMap = <String, List<Moment>>{};
    for (final m in moments) {
      final loc = m.location.split(',').first.trim();
      locationMap.putIfAbsent(loc, () => []).add(m);
    }

    // Sort locations by most recent moment in each group
    final sortedLocations = locationMap.entries.toList()
      ..sort((a, b) {
        final aDate = a.value
            .map((m) => m.createdAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        final bDate = b.value
            .map((m) => m.createdAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        return bDate.compareTo(aDate);
      });

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final entry = sortedLocations[index];
          return _buildLocationGroupCard(entry.key, entry.value);
        }, childCount: sortedLocations.length),
      ),
    );
  }

  Widget _buildLocationGroupCard(String locationName, List<Moment> moments) {
    moments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final cover = moments.first;
    final count = moments.length;

    return GestureDetector(
      onTap: () => _onMomentGroupTapped(moments),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMomentImage(cover, fit: BoxFit.cover),
            // Bottom scrim
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
            // Count badge
            if (count > 1)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            // Title + location
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cover.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 10,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          locationName,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Image helper ───────────────────────────────────────────────

  Widget _buildMomentImage(
    Moment moment, {
    BoxFit fit = BoxFit.cover,
    double? width,
  }) {
    final imageUrl = _getImageUrl(moment);
    final cacheKey = moment.mediaPath ?? moment.id;

    return OfflineImage(
      localPath: moment.localMediaPath,
      networkUrl: imageUrl,
      cacheKey: cacheKey,
      fit: fit,
      width: width,
      errorWidget: _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppTheme.borderGray.withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          color: AppTheme.textGray.withValues(alpha: 0.4),
          size: 28,
        ),
      ),
    );
  }

  // ─── Navigation ─────────────────────────────────────────────────

  void _openMomentGroup(Moment moment) {
    _onMomentGroupTapped([moment]);
  }

  void _onMomentGroupTapped(List<Moment> moments) {
    HapticService.mediumTap();
    final placeName = moments.first.location.split(',').first.trim();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MomentDetailsPage(
          locationName: placeName,
          moments: moments,
          heroTag: null,
          initialPage: 0,
        ),
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
      ),
    );
  }

  void _navigateToAllMoments(String title, List<Moment> moments) {
    HapticService.mediumTap();
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => AllMomentsPage(title: title, moments: moments),
      ),
    );
  }

  void _navigateToAllFriends(List<Moment> moments) {
    HapticService.mediumTap();
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => AllFriendsPage(moments: moments)),
    );
  }

  void _navigateToAllLocations(List<Moment> moments) {
    HapticService.mediumTap();
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (_) => AllLocationsPage(moments: moments)),
    );
  }

  // ─── States ─────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return const Center(child: CupertinoActivityIndicator(radius: 14));
  }

  Widget _buildEmptyState(String name) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.compass,
              size: 56,
              color: AppTheme.textGray.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No moments yet, $name',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Head to the map and capture your first moment!',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w400,
                color: AppTheme.textGray.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, String name) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.cloud_bolt, size: 48, color: AppTheme.textGray),
            const SizedBox(height: 16),
            Text(
              'Couldn\'t load moments',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textGray,
              ),
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: () => ref.invalidate(momentsStreamProvider),
              child: Text(
                'Try again',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final momentsAsync = ref.watch(momentsStreamProvider);
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final notificationCount = ref.watch(notificationCountProvider).value ?? 0;
    final displayName =
        userProfile?.displayName ?? _authService.currentUser?.email ?? 'You';
    final firstName = displayName.split(' ').first;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: SafeArea(
        top: true,
        child: momentsAsync.when(
          data: (moments) {
            final allMoments = List<Moment>.from(moments)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (allMoments.isEmpty) return _buildEmptyState(firstName);

            _resolveSignedUrls(allMoments);

            // Apply filter for Recent + Location grid sections
            final filteredMoments = _applyFilter(allMoments);

            return RefreshIndicator.adaptive(
              onRefresh: () async {
                HapticService.mediumTap();
                ref.invalidate(momentsStreamProvider);
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: AppTheme.coralPink,
              child: CustomScrollView(
                controller: widget.scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ── Greeting SliverAppBar ──
                  _buildGreetingSliverAppBar(
                    firstName,
                    userProfile?.avatarUrl,
                    notificationCount,
                  ),

                  // ── Featured hero card ──
                  SliverToBoxAdapter(
                    child: _buildFeaturedCard(allMoments.first),
                  ),

                  // ── Weekly recap card ──
                  SliverToBoxAdapter(child: _buildWeeklyRecapCard(allMoments)),

                  // ── Filter tabs ──
                  SliverToBoxAdapter(child: _buildFilterTabs()),

                  // ── Stats row ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildStatsRow(filteredMoments),
                    ),
                  ),

                  // ── Recent moments (horizontal) ──
                  SliverToBoxAdapter(
                    child: _buildRecentSection(
                      filteredMoments,
                      allMoments: allMoments,
                    ),
                  ),

                  // ── Moments Together (collaborative) ──
                  SliverToBoxAdapter(
                    child: _buildMomentsTogetherSection(allMoments),
                  ),

                  // ── Throwback card ──
                  SliverToBoxAdapter(child: _buildThrowbackCard(allMoments)),

                  // ── Top Destinations ──
                  SliverToBoxAdapter(child: _buildTopDestinations(allMoments)),

                  // ── By Friends (horizontal) ──
                  SliverToBoxAdapter(
                    child: _buildFriendsSection(filteredMoments),
                  ),

                  // ── Location groups header ──
                  SliverToBoxAdapter(
                    child: _buildLocationGroupsHeader(filteredMoments),
                  ),

                  // ── Location groups grid ──
                  _buildLocationGroups(filteredMoments),
                  // Bottom spacing for floating bar
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            );
          },
          loading: () => _buildLoadingState(),
          error: (e, _) => _buildErrorState(e, firstName),
        ),
      ),
    );
  }
}
