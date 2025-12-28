import 'package:flutter/material.dart';
import 'package:avatar_stack/avatar_stack.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/services/haptic_service.dart';
import 'package:moments/core/services/avatar_cache_service.dart';
import 'package:moments/data/repositories/moment_repository.dart';
import 'package:moments/widgets/heart_animation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../data/models/moment.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../core/services/moment_storage_service.dart';
import '../../../widgets/offline_image.dart';

/// Stacked card marker showing up to 5 moments with unique rotations
class StackedMomentMarker extends StatefulWidget {
  final List<Moment> moments;
  final VoidCallback onTap;
  final String? heroTag; // Hero tag for the front card only

  const StackedMomentMarker({
    super.key,
    required this.moments,
    required this.onTap,
    this.heroTag,
  });

  @override
  State<StackedMomentMarker> createState() => _StackedMomentMarkerState();
}

class _StackedMomentMarkerState extends State<StackedMomentMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  final Map<String, String> _imageUrls = {};
  final Map<String, String> _localPaths = {}; // Local cached paths
  final Map<String, String> _userAvatars = {}; // User ID -> avatar URL
  bool _isPressed = false;
  final MomentStorageService _storage = MomentStorageService();
  final AvatarCacheService _avatarCache = AvatarCacheService();
  final MomentRepository _momentRepo = MomentRepository();

  // Track which moments we've loaded to avoid redundant loads
  Set<String> _loadedMomentIds = {};
  bool _isLoading = false;

  // Reactions state (simplified - just total count)
  int _reactionCount = 0;
  String? _userReaction;
  bool _showingHeartAnimation = false;
  bool _isLikeAnimation = true; // true = like, false = dislike

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _loadImages();
    _loadUserAvatars();
    _loadReactions();
  }

  @override
  void didUpdateWidget(StackedMomentMarker oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if moments have changed
    final newIds = widget.moments.take(4).map((m) => m.id).toSet();
    final oldIds = oldWidget.moments.take(4).map((m) => m.id).toSet();

    // Only reload if the moment IDs have actually changed
    if (!newIds.difference(oldIds).isEmpty ||
        !oldIds.difference(newIds).isEmpty) {
      // Clear data for moments that are no longer displayed
      final removedIds = oldIds.difference(newIds);
      for (final id in removedIds) {
        _imageUrls.remove(id);
        _localPaths.remove(id);
        _loadedMomentIds.remove(id);
      }

      // Load new moments that we haven't loaded yet
      _loadImages();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    // Prevent concurrent loads
    if (_isLoading) return;
    _isLoading = true;

    try {
      // First, check for locally cached images (only for moments not already loaded)
      final newLocalPaths = <String, String>{};

      for (var moment in widget.moments.take(4)) {
        // Skip if we already have this moment's local path
        if (_localPaths.containsKey(moment.id)) continue;
        if (_loadedMomentIds.contains(moment.id)) continue;

        final isThumbnail = moment.mediaType == 'video';
        final localPath = await _storage.getLocalMediaPath(
          moment.id,
          isThumbnail: isThumbnail,
        );

        if (localPath != null) {
          newLocalPaths[moment.id] = localPath;
        }

        _loadedMomentIds.add(moment.id);
      }

      // Batch update all local paths in a single setState
      if (newLocalPaths.isNotEmpty && mounted) {
        setState(() {
          _localPaths.addAll(newLocalPaths);
        });
      }

      // Then load network URLs (for fallback and caching)
      await _loadNetworkUrls();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadNetworkUrls() async {
    // Collect paths to load - use thumbnails for videos, media_path for images
    // Skip moments that already have URLs or local paths
    final pathsToLoad = <String>[];

    for (var moment in widget.moments.take(4)) {
      // Skip if we already have a URL or local path for this moment
      if (_imageUrls.containsKey(moment.id) ||
          _localPaths.containsKey(moment.id)) {
        continue;
      }

      // For videos, only load thumbnail
      if (moment.mediaType == 'video') {
        if (moment.thumbnailPath != null && moment.thumbnailPath!.isNotEmpty) {
          pathsToLoad.add(moment.thumbnailPath!);
        }
      } else {
        // For images, load the media path
        if (moment.mediaPath != null && moment.mediaPath!.isNotEmpty) {
          pathsToLoad.add(moment.mediaPath!);
        }
      }
    }

    if (pathsToLoad.isEmpty) return;

    try {
      final urls = await SignedUrlCache.getSignedUrlsBatch(pathsToLoad);

      if (mounted) {
        setState(() {
          for (var moment in widget.moments.take(4)) {
            // Skip if we have local path (prefer offline) or already have URL
            if (_localPaths.containsKey(moment.id)) continue;
            if (_imageUrls.containsKey(moment.id)) continue;

            if (moment.mediaType == 'video') {
              // For videos, use thumbnail URL
              if (moment.thumbnailPath != null) {
                final thumbUrl = urls[moment.thumbnailPath];
                if (thumbUrl != null) {
                  _imageUrls[moment.id] = thumbUrl;
                }
              }
            } else {
              // For images, use media URL
              if (moment.mediaPath != null) {
                final url = urls[moment.mediaPath];
                if (url != null) {
                  _imageUrls[moment.id] = url;
                }
              }
            }
          }
        });

        // Cache images to local storage in background
        _cacheImagesInBackground(urls);
      }
    } catch (e) {
      debugPrint('Error loading network URLs: $e');
    }
  }

  Future<void> _cacheImagesInBackground(Map<String, String> urls) async {
    final newLocalPaths = <String, String>{};

    for (var moment in widget.moments.take(4)) {
      // Skip if already cached locally
      if (_localPaths.containsKey(moment.id)) continue;

      final url = _imageUrls[moment.id];
      if (url == null) continue;

      final isThumbnail = moment.mediaType == 'video';
      final localPath = await _storage.cacheMedia(
        moment.id,
        url,
        isThumbnail: isThumbnail,
      );

      if (localPath != null) {
        newLocalPaths[moment.id] = localPath;
      }
    }

    // Batch update all local paths in a single setState
    if (newLocalPaths.isNotEmpty && mounted) {
      setState(() {
        _localPaths.addAll(newLocalPaths);
      });
    }
  }

  Future<void> _loadUserAvatars() async {
    // Get unique user IDs
    final userIds = widget.moments
        .where((m) => m.userId != null)
        .map((m) => m.userId!)
        .toSet()
        .toList();

    if (userIds.isEmpty) return;

    // First, immediately populate from cache (sync - no network, no delay)
    final cachedAvatars = _avatarCache.getAvatarUrlsSync(userIds);
    if (cachedAvatars.isNotEmpty && mounted) {
      setState(() {
        _userAvatars.addAll(cachedAvatars);
      });
    }

    // Then fetch any missing avatars asynchronously
    final missingIds = userIds
        .where((id) => !_userAvatars.containsKey(id))
        .toList();
    if (missingIds.isEmpty) return;

    try {
      final fetchedAvatars = await _avatarCache.getAvatarUrls(missingIds);

      if (mounted && fetchedAvatars.isNotEmpty) {
        setState(() {
          _userAvatars.addAll(fetchedAvatars);
        });
      }
    } catch (e) {
      debugPrint('Error loading user avatars: $e');
    }
  }

  Future<void> _loadReactions() async {
    if (widget.moments.isEmpty) return;

    // Load reactions for the front moment (most visible)
    final frontMoment = widget.moments.first;

    try {
      final summaries = await _momentRepo.getReactionSummary(frontMoment.id);
      final userReaction = await _momentRepo.getUserReaction(frontMoment.id);

      if (mounted) {
        // Calculate total count from all emoji summaries
        final totalCount = summaries.fold<int>(0, (sum, s) => sum + s.count);
        setState(() {
          _reactionCount = totalCount;
          _userReaction = userReaction?.emoji;
        });
      }
    } catch (e) {
      debugPrint('Error loading reactions: $e');
    }
  }

  Future<void> _toggleHeart() async {
    if (widget.moments.isEmpty) return;

    final frontMoment = widget.moments.first;
    const heartEmoji = '❤️';

    // Determine if this is a like or unlike action
    final isUnliking = _userReaction == heartEmoji;

    // Show appropriate animation immediately for responsiveness
    setState(() {
      _showingHeartAnimation = true;
      _isLikeAnimation =
          !isUnliking; // like animation if adding, dislike if removing
    });
    HapticService.mediumTap();

    // Hide animation after delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showingHeartAnimation = false;
        });
      }
    });

    try {
      if (isUnliking) {
        // Remove heart
        await _momentRepo.removeReaction(frontMoment.id);
        setState(() {
          _userReaction = null;
          _reactionCount = (_reactionCount - 1).clamp(0, 999);
        });
      } else {
        // Add heart
        await _momentRepo.addReaction(frontMoment.id, heartEmoji);
        final wasNewReaction = _userReaction == null;
        setState(() {
          _userReaction = heartEmoji;
          if (wasNewReaction) {
            _reactionCount++;
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling heart: $e');
    }
  }

  // Generate unique rotation based on moment ID
  double _getRotation(int index, String momentId) {
    final seed = momentId.hashCode;
    final random = math.Random(seed + index);

    switch (index) {
      case 0: // Back card
        return -12 + random.nextDouble() * 8; // -12 to -4 degrees
      case 1: // Middle-back card
        return -2 + random.nextDouble() * 10; // -2 to 8 degrees
      case 2: // Middle card
        return -4 + random.nextDouble() * 7; // -4 to 3 degrees
      case 3: // Middle-front card
        return -3 + random.nextDouble() * 6; // -3 to 3 degrees
      case 4: // Front card
        return -2 + random.nextDouble() * 4; // -2 to 2 degrees
      default:
        return 0;
    }
  }

  Offset _getOffset(int index, String momentId) {
    final seed = momentId.hashCode;
    final random = math.Random(seed + index);

    switch (index) {
      case 0: // Back card
        return Offset(
          -8 + random.nextDouble() * 6, // x: -8 to -2
          10 + random.nextDouble() * 5, // y: 10 to 15
        );
      case 1: // Middle-back card
        return Offset(
          -1 + random.nextDouble() * 7, // x: -1 to 6
          6 + random.nextDouble() * 4, // y: 6 to 10
        );
      case 2: // Middle card
        return Offset(
          -2 + random.nextDouble() * 4, // x: -2 to 2
          3 + random.nextDouble() * 3, // y: 3 to 6
        );
      case 3: // Middle-front card
        return Offset(
          -1 + random.nextDouble() * 2, // x: -1 to 1
          1 + random.nextDouble() * 2, // y: 1 to 3
        );
      case 4: // Front card
        return const Offset(0, 0);
      default:
        return Offset.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayMoments = widget.moments.take(5).toList().reversed.toList();

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _pressController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _pressController.reverse();
        HapticService.mediumTap();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pressController.reverse();
      },
      onDoubleTap: () {
        // Double-tap to toggle heart
        _toggleHeart();
      },
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final scale = 1.0 - (_pressController.value * 0.05); // Scale to 0.95

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 120,
              height: 160,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Stacked cards (back to front)
                  for (var i = 0; i < displayMoments.length; i++)
                    _buildCard(
                      displayMoments[i],
                      i,
                      displayMoments.length -
                          1 -
                          i, // Reverse index for stacking
                      isFrontCard:
                          i ==
                          displayMoments.length -
                              1, // Last one rendered is front
                    ),

                  // Avatar stack and date badge on top
                  _buildFloatingBadges(),

                  // Title badge at bottom right
                  _buildTitleBadge(),

                  // Heart/Dislike animation overlay
                  if (_showingHeartAnimation)
                    Positioned.fill(
                      child: Center(
                        child: HeartAnimation(
                          size: 80,
                          isLike: _isLikeAnimation,
                        ),
                      ),
                    ),

                  // Compact reaction indicator (bottom left, inside card bounds)
                  // Only show count when > 1
                  if (_reactionCount > 1 ||
                      (_userReaction != null && _reactionCount <= 1))
                    Positioned(
                      bottom: -18,
                      left: -2,
                      child: Container(
                        padding: _reactionCount > 1
                            ? const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              )
                            : const EdgeInsets.all(5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _userReaction != null
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                              size: 24,
                            ),
                            if (_reactionCount > 1) ...[
                              const SizedBox(width: 3),
                              Text(
                                _reactionCount.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(
    Moment moment,
    int visualIndex,
    int stackIndex, {
    bool isFrontCard = false,
  }) {
    // Get local path first, fallback to network URL
    final localPath = _localPaths[moment.id];
    final imageUrl = _imageUrls[moment.id];
    final rotation = _getRotation(stackIndex, moment.id);
    final offset = _getOffset(stackIndex, moment.id);

    // Add extra shuffle rotation on press
    final pressRotation = _isPressed ? (stackIndex - 2) * 2.0 : 0.0;

    bool isVideo = moment.mediaType == 'video';
    bool hasImage = localPath != null || imageUrl != null;

    // Simple card for Hero compatibility - 3:4 aspect ratio
    Widget simpleCard = AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMomentCard),
          child: Stack(
            fit: StackFit.expand,
            children: [
              hasImage
                  ? OfflineImage(
                      localPath: localPath,
                      networkUrl: imageUrl,
                      cacheKey: moment.mediaPath,
                      fit: BoxFit.cover,
                      memCacheHeight: 600,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
              // Show play icon for videos
              if (isVideo)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Wrap ONLY the front card in Hero (no transforms inside Hero)
    if (isFrontCard && widget.heroTag != null) {
      return Positioned.fill(
        child: Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: (rotation + pressRotation) * math.pi / 180,
            child: Hero(tag: widget.heroTag!, child: simpleCard),
          ),
        ),
      );
    }

    // Other cards with transforms
    return Positioned.fill(
      child: Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: (rotation + pressRotation) * math.pi / 180,
          child: simpleCard,
        ),
      ),
    );
  }

  Widget _buildFloatingBadges() {
    // Get ALL unique contributors with avatars (for counting overflow)
    final allContributorsWithAvatars = widget.moments
        .where((m) => m.userId != null && _userAvatars.containsKey(m.userId))
        .map((m) => m.userId!)
        .toSet()
        .toList();

    // Only display first 3 avatars
    final displayAvatars = allContributorsWithAvatars.take(3).toList();
    final overflowCount = allContributorsWithAvatars.length > 3
        ? allContributorsWithAvatars.length - 3
        : 0;

    // Calculate date range
    final dates = widget.moments.map((m) => m.timestamp).toList()..sort();
    final firstDate = dates.first;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // College-style date sticker on top-left
        Positioned(
          top: -8,
          left: -12,
          child: _buildCollegeDateSticker(firstDate),
        ),

        // Avatar stack on top-right
        if (displayAvatars.isNotEmpty)
          Positioned(
            top: -8,
            right: -35,
            child: SizedBox(
              width: 80,
              height: 36,
              child: AvatarStack(
                height: 36,
                avatars: displayAvatars
                    .map((id) => CachedNetworkImageProvider(_userAvatars[id]!))
                    .toList(),
                borderColor: Colors.white,
                borderWidth: 2,
                infoWidgetBuilder: overflowCount > 0
                    ? (surplus, _) => CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.black87,
                        child: Text(
                          '+$overflowCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  /// Build a calendar-style date sticker (red top with month, white bottom with day)
  Widget _buildCollegeDateSticker(DateTime date) {
    final month = _getMonthAbbr(date.month);
    final day = date.day.toString();

    return Transform.rotate(
      angle: 0.08, // Slight tilt for that casual sticker look
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          width: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderBlack, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top red part with month
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935), // Red
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  month,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Bottom white part with day
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bangers(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.borderBlack,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      '',
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month];
  }

  Widget _buildTitleBadge() {
    if (widget.moments.isEmpty) return const SizedBox.shrink();
    final title = widget.moments.first.title;
    if (title.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      right: -10,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.bebasNeue(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
