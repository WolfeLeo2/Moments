import 'package:flutter/material.dart';
import 'package:avatar_stack/avatar_stack.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../data/models/moment.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../widgets/cached_image.dart';

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
  final Map<String, String> _userAvatars = {}; // User ID -> avatar URL
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _loadImageUrls();
    _loadUserAvatars();
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _loadImageUrls() async {
    final mediaPaths = widget.moments
        .take(4) // Only load first 5
        .map((m) => m.mediaPath)
        .where((path) => path != null && path.isNotEmpty)
        .cast<String>()
        .toList();

    if (mediaPaths.isEmpty) return;

    final urls = await SignedUrlCache.getSignedUrlsBatch(mediaPaths);

    if (mounted) {
      setState(() {
        for (var moment in widget.moments.take(4)) {
          if (moment.mediaPath != null) {
            final url = urls[moment.mediaPath];
            if (url != null) {
              _imageUrls[moment.id] = url;
            }
          }
        }
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

    try {
      // For each user, try to get their avatar from auth metadata
      final avatarMap = <String, String>{};

      for (final userId in userIds) {
        try {
          // Try to get user metadata from Supabase auth admin API
          // Note: This requires proper permissions. Alternative: create a profiles table
          final currentUser = Supabase.instance.client.auth.currentUser;
          if (currentUser != null && currentUser.id == userId) {
            final avatarUrl =
                currentUser.userMetadata?['avatar_url'] as String?;
            if (avatarUrl != null && avatarUrl.isNotEmpty) {
              avatarMap[userId] = avatarUrl;
            }
          }
        } catch (e) {
          // Skip if we can't get avatar for this user
          print('Could not load avatar for user $userId: $e');
        }
      }

      if (mounted && avatarMap.isNotEmpty) {
        setState(() {
          _userAvatars.addAll(avatarMap);
        });
      }
    } catch (e) {
      print('Error loading user avatars: $e');
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
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pressController.reverse();
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
    final imageUrl = _imageUrls[moment.id];
    final rotation = _getRotation(stackIndex, moment.id);
    final offset = _getOffset(stackIndex, moment.id);

    // Add extra shuffle rotation on press
    final pressRotation = _isPressed ? (stackIndex - 2) * 2.0 : 0.0;

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
          child: imageUrl != null
              ? CachedImage(
                  imageUrl: imageUrl,
                  cacheKey:
                      moment.mediaPath, // Use stable mediaPath as cache key
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
    // Get unique contributors with avatars
    final contributorsWithAvatars = widget.moments
        .where((m) => m.userId != null && _userAvatars.containsKey(m.userId))
        .map((m) => m.userId!)
        .toSet()
        .take(3)
        .toList();

    // Calculate date range
    final dates = widget.moments.map((m) => m.timestamp).toList()..sort();
    final firstDate = dates.first;
    final lastDate = dates.last;
    final dateLabel = _formatDateRange(firstDate, lastDate);

    return Positioned(
      top: -8,
      right: -8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar stack - only show if we have real avatars
          if (contributorsWithAvatars.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SizedBox(
                width: 32,
                height: 32,
                child: AvatarStack(
                  height: 32,
                  avatars: contributorsWithAvatars
                      .map(
                        (id) => CachedNetworkImageProvider(_userAvatars[id]!),
                      )
                      .toList(),
                  borderColor: Colors.white,
                  borderWidth: 1,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              dateLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBadge() {
    if (widget.moments.isEmpty) return const SizedBox.shrink();
    final title = widget.moments.first.title;
    if (title.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      right: -10,
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
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${start.day}/${start.month}';
    } else if (start.year == end.year && start.month == end.month) {
      return '${start.day}-${end.day}/${start.month}';
    } else {
      return '${start.day}/${start.month}-${end.day}/${end.month}';
    }
  }
}
