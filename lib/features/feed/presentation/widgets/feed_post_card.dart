import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/widgets/time_ago_text.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/core/services/signed_url_cache.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/data/services/user_profile_service.dart';
import 'package:moments/widgets/heart_animation.dart';
import 'package:moments/features/moments/presentation/moment_details_page.dart';

/// Instagram-style post card for the feed
/// Supports single moments or grouped moments (carousel)
class FeedPostCard extends ConsumerStatefulWidget {
  const FeedPostCard({
    super.key,
    required this.moments,
    this.onLocationTap,
  });

  /// List of moments to display (single or group)
  final List<Moment> moments;
  final VoidCallback? onLocationTap;

  @override
  ConsumerState<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends ConsumerState<FeedPostCard> {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _showHeartAnimation = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  // Image data: momentId -> (localPath, networkUrl)
  final Map<String, (String?, String?)> _imageData = {};
  String? _userAvatarUrl;
  String? _userName;

  Moment get _primaryMoment => widget.moments.first;
  bool get _isCarousel => widget.moments.length > 1;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _loadUserInfo();
    _loadReactionState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    final storageService = ref.read(momentStorageServiceProvider);

    for (final moment in widget.moments) {
      if (moment.mediaPath == null) continue;

      try {
        // Try local path first
        final localPath = await storageService.getLocalMediaPath(moment.id);

        if (localPath != null && await File(localPath).exists()) {
          if (mounted) {
            setState(() {
              _imageData[moment.id] = (localPath, null);
            });
          }
          continue;
        }

        // Fallback to signed URL
        final url = await SignedUrlCache.getSignedUrl(moment.mediaPath!);
        if (mounted && url != null) {
          setState(() {
            _imageData[moment.id] = (null, url);
          });

          // Cache in background for next time
          storageService.cacheMedia(moment.id, url);
        }
      } catch (e) {
        debugPrint('Error loading image for ${moment.id}: $e');
      }
    }
  }

  Future<void> _loadUserInfo() async {
    if (_primaryMoment.userId != null) {
      try {
        final profile =
            await UserProfileService.getUserProfile(_primaryMoment.userId!);

        if (profile != null && mounted) {
          setState(() {
            _userName = profile.displayName ?? profile.username;
            _userAvatarUrl = profile.avatarUrl;
          });
        }
      } catch (e) {
        debugPrint('Error loading user info: $e');
      }
    }
  }

  Future<void> _loadReactionState() async {
    // Load reaction count and user's reaction state
    if (mounted) {
      setState(() {
        _likeCount = 0;
        _isLiked = false;
      });
    }
  }

  void _handleDoubleTap() {
    if (!_isLiked) {
      _toggleLike();
    }
    setState(() => _showHeartAnimation = true);
    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showHeartAnimation = false);
      }
    });
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    HapticFeedback.lightImpact();
    // TODO: Persist reaction to Supabase
  }

  void _openMomentDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MomentDetailsPage(
          locationName: _primaryMoment.location,
          moments: widget.moments,
          initialPage: _currentImageIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundBeige,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildImageCarousel(),
          _buildActions(),
          _buildLikeCount(),
          _buildCaption(),
          _buildTimestamp(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              // TODO: Navigate to profile
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: _userAvatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _userAvatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Username and location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                if (_primaryMoment.location.isNotEmpty)
                  GestureDetector(
                    onTap: widget.onLocationTap,
                    child: Text(
                      _primaryMoment.location,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // More options
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(
              Icons.more_horiz,
              color: AppTheme.textDark,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return GestureDetector(
      onTap: _openMomentDetails,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1, // Square like Instagram
            child: _isCarousel
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: widget.moments.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildImageContent(widget.moments[index]);
                    },
                  )
                : _buildImageContent(_primaryMoment),
          ),

          // Heart animation overlay
          if (_showHeartAnimation)
            const HeartAnimation(
              size: 100,
              isLike: true,
            ),

          // Page indicator for carousel
          if (_isCarousel)
            Positioned(
              bottom: 12,
              child: _buildPageIndicator(),
            ),

          // Image counter for carousel
          if (_isCarousel)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${widget.moments.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.moments.length, (index) {
        final isActive = index == _currentImageIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppTheme.primaryBlue
                : Colors.white.withValues(alpha: 0.6),
          ),
        );
      }),
    );
  }

  Widget _buildImageContent(Moment moment) {
    final data = _imageData[moment.id];
    final localPath = data?.$1;
    final networkUrl = data?.$2;

    // Try local file first
    if (localPath != null) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    // Fallback to network image
    if (networkUrl != null) {
      return CachedNetworkImage(
        imageUrl: networkUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    // Loading state
    return _buildLoadingPlaceholder();
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Like button
          GestureDetector(
            onTap: _toggleLike,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                key: ValueKey(_isLiked),
                _isLiked ? Icons.favorite : Icons.favorite_outline,
                color: _isLiked ? Colors.red : AppTheme.textDark,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Comment button
          GestureDetector(
            onTap: _openMomentDetails,
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppTheme.textDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Share button
          GestureDetector(
            onTap: () {
              // TODO: Share functionality
            },
            child: const Icon(
              Icons.send_outlined,
              color: AppTheme.textDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Map button - navigate to location
          GestureDetector(
            onTap: widget.onLocationTap,
            child: const Icon(
              Icons.location_on_outlined,
              color: AppTheme.textDark,
              size: 26,
            ),
          ),

          const Spacer(),

          // Bookmark button
          GestureDetector(
            onTap: () {
              // TODO: Bookmark functionality
            },
            child: const Icon(
              Icons.bookmark_outline,
              color: AppTheme.textDark,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeCount() {
    if (_likeCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        _likeCount == 1 ? '1 like' : '$_likeCount likes',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildCaption() {
    final caption = _primaryMoment.caption ?? _primaryMoment.description;
    if (caption == null || caption.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textDark,
          ),
          children: [
            TextSpan(
              text: '${_userName ?? 'Unknown'} ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: caption),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TimeAgoText(
        dateTime: _primaryMoment.timestamp,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textGray,
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Share
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy link'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Copy link
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('View on map'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onLocationTap?.call();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
