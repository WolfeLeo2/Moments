import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:motor/motor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/moment.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../core/services/moment_storage_service.dart';
import '../../../core/services/video_controller_manager.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/avatar_cache_service.dart';
import '../../../widgets/offline_image.dart';
import '../../../widgets/offline_video.dart';
import '../../../widgets/share_bottom_sheet.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/moments_providers.dart';
import 'dart:io';
import 'package:button_m3e/button_m3e.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Details page showing moments in a carousel with spring animations
class MomentDetailsPage extends ConsumerStatefulWidget {
  const MomentDetailsPage({
    super.key,
    required this.locationName,
    required this.moments,
    this.heroTag,
    this.initialPage = 0,
  });

  final String? heroTag;
  final int initialPage;
  final String locationName;
  final List<Moment> moments;

  @override
  ConsumerState<MomentDetailsPage> createState() => _MomentDetailsPageState();
}

class _MomentDetailsPageState extends ConsumerState<MomentDetailsPage>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  double _headerOpacity = 0.0;
  late SingleMotionController _headerOpacityController;
  double _headerScale = 0.85; // Match carousel initial scale
  // Motor spring controllers for header elements
  late SingleMotionController _headerScaleController;

  final Map<String, String> _imageUrls = {};
  bool _isUploading = false;
  final Map<String, String> _localPaths = {}; // Local cached paths for images
  final Map<String, String> _localVideoPaths =
      {}; // Local cached paths for videos

  final List<double> _opacities = [];
  final List<SingleMotionController> _opacityControllers = [];
  final ImagePicker _picker = ImagePicker();
  // Motor spring controllers for each card
  final List<SingleMotionController> _scaleControllers = [];

  final List<double> _scales = [];
  final MomentStorageService _storage = MomentStorageService();
  final AvatarCacheService _avatarCache = AvatarCacheService();
  final Map<String, String> _userAvatars = {}; // User ID -> avatar URL
  // Video controller manager for hybrid prewarm approach
  late final VideoControllerManager _videoManager;

  @override
  void dispose() {
    _videoManager.disposeAll();
    _headerScaleController.dispose();
    _headerOpacityController.dispose();
    for (var controller in _scaleControllers) {
      controller.dispose();
    }
    for (var controller in _opacityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _videoManager = VideoControllerManager(
      onControllerReady: () {
        if (mounted) setState(() {});
      },
    );
    _loadImageUrls();
    _loadUserAvatars();
    _setupHeaderAnimations();
    _setupSpringAnimations();
  }

  void _setupHeaderAnimations() {
    // Header scale animation - start from 0.85 like carousel cards
    _headerScaleController = SingleMotionController(
      vsync: this,
      initialValue: 0.85,
      motion: const MaterialSpringMotion.expressiveSpatialFast(),
    );

    _headerScaleController.addListener(() {
      if (mounted) {
        setState(() {
          _headerScale = _headerScaleController.value;
        });
      }
    });

    // Header opacity animation
    _headerOpacityController = SingleMotionController(
      vsync: this,
      initialValue: 0.0,
      motion: const MaterialSpringMotion.expressiveSpatialFast(),
    );

    _headerOpacityController.addListener(() {
      if (mounted) {
        setState(() {
          _headerOpacity = _headerOpacityController.value.clamp(0.0, 1.0);
        });
      }
    });

    // Animate header first (before cards)
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _headerScaleController.animateTo(1.0);
        _headerOpacityController.animateTo(1.0);
      }
    });
  }

  void _setupSpringAnimations() {
    // Create Motor spring animations for each card using Material Design 3 tokens
    for (int i = 0; i < widget.moments.length; i++) {
      // Initialize values
      _scales.add(0.85);
      _opacities.add(0.0);

      // Scale controller with Material expressiveSpatialFast spring
      final scaleController = SingleMotionController(
        vsync: this,
        initialValue: 0.85,
        motion: const MaterialSpringMotion.expressiveSpatialFast(),
      );

      scaleController.addListener(() {
        if (mounted && i < _scales.length) {
          setState(() {
            _scales[i] = scaleController.value;
          });
        }
      });

      // Opacity controller with Material expressiveSpatialFast spring
      final opacityController = SingleMotionController(
        vsync: this,
        initialValue: 0.0,
        motion: const MaterialSpringMotion.expressiveSpatialFast(),
      );

      opacityController.addListener(() {
        if (mounted && i < _opacities.length) {
          setState(() {
            _opacities[i] = opacityController.value.clamp(0.0, 1.0);
          });
        }
      });

      _scaleControllers.add(scaleController);
      _opacityControllers.add(opacityController);

      // Stagger the animations with 50ms delays
      Future.delayed(Duration(milliseconds: 80 + (i * 50)), () {
        if (mounted) {
          scaleController.animateTo(1.0);
          opacityController.animateTo(1.0);
        }
      });
    }
  }

  Widget _buildMediaContent(Moment moment, String? mediaUrl) {
    final localPath = _localPaths[moment.id];
    final localVideoPath = _localVideoPaths[moment.id];

    // If video, show video player with offline support
    if (moment.mediaType == 'video') {
      return OfflineVideo(
        localPath: localVideoPath,
        networkUrl: mediaUrl,
        autoPlay: false,
        looping: false,
        prewarmedController: _videoManager.getController(moment.id),
      );
    }

    // Show image using offline-first approach
    if (localPath != null || mediaUrl != null) {
      return OfflineImage(
        localPath: localPath,
        networkUrl: mediaUrl,
        cacheKey: moment.mediaPath,
        fit: BoxFit.cover,
      );
    }

    // Loading state
    return Container(
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _loadImageUrls() async {
    // First, load local cached images and videos
    for (var moment in widget.moments) {
      if (moment.mediaType == 'video') {
        // Load local video path
        final localVideoPath = await _storage.getLocalMediaPath(moment.id);
        if (localVideoPath != null && mounted) {
          setState(() {
            _localVideoPaths[moment.id] = localVideoPath;
          });
        }
        // Also load local thumbnail for preview
        final localThumbPath = await _storage.getLocalMediaPath(
          moment.id,
          isThumbnail: true,
        );
        if (localThumbPath != null && mounted) {
          setState(() {
            _localPaths[moment.id] = localThumbPath;
          });
        }
      } else {
        // Load local image path
        final localPath = await _storage.getLocalMediaPath(moment.id);
        if (localPath != null && mounted) {
          setState(() {
            _localPaths[moment.id] = localPath;
          });
        }
      }
    }

    // Pre-populate with existing imageUrls (fallback)
    if (mounted) {
      setState(() {
        for (var moment in widget.moments) {
          if (moment.imageUrl != null) {
            _imageUrls[moment.id] = moment.imageUrl!;
          }
        }
      });
    }

    // Collect paths to load - use thumbnails for videos, media_path for images
    final pathsToLoad = <String>[];

    for (var moment in widget.moments) {
      if (moment.mediaType == 'video') {
        // For videos, load thumbnail for preview
        if (moment.thumbnailPath != null && moment.thumbnailPath!.isNotEmpty) {
          pathsToLoad.add(moment.thumbnailPath!);
        }
        // Also load the actual video URL for playback
        if (moment.mediaPath != null && moment.mediaPath!.isNotEmpty) {
          pathsToLoad.add(moment.mediaPath!);
        }
      } else {
        // For images, just load media path
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
          for (var moment in widget.moments) {
            if (moment.mediaType == 'video') {
              // Store video URL for playback
              if (moment.mediaPath != null) {
                final videoUrl = urls[moment.mediaPath];
                if (videoUrl != null) {
                  _imageUrls[moment.id] = videoUrl;
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

        // Cache media to local storage in background
        _cacheMediaInBackground(urls);

        // Prewarm video controllers for current ± 1 window
        _prewarmVideoControllers();
      }
    } catch (e) {
      debugPrint('Error loading signed URLs: $e');
    }
  }

  /// Prewarm video controllers for the current page ± 1 window
  void _prewarmVideoControllers() {
    // Get indices in the ±1 window
    final indices = <int>[];
    for (int i = _currentPage - 1; i <= _currentPage + 1; i++) {
      if (i >= 0 && i < widget.moments.length) {
        indices.add(i);
      }
    }

    // Collect video moment IDs and their info
    final momentIds = <String>[];
    final videoInfoMap = <String, VideoInfo>{};

    for (final i in indices) {
      final moment = widget.moments[i];
      if (moment.mediaType != 'video') continue;

      momentIds.add(moment.id);

      // Prefer local path, fallback to network URL
      final localPath = _localVideoPaths[moment.id];
      final networkUrl = _imageUrls[moment.id];

      if (localPath != null) {
        videoInfoMap[moment.id] = VideoInfo(url: localPath, isLocal: true);
      } else if (networkUrl != null) {
        videoInfoMap[moment.id] = VideoInfo(url: networkUrl, isLocal: false);
      }
    }

    if (momentIds.isNotEmpty) {
      _videoManager.prewarm(momentIds: momentIds, videoInfoMap: videoInfoMap);
    }
  }

  Future<void> _cacheMediaInBackground(Map<String, String> urls) async {
    for (var moment in widget.moments) {
      if (moment.mediaType == 'video') {
        // Cache video if not already cached
        if (!_localVideoPaths.containsKey(moment.id)) {
          final videoUrl = _imageUrls[moment.id];
          if (videoUrl != null) {
            final localPath = await _storage.cacheMedia(moment.id, videoUrl);
            if (localPath != null && mounted) {
              setState(() {
                _localVideoPaths[moment.id] = localPath;
              });
            }
          }
        }
        // Cache video thumbnail if not already cached
        if (!_localPaths.containsKey(moment.id) &&
            moment.thumbnailPath != null) {
          final thumbUrl = urls[moment.thumbnailPath];
          if (thumbUrl != null) {
            final localPath = await _storage.cacheMedia(
              moment.id,
              thumbUrl,
              isThumbnail: true,
            );
            if (localPath != null && mounted) {
              setState(() {
                _localPaths[moment.id] = localPath;
              });
            }
          }
        }
      } else {
        // Cache image if not already cached
        if (_localPaths.containsKey(moment.id)) continue;

        final url = _imageUrls[moment.id];
        if (url == null) continue;

        final localPath = await _storage.cacheMedia(moment.id, url);
        if (localPath != null && mounted) {
          setState(() {
            _localPaths[moment.id] = localPath;
          });
        }
      }
    }
  }

  Future<void> _handleAddPhotos() async {
    if (widget.moments.isEmpty) return;

    final firstMoment = widget.moments.first;
    final groupId = firstMoment.momentGroupId;

    if (groupId == null) {
      context.showErrorSnackBar('Cannot add photos to this moment (Legacy).');
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (pickedFiles.isEmpty) return;

      setState(() {
        _isUploading = true;
      });

      final imageFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();

      await ref
          .read(momentRepositoryProvider)
          .createMomentsBatch(
            imageFiles,
            firstMoment.title,
            '', // Caption optional for batch add
            widget.locationName,
            firstMoment.latitude,
            firstMoment.longitude,
            momentGroupId: groupId,
          );

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        HapticService.photoAdded();
        context.showSuccessSnackBar('Photos added successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        HapticService.error();
        context.showErrorSnackBar('Error picking photos: $e');
      }
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

    // First, immediately populate from cache (sync)
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

  String _getDateRange() {
    if (widget.moments.isEmpty) return '';

    final dates = widget.moments.map((m) => m.timestamp).toList()..sort();

    final earliest = dates.first;
    final latest = dates.last;

    if (earliest.year == latest.year &&
        earliest.month == latest.month &&
        earliest.day == latest.day) {
      return _formatDate(earliest);
    }

    return '${_formatDate(earliest)} - ${_formatDate(latest)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
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
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  List<String> _getUniqueContributorIds() {
    final Set<String> contributorIds = {};
    for (var moment in widget.moments) {
      if (moment.userId != null) {
        contributorIds.add(moment.userId!);
      }
    }
    return contributorIds.toList();
  }

  /// Get list of avatar ImageProviders to display (max 3)
  List<ImageProvider> _getAvatarsToDisplay() {
    final contributorIds = _getUniqueContributorIds();
    final avatars = <CachedNetworkImageProvider>[];

    for (final userId in contributorIds.take(3)) {
      final avatarUrl = _userAvatars[userId];
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        avatars.add(CachedNetworkImageProvider(avatarUrl));
      }
    }
    return avatars;
  }

  /// Get overflow count (contributors beyond the first 3)
  int _getOverflowCount() {
    final totalWithAvatars = _getUniqueContributorIds()
        .where(
          (id) => _userAvatars.containsKey(id) && _userAvatars[id]!.isNotEmpty,
        )
        .length;
    return totalWithAvatars > 3 ? totalWithAvatars - 3 : 0;
  }

  /// Calculate avatar stack width based on number of avatars
  Widget _buildAvatarStack() {
    final avatars = _getAvatarsToDisplay();
    final overflowCount = _getOverflowCount();

    // Combine avatars and overflow into a list of widgets
    final items = <Widget>[];
    for (final avatar in avatars) {
      items.add(
        Container(
          width: 40.sp,
          height: 40.sp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            image: DecorationImage(image: avatar, fit: BoxFit.cover),
          ),
        ),
      );
    }

    if (overflowCount > 0) {
      items.add(
        Container(
          width: 40.sp,
          height: 40.sp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            color: Colors.black87,
          ),
          child: Center(
            child: Text(
              '+$overflowCount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    final double size = 40.sp;
    final double overlap = 15.sp; // Amount they overlap
    final double shift = size - overlap; // 25.sp
    final double width = size + (items.length - 1) * shift;

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: List.generate(items.length, (index) {
          return Positioned(left: index * shift, top: 0, child: items[index]);
        }),
      ),
    );
  }

  void _showShareSheet(Moment moment, String? imageUrl) {
    ShareBottomSheet.show(
      context: context,
      moment: moment,
      imageUrl: imageUrl,
      localImagePath: _localPaths[moment.id],
    );
  }

  Future<void> _showDeleteDialog(Moment moment) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Moment'),
        content: const Text('What would you like to delete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete_all'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (result == null || result == 'cancel' || !mounted) return;

    try {
      if (result == 'delete') {
        // Delete single moment
        await Supabase.instance.client
            .from('moments')
            .delete()
            .eq('id', moment.id);

        if (mounted) {
          setState(() {
            widget.moments.remove(moment);
          });

          if (widget.moments.isEmpty) {
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Moment deleted')));
          }
        }
      } else if (result == 'delete_all') {
        // Delete all moments at this location
        final momentIds = widget.moments.map((m) => m.id).toList();
        await Supabase.instance.client
            .from('moments')
            .delete()
            .inFilter('id', momentIds);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('All moments deleted')));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height for proper sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight =
        screenHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _handleAddPhotos,
        backgroundColor: Colors.black,
        child: _isUploading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add_photo_alternate, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Animated header with spring animation
            Transform.scale(
              scale: _headerScale,
              child: Opacity(
                opacity: _headerOpacity,
                child: Column(
                  children: [
                    // AppBar with back button and centered location
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: SvgPicture.asset(
                              'assets/icons/Left arrow.svg',
                              width: 34.w,
                              height: 34.h,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.moments.isNotEmpty &&
                                        widget.moments.first.isPrivate)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6.0,
                                        ),
                                        child: HugeIcon(
                                          icon: HugeIcons
                                              .strokeRoundedSquareLock02,
                                          size: 20,
                                          color: Colors.black,
                                        ),
                                      ),
                                    Flexible(
                                      child: Text(
                                        widget.moments.isNotEmpty
                                            ? widget.moments.first.title
                                                  .toUpperCase()
                                            : 'MOMENT',
                                        style: GoogleFonts.bebasNeue(
                                          fontSize: 28.sp,
                                          letterSpacing: 1.5.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                          height: 1.2.h,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedLocation03,
                                      size: 12,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.locationName,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.primaryBlue,
                                        letterSpacing: 1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 48), // Balance the back button
                        ],
                      ),
                    ),

                    // Total count and date range in same line (sentence case)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Text(
                        '${widget.moments.length} ${widget.moments.length == 1 ? 'photo' : 'photos'}  •  ${_getDateRange()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Avatar stack of contributors
                    if (_getAvatarsToDisplay().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [_buildAvatarStack()],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Carousel with spring animations using carousel_slider - fixed height
            SizedBox(
              height: availableHeight - 270.h, // Subtract header/avatar space
              child: CarouselSlider.builder(
                itemCount: widget.moments.length,
                options: CarouselOptions(
                  height: availableHeight - 200.h,
                  viewportFraction: 0.7, // 70% viewport for nice peek effect
                  enlargeCenterPage: true,
                  enlargeFactor: 0.2, // Subtle scale effect
                  enableInfiniteScroll: false,
                  initialPage: widget.initialPage,
                  onPageChanged: (index, reason) {
                    _currentPage = index;
                    _prewarmVideoControllers();
                    // Haptic feedback on card snap
                    HapticService.cardSnap();
                  },
                ),
                itemBuilder: (context, index, realIndex) {
                  final moment = widget.moments[index];
                  final imageUrl = _imageUrls[moment.id];

                  // Get animation values
                  final scale = index < _scales.length ? _scales[index] : 0.85;
                  final opacity = index < _opacities.length
                      ? _opacities[index]
                      : 0.0;

                  // Slight rotation for natural feel
                  final rotation = (((index * 37) % 5) - 2) * 0.5;

                  return GestureDetector(
                    onLongPress: () {
                      HapticService.longPress();
                      _showDeleteDialog(moment);
                    },
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: rotation * math.pi / 180,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth:
                                    320, // Slightly larger for better visibility with 0.7 viewport
                                maxHeight: 500,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Image card with white border - 4:5 aspect ratio
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 6.w,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 24.r,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: AspectRatio(
                                      aspectRatio: 4 / 5,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        child: _buildMediaContent(
                                          moment,
                                          imageUrl,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Description below image
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 16.0,
                                      left: 8.0,
                                      right: 8.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        if (moment.caption != null &&
                                            moment.caption!.isNotEmpty)
                                          Text(
                                            moment.caption!,
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 15.sp,
                                              color: AppTheme.textDark,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _formatDate(moment.timestamp),
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: AppTheme.textGray,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            GestureDetector(
                                              onTap: () => _showShareSheet(
                                                moment,
                                                imageUrl,
                                              ),
                                              child: ButtonM3E(
                                                label: const Text('Share'),
                                                style: ButtonM3EStyle.filled,
                                                size: ButtonM3ESize.xs,
                                                icon: const Icon(Icons.share),
                                                shape: ButtonM3EShape.round,
                                                onPressed: () =>
                                                    _showShareSheet(
                                                      moment,
                                                      imageUrl,
                                                    ),
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
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
