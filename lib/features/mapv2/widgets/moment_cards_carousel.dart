import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../widgets/offline_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/moment.dart';

final _log = AppLogger('MomentCardsCarousel');

/// Viewport-aware bottom carousel showing moment groups as cards.
///
/// Each card shows:
/// - Hero image (top moment's first photo)
/// - Badge with moment count (top-right)
/// - Contributor avatar stack (top-left)
/// - Group title + date range (bottom-left)
/// - Sub-location name (bottom-right)
class MomentCardsCarousel extends ConsumerStatefulWidget {
  const MomentCardsCarousel({
    super.key,
    required this.groups,
    required this.selectedIndex,
    required this.onCardTapped,
    required this.onCardChanged,
  });

  /// Moment groups from [MapLogicService.groupMomentsByPlace].
  /// Each group: `{'placeName', 'moments', 'lat', 'lng', 'groupId', ...}`
  final List<Map<String, dynamic>> groups;
  final int selectedIndex;
  final void Function(Map<String, dynamic> group) onCardTapped;
  final void Function(int index) onCardChanged;

  @override
  ConsumerState<MomentCardsCarousel> createState() =>
      _MomentCardsCarouselState();
}

class _MomentCardsCarouselState extends ConsumerState<MomentCardsCarousel> {
  late PageController _pageController;
  final Map<String, String> _imageUrls = {};
  final Map<String, Map<String, String>> _avatarCache = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.78,
      initialPage: widget.selectedIndex,
    );
    _resolveImages();
  }

  @override
  void didUpdateWidget(MomentCardsCarousel old) {
    super.didUpdateWidget(old);
    if (old.groups != widget.groups) {
      _resolveImages();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Batch-resolve signed URLs for the hero images of each group.
  Future<void> _resolveImages() async {
    final paths = <String>[];
    for (final group in widget.groups) {
      final moments = group['moments'] as List<Moment>;
      if (moments.isEmpty) continue;
      final front = moments.first;
      // Skip if local file is available
      final localPath = front.mediaType == 'video'
          ? front.localThumbnailPath
          : front.localMediaPath;
      if (localPath != null && localPath.isNotEmpty) continue;
      final path = front.mediaType == 'video'
          ? front.thumbnailPath
          : front.mediaPath;
      if (path != null && path.isNotEmpty) paths.add(path);
    }

    if (paths.isEmpty) return;

    final urls = await SignedUrlCache.getSignedUrlsBatch(paths);
    if (mounted) setState(() => _imageUrls.addAll(urls));
  }

  String? _getHeroUrl(Map<String, dynamic> group) {
    final moments = group['moments'] as List<Moment>;
    if (moments.isEmpty) return null;
    final front = moments.first;
    final path = front.mediaType == 'video'
        ? front.thumbnailPath
        : front.mediaPath;
    if (path == null) return null;
    return _imageUrls[path];
  }

  // ─── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.groups.length,
        onPageChanged: (index) {
          HapticService.lightTap();
          widget.onCardChanged(index);
        },
        itemBuilder: (context, index) {
          return AnimatedScale(
            scale: index == widget.selectedIndex ? 1.0 : 0.92,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCirc,
            child: _buildCard(widget.groups[index]),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> group) {
    final moments = group['moments'] as List<Moment>;
    final placeName = group['placeName'] as String? ?? 'Unknown';
    final momentCount = moments.length;
    final heroUrl = _getHeroUrl(group);
    final heroMoment = moments.first;
    final title = moments.first.title;
    final dateRange = _formatDateRange(moments);
    // Sub-location: the specific place inside the broader city
    final subLocation = _extractSubLocation(moments.first.location);

    return GestureDetector(
      onTap: () {
        HapticService.mediumTap();
        widget.onCardTapped(group);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadiusGeometry.lerp(
              BorderRadius.circular(20),
              BorderRadius.circular(20),
              1.0,
            )!,
          ),
          /*shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],*/
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Hero image (OfflineImage with local-first + network fallback) ──
            if (heroUrl != null)
              OfflineImage(
                localPath: heroMoment.localMediaPath,
                networkUrl: heroUrl,
                cacheKey: heroMoment.mediaPath ?? heroMoment.id,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: AppTheme.borderGray.withValues(alpha: 0.3),
                  child: Icon(
                    CupertinoIcons.photo,
                    color: AppTheme.textGray,
                    size: 32,
                  ),
                ),
              )
            else
              Container(
                color: AppTheme.borderGray.withValues(alpha: 0.3),
                child: Icon(
                  CupertinoIcons.photo,
                  color: AppTheme.textGray,
                  size: 32,
                ),
              ),

            // ── Gradient scrim at bottom ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 90,
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

            // ── Contributor avatar stack (top-left) ──
            Positioned(top: 10, left: 10, child: _buildAvatarStack(moments)),

            // ── Moment count badge (top-right) ──
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.photo_on_rectangle,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$momentCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: 'GoogleSansFlex',
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Title + date (bottom-left) ──
            Positioned(
              left: 12,
              bottom: 12,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontFamily: 'GoogleSansFlex',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateRange,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontFamily: 'GoogleSansFlex',
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subLocation ?? '',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontFamily: 'GoogleSansFlex',
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Sub-location pill (bottom-right) ──
            /*if (subLocation != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: const RoundedSuperellipseBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 10,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 3),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 70),
                        child: Text(
                          subLocation,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),*/
          ],
        ),
      ),
    );
  }

  // ─── Avatar stack ───────────────────────────────────────────────

  Widget _buildAvatarStack(List<Moment> moments) {
    final userIds = moments
        .where((m) => m.userId != null)
        .map((m) => m.userId!)
        .toSet()
        .take(3)
        .toList();

    if (userIds.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 28,
      width: 28.0 + (userIds.length - 1) * 16.0,
      child: Stack(
        children: List.generate(userIds.length, (i) {
          return Positioned(
            left: i * 16.0,
            child: _buildMiniAvatar(userIds[i]),
          );
        }),
      ),
    );
  }

  Widget _buildMiniAvatar(String userId) {
    // Use avatar cache service for URL resolution
    final avatarCache = ref.read(avatarCacheServiceProvider);
    final avatarUrl = avatarCache.getAvatarUrlSync(userId);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image(
                image:
                    avatarCache.getAvatarImageProvider(avatarUrl) ??
                    const AssetImage('assets/images/default_avatar.png'),
                fit: BoxFit.cover,
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────

  String _formatDateRange(List<Moment> moments) {
    if (moments.isEmpty) return '';
    final dates = moments.map((m) => m.createdAt).toList()..sort();
    final first = dates.first;
    final last = dates.last;

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (first.year == last.year &&
        first.month == last.month &&
        first.day == last.day) {
      return '${months[first.month - 1]} ${first.day}, ${first.year}';
    }

    return '${months[first.month - 1]} ${first.day} – ${months[last.month - 1]} ${last.day}, ${last.year}';
  }

  /// Extract the sub-location (specific place) from a full location string.
  /// e.g. "Golden Gate Bridge, San Francisco, CA" → "Golden Gate Bridge"
  String? _extractSubLocation(String location) {
    final parts = location.split(',');
    if (parts.length > 1) {
      return parts.first.trim();
    }
    return null; // Only one part — don't show redundant info
  }
}
