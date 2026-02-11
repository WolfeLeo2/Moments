import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/moment.dart';
import '../../../widgets/offline_image.dart';
import '../../moments/presentation/moment_details_page.dart';

/// Discovery page — browse all moments from the user and friends.
///
/// Sections:
/// - Greeting header with stats
/// - Recent moments horizontal strip
/// - Location-based moment groups (2-column grid)
class DiscoveryPage extends ConsumerStatefulWidget {
  const DiscoveryPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage>
    with AutomaticKeepAliveClientMixin {
  final AuthService _authService = AuthService();

  /// Resolved signed URLs: mediaPath → signedUrl
  final Map<String, String> _signedUrls = {};

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

  // ─── Greeting ───────────────────────────────────────────────────

  Widget _buildGreetingHeader(String firstName, List<Moment> moments) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textGray,
                      ),
                    ),
                    Text(
                      firstName,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              _buildUserAvatar(),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatsRow(moments),
        ],
      ),
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

  Widget _buildUserAvatar() {
    final avatarUrl = _authService.currentUserPhotoUrl;
    final avatarService = ref.watch(avatarCacheServiceProvider);
    return Container(
      width: 44,
      height: 44,
      decoration: ShapeDecoration(
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        color: AppTheme.primaryBlue.withValues(alpha: 0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null
          ? Image(
              image:
                  avatarService.getAvatarImageProvider(avatarUrl) ??
                  const AssetImage('assets/images/default_avatar.png'),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                CupertinoIcons.person_fill,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            )
          : Icon(
              CupertinoIcons.person_fill,
              color: AppTheme.primaryBlue,
              size: 24,
            ),
    );
  }

  // ─── Recent moments ─────────────────────────────────────────────

  Widget _buildRecentSection(List<Moment> moments) {
    final recent = moments.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Text(
                'Recent Moments',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: AppTheme.textGray,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
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
        width: 155,
        decoration: ShapeDecoration(
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          color: Colors.white,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMomentImage(
                moment,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moment.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 10,
                        color: AppTheme.primaryBlue,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'By Friends',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
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

  Widget _buildLocationGroupsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Text(
        'By Location',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
        ),
      ),
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
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final entry = sortedLocations[index];
          return _buildLocationGroupCard(entry.key, entry.value);
        }, childCount: sortedLocations.length),
      ),
    );
  }

  Widget _buildLocationGroupCard(String locationName, List<Moment> moments) {
    // Sort newest first, pick the cover
    moments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final cover = moments.first;
    final count = moments.length;

    return GestureDetector(
      onTap: () => _onMomentGroupTapped(moments),
      child: Container(
        decoration: ShapeDecoration(
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          color: Colors.white,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
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
              height: 70,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),

            // Count badge
            if (count > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: ShapeDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: const RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
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

            // Location name
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cover.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 10,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          locationName,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
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

    if (imageUrl == null || imageUrl.isEmpty) return _imagePlaceholder();

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
    final displayName =
        userProfile?.displayName ?? _authService.currentUser?.email ?? 'You';
    final firstName = displayName.split(' ').first;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: SafeArea(
        child: momentsAsync.when(
          data: (moments) {
            // All visible moments (user's own + friends' public).
            // momentsStreamProvider already respects RLS.
            final allMoments = List<Moment>.from(moments)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (allMoments.isEmpty) return _buildEmptyState(firstName);

            // Resolve signed URLs for moments without imageUrl
            _resolveSignedUrls(allMoments);

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
                  // --Build greetings section--
                  SliverToBoxAdapter(
                    child: _buildGreetingHeader(firstName, allMoments),
                  ),
                  // ── Recent moments (horizontal) ──
                  SliverToBoxAdapter(child: _buildRecentSection(allMoments)),

                  // ── By Friends (horizontal) ──
                  SliverToBoxAdapter(child: _buildFriendsSection(allMoments)),

                  // ── Location groups header ──
                  SliverToBoxAdapter(child: _buildLocationGroupsHeader()),

                  // ── Location groups grid ──
                  _buildLocationGroups(allMoments),

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
