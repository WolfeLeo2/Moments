import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:motor/motor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../../data/models/moment.dart';
import '../../../data/models/moment_contributor.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../core/services/video_controller_manager.dart';
import '../../../core/services/haptic_service.dart';

import '../../../core/providers/providers.dart';
import '../../../widgets/offline_image.dart';
import '../../../widgets/offline_video.dart';
import '../../../widgets/share_bottom_sheet.dart';
import '../../../widgets/heart_animation.dart';
import '../../../widgets/contributors_list.dart';
import '../../../widgets/invite_contributors_sheet.dart';

import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../core/providers/database_provider.dart';
import 'dart:io';
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
  bool _isSavingOffline = false;
  bool _allSavedOffline = false;

  final List<double> _opacities = [];
  final List<SingleMotionController> _opacityControllers = [];
  // Motor spring controllers for each card
  final List<SingleMotionController> _scaleControllers = [];

  final List<double> _scales = [];
  final Map<String, String> _userAvatars = {}; // User ID -> avatar URL
  // Video controller manager for hybrid prewarm approach
  late final VideoControllerManager _videoManager;

  // Photo heart state (double-tap to like)
  final Map<int, int> _photoHeartCounts = {}; // photo index -> heart count
  final Map<int, bool> _userHeartedPhoto = {}; // photo index -> user hearted
  int? _showingHeartAtIndex; // Index of photo showing heart animation
  bool _isLikeAnimation = true; // true = like, false = dislike

  // Collaborative moments state
  List<MomentContributor> _contributors = [];
  bool _isOwner = false;
  bool _isGroupPrivate = false;
  MomentContributor? _userContribution;

  // Realtime moments list (starts with widget.moments, updates via stream)
  late List<Moment> _moments;
  String? _groupId;

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

  /// Reinitialize animation controllers when moments list changes
  void _initializeAnimationControllers() {
    // Dispose old controllers
    for (var controller in _scaleControllers) {
      controller.dispose();
    }
    for (var controller in _opacityControllers) {
      controller.dispose();
    }

    // Clear old data
    _scaleControllers.clear();
    _opacityControllers.clear();
    _scales.clear();
    _opacities.clear();

    // Setup new controllers for new moment count
    _setupSpringAnimations();
  }

  @override
  void initState() {
    super.initState();
    // Initialize with widget moments, will be updated via stream
    _moments = List.from(widget.moments);

    // Only enable realtime updates if all moments belong to the same group
    // If it's a cluster of multiple groups, we don't watch a single group stream
    final uniqueGroupIds = widget.moments
        .map((m) => m.momentGroupId)
        .where((id) => id != null)
        .toSet();

    _groupId = uniqueGroupIds.length == 1 ? uniqueGroupIds.first : null;
    _currentPage = widget.initialPage;
    _videoManager = VideoControllerManager(
      onControllerReady: () {
        if (mounted) setState(() {});
      },
    );
    _loadImageUrls();
    _loadUserAvatars();
    _loadAllPhotoHeartStatuses();
    _loadContributors();
    _setupHeaderAnimations();
    _setupSpringAnimations();
  }

  /// Handle realtime stream updates for moments in this group
  void _handleMomentsStreamUpdate(List<Moment> updatedMoments) {
    // Check if moments actually changed (by comparing IDs AND count)
    final currentIds = _moments.map((m) => m.id).toSet();
    final updatedIds = updatedMoments.map((m) => m.id).toSet();

    // Skip update if IDs are identical (same moments, same count)
    if (currentIds.length == updatedIds.length &&
        currentIds.containsAll(updatedIds)) {
      return; // No actual change
    }

    if (!currentIds.containsAll(updatedIds) ||
        !updatedIds.containsAll(currentIds)) {
      if (!mounted) return;

      // Find deleted/added moment IDs
      final deletedIds = currentIds.difference(updatedIds);
      final addedIds = updatedIds.difference(currentIds);
      final countChanged = _moments.length != updatedMoments.length;

      setState(() {
        // Clean up cached data for deleted moments
        for (final deletedId in deletedIds) {
          _imageUrls.remove(deletedId);
          _localPaths.remove(deletedId);
          _localVideoPaths.remove(deletedId);
        }

        _moments = updatedMoments;

        // Adjust current page if needed
        if (_currentPage >= _moments.length && _moments.isNotEmpty) {
          _currentPage = _moments.length - 1;
        }
      });

      // Only reinitialize animations if count changed (new/deleted moments)
      if (countChanged) {
        _initializeAnimationControllers();
      }

      // Load data for new moments only
      if (addedIds.isNotEmpty) {
        _loadAllPhotoHeartStatuses();
        _loadImageUrls();
      }
    }
  }

  /// Load contributors for collaborative moment
  Future<void> _loadContributors() async {
    if (_moments.isEmpty) return;
    final groupId = _moments.first.momentGroupId;
    if (groupId == null) return;

    try {
      final repository = ref.read(momentRepositoryProvider);

      final contributors = await repository.getContributors(groupId);
      final userContribution = await repository.getUserContribution(groupId);
      final isPrivate = await repository.isGroupPrivate(groupId);

      if (mounted) {
        setState(() {
          _contributors = contributors;
          _userContribution = userContribution;
          _isGroupPrivate = isPrivate;
          // Fallback to moment ownership if group ownership is not explicitly defined
          _isOwner =
              (_userContribution?.isOwner ?? false) ||
              (_moments.isNotEmpty && _isOwnMoment(_moments.first));
        });

        // Reload avatars now that contributors are available
        _loadUserAvatars();
      }
    } catch (e) {
      debugPrint('Failed to load contributors: $e');
    }
  }

  /// Show invite contributors sheet
  void _showInviteSheet() {
    if (_moments.isEmpty) return;
    final groupId = _moments.first.momentGroupId;
    if (groupId == null) return;

    HapticService.lightTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InviteContributorsSheet(
        momentId: groupId,
        existingContributorIds: _contributors.map((c) => c.userId).toList(),
        onInvite: (profiles) async {
          final repository = ref.read(momentRepositoryProvider);
          for (final profile in profiles) {
            try {
              await repository.inviteContributor(
                momentId: groupId,
                friendId: profile.id,
              );
            } catch (e) {
              debugPrint('Failed to invite ${profile.username}: $e');
            }
          }
          // Reload contributors
          await _loadContributors();
          if (mounted) {
            context.showSuccessSnackBar(
              'Invitation${profiles.length > 1 ? 's' : ''} sent!',
            );
          }
        },
      ),
    );
  }

  /// Show contributors modal
  void _showContributorsModal() {
    // If group is private, show warning that it needs to be public to invite others
    if (_isGroupPrivate && !_contributors.any((c) => !c.isOwner)) {
      // Only show if there are no other contributors yet (solo private group)
      if (_moments.isNotEmpty && _isOwnMoment(_moments.first)) {
        HapticService.error();
        context.showSnackBar(
          'Limited to public groups!',
          backgroundColor: AppTheme.primaryBlue,
        );
        return;
      }
    }

    HapticService.lightTap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ContributorsList(
              contributors: _contributors,
              isOwner: _isOwner,
              onInvite: () {
                Navigator.pop(context);
                _showInviteSheet();
              },
              onRemove: (contributor) async {
                Navigator.pop(context);
                await _removeContributor(contributor);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Remove a contributor
  Future<void> _removeContributor(MomentContributor contributor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove contributor?'),
        content: Text(
          'Remove ${contributor.displayName ?? contributor.username ?? 'this user'} from this moment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(momentRepositoryProvider);
      await repository.removeContributor(contributor.id);
      await _loadContributors();
      if (mounted) {
        context.showSuccessSnackBar('Contributor removed');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to remove contributor');
      }
    }
  }

  /// Load heart status for all photos in the carousel
  void _loadAllPhotoHeartStatuses() {
    for (int i = 0; i < _moments.length; i++) {
      _loadPhotoHeartStatus(i);
    }
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
    for (int i = 0; i < _moments.length; i++) {
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
          try {
            scaleController.animateTo(1.0);
            opacityController.animateTo(1.0);
          } catch (e) {
            // Controller might be disposed if page was closed/reloaded rapidly
            debugPrint('Animation controller validation error: $e');
          }
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
    final db = ref.read(appDatabaseProvider);

    // First, load local cached images and videos
    for (var moment in _moments) {
      if (moment.mediaType == 'video') {
        // Load local video path
        final localVideoPath = await db.getLocalMediaPath(moment.id);
        if (localVideoPath != null && mounted) {
          setState(() {
            _localVideoPaths[moment.id] = localVideoPath;
          });
        }
        // Also load local thumbnail for preview
        final localThumbPath = await db.getLocalMediaPath(
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
        final localPath = await db.getLocalMediaPath(moment.id);
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
        for (var moment in _moments) {
          if (moment.imageUrl != null) {
            _imageUrls[moment.id] = moment.imageUrl!;
          }
        }
      });
    }

    // Collect paths to load - use thumbnails for videos, media_path for images
    final pathsToLoad = <String>[];

    for (var moment in _moments) {
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
          for (var moment in _moments) {
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

        // Check if all saved offline
        _checkAllSavedOffline();
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
      if (i >= 0 && i < _moments.length) {
        indices.add(i);
      }
    }

    // Collect video moment IDs and their info
    final momentIds = <String>[];
    final videoInfoMap = <String, VideoInfo>{};

    for (final i in indices) {
      final moment = _moments[i];
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
    final db = ref.read(appDatabaseProvider);

    for (var moment in _moments) {
      if (moment.mediaType == 'video') {
        // Cache video if not already cached
        if (!_localVideoPaths.containsKey(moment.id)) {
          final videoUrl = _imageUrls[moment.id];
          if (videoUrl != null) {
            final localPath = await db.cacheMedia(moment.id, videoUrl);
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
            final localPath = await db.cacheMedia(
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

        final localPath = await db.cacheMedia(moment.id, url);
        if (localPath != null && mounted) {
          setState(() {
            _localPaths[moment.id] = localPath;
          });
        }
      }
    }
  }

  /// Check if user can add photos (owner or accepted contributor)
  bool get _canAddPhotos {
    // Owner can always add
    if (_isOwner) return true;
    // Accepted contributors can add
    if (_userContribution != null && _userContribution!.hasAccepted)
      return true;
    // Check if user is the moment creator (fallback for moments without contributor records)
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (_moments.isNotEmpty && _moments.first.userId == userId) return true;
    return false;
  }

  Future<void> _handleAddPhotos() async {
    if (_moments.isEmpty) return;

    // Check permission
    if (!_canAddPhotos) {
      context.showErrorSnackBar(
        'Only contributors can add photos to this moment.',
      );
      return;
    }

    final firstMoment = _moments.first;
    final groupId = firstMoment.momentGroupId;

    if (groupId == null) {
      context.showErrorSnackBar('Cannot add photos to this moment (Legacy).');
      return;
    }

    try {
      final picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage(
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
    // Get unique user IDs from moments
    final momentUserIds = _moments
        .where((m) => m.userId != null)
        .map((m) => m.userId!)
        .toSet();

    // Also get user IDs from contributors (in case they haven't posted yet)
    final contributorUserIds = _contributors.map((c) => c.userId).toSet();

    // Combine both sets
    final userIds = {...momentUserIds, ...contributorUserIds}.toList();

    if (userIds.isEmpty) return;

    final avatarService = ref.read(avatarCacheServiceProvider);

    // First, immediately populate from cache (sync)
    final cachedAvatars = avatarService.getAvatarUrlsSync(userIds);
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
      final fetchedAvatars = await avatarService.getAvatarUrls(missingIds);

      if (mounted && fetchedAvatars.isNotEmpty) {
        setState(() {
          _userAvatars.addAll(fetchedAvatars);
        });
      }
    } catch (e) {
      debugPrint('Error loading user avatars: $e');
    }
  }

  /// Load heart status for a photo at given index
  Future<void> _loadPhotoHeartStatus(int photoIndex) async {
    if (_moments.isEmpty || photoIndex >= _moments.length) return;

    // Use the actual moment ID for this photo
    final momentId = _moments[photoIndex].id;

    try {
      final repo = ref.read(momentRepositoryProvider);
      final count = await repo.getPhotoHeartCount(momentId, photoIndex);
      final userHearted = await repo.hasUserHeartedPhoto(momentId, photoIndex);

      if (mounted) {
        setState(() {
          _photoHeartCounts[photoIndex] = count;
          _userHeartedPhoto[photoIndex] = userHearted;
        });
      }
    } catch (e) {
      debugPrint('Error loading photo heart status: $e');
    }
  }

  /// Handle double-tap to heart a photo
  Future<void> _handleDoubleTapHeart(int photoIndex) async {
    if (_moments.isEmpty || photoIndex >= _moments.length) return;

    // Use the actual moment ID for this photo
    final momentId = _moments[photoIndex].id;

    // Determine if this is a like or unlike action
    final isUnliking = _userHeartedPhoto[photoIndex] == true;

    // Show appropriate animation immediately for responsiveness
    setState(() {
      _showingHeartAtIndex = photoIndex;
      _isLikeAnimation =
          !isUnliking; // like animation if adding, dislike if removing
    });
    HapticService.mediumTap();

    // Hide animation after delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showingHeartAtIndex = null;
        });
      }
    });

    try {
      final repo = ref.read(momentRepositoryProvider);
      final wasAdded = await repo.togglePhotoHeart(momentId, photoIndex);

      if (mounted) {
        setState(() {
          _userHeartedPhoto[photoIndex] = wasAdded;
          _photoHeartCounts[photoIndex] =
              (_photoHeartCounts[photoIndex] ?? 0) + (wasAdded ? 1 : -1);
        });
      }
    } catch (e) {
      debugPrint('Error toggling photo heart: $e');
    }
  }

  String _getDateRange() {
    if (_moments.isEmpty) return '';

    final dates = _moments.map((m) => m.timestamp).toList()..sort();

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

    // Get user IDs from moments
    for (var moment in _moments) {
      if (moment.userId != null) {
        contributorIds.add(moment.userId!);
      }
    }

    // Also include accepted contributors who may not have posted moments yet
    for (var contributor in _contributors) {
      if (contributor.hasAccepted) {
        contributorIds.add(contributor.userId);
      }
    }

    return contributorIds.toList();
  }

  /// Get list of ALL avatar ImageProviders to display (no limit)
  List<ImageProvider> _getAvatarsToDisplay() {
    final contributorIds = _getUniqueContributorIds();
    final avatars = <ImageProvider>[];
    final avatarService = ref.read(avatarCacheServiceProvider);

    for (final userId in contributorIds) {
      final avatarUrl = _userAvatars[userId];
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        // Use getAvatarImageProvider for offline support (FileImage if local exists)
        final provider = avatarService.getAvatarImageProvider(avatarUrl);
        if (provider != null) {
          avatars.add(provider);
        }
      }
    }
    return avatars;
  }

  /// Build avatar stack showing all contributors
  Widget _buildAvatarStack() {
    final avatars = _getAvatarsToDisplay();
    if (avatars.isEmpty) return const SizedBox.shrink();

    const double size = 38; // Fixed size for consistent look
    const double overlap = 16; // Amount they overlap

    // Build list of avatar widgets
    final items = <Widget>[];
    for (int i = 0; i < avatars.length; i++) {
      items.add(
        Container(
          width: size,
          height: size,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            image: DecorationImage(image: avatars[i], fit: BoxFit.cover),
          ),
        ),
      );
    }

    // Calculate total width: first avatar full + remaining with overlap
    final double totalWidth = size + (avatars.length - 1) * (size - overlap);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(items.length, (index) {
          return Positioned(
            left: index * (size - overlap),
            top: 0,
            child: items[index],
          );
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

  /// Check if all moments are saved offline
  void _checkAllSavedOffline() {
    final allSaved = _moments.every((m) {
      if (m.mediaType == 'video') {
        return _localVideoPaths.containsKey(m.id) &&
            _localPaths.containsKey(m.id);
      }
      return _localPaths.containsKey(m.id);
    });
    if (mounted && allSaved != _allSavedOffline) {
      setState(() => _allSavedOffline = allSaved);
    }
  }

  /// Save all moments in this group offline
  Future<void> _saveAllOffline() async {
    if (_isSavingOffline || _allSavedOffline) return;

    setState(() => _isSavingOffline = true);
    HapticService.selectionClick();

    int savedCount = 0;
    int totalToSave = 0;

    try {
      final db = ref.read(appDatabaseProvider);

      for (var moment in _moments) {
        // Skip if already saved
        if (moment.mediaType == 'video') {
          if (_localVideoPaths.containsKey(moment.id) &&
              _localPaths.containsKey(moment.id)) {
            continue;
          }
        } else {
          if (_localPaths.containsKey(moment.id)) continue;
        }

        totalToSave++;
        final url = _imageUrls[moment.id];
        if (url == null) continue;

        if (moment.mediaType == 'video') {
          // Save video
          final videoPath = await db.cacheMedia(moment.id, url);
          if (videoPath != null && mounted) {
            setState(() => _localVideoPaths[moment.id] = videoPath);
            savedCount++;
          }
          // Save thumbnail
          if (moment.thumbnailPath != null) {
            final thumbUrl = await SignedUrlCache.getSignedUrl(
              moment.thumbnailPath!,
            );
            if (thumbUrl != null) {
              final thumbPath = await db.cacheMedia(
                moment.id,
                thumbUrl,
                isThumbnail: true,
              );
              if (thumbPath != null && mounted) {
                setState(() => _localPaths[moment.id] = thumbPath);
              }
            }
          }
        } else {
          // Save image
          final localPath = await db.cacheMedia(moment.id, url);
          if (localPath != null && mounted) {
            setState(() => _localPaths[moment.id] = localPath);
            savedCount++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _isSavingOffline = false;
          _allSavedOffline = true;
        });
        HapticService.success();
        if (savedCount > 0) {
          context.showSuccessSnackBar(
            'Saved $savedCount ${savedCount == 1 ? "moment" : "moments"} offline!',
          );
        } else if (totalToSave == 0) {
          context.showSuccessSnackBar('All moments already saved offline!');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingOffline = false);
        HapticService.error();
        context.showErrorSnackBar('Failed to save offline: $e');
      }
    }
  }

  /// Show popup menu for moment actions (share, delete)
  void _showMomentActionsMenu(
    Moment moment,
    String? imageUrl,
    Offset position,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final isOwner = _isOwnMoment(moment);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromCenter(center: position, width: 0, height: 0),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: AppTheme.borderBlack,
          width: AppTheme.borderMedium,
        ),
      ),
      color: AppTheme.cardWhite,
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'share',
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedShare08,
                size: 20,
                color: AppTheme.textDark,
              ),
              const SizedBox(width: 12),
              Text(
                'Share',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
        // Privacy toggle option (only for owner)
        if (isOwner)
          PopupMenuItem<String>(
            value: 'toggle_privacy',
            child: Row(
              children: [
                HugeIcon(
                  icon: moment.isPrivate
                      ? HugeIcons.strokeRoundedSquareUnlock02
                      : HugeIcons.strokeRoundedSquareLock02,
                  size: 20,
                  color: moment.isPrivate
                      ? AppTheme.vibrantGreen
                      : AppTheme.emergencyRed,
                ),
                const SizedBox(width: 12),
                Text(
                  moment.isPrivate ? 'Make Visible' : 'Make Private',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: moment.isPrivate
                        ? AppTheme.vibrantGreen
                        : AppTheme.emergencyRed,
                  ),
                ),
              ],
            ),
          ),
        if (isOwner)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 20,
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                Text(
                  'Delete',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (value == 'share') {
        _showShareSheet(moment, imageUrl);
      } else if (value == 'toggle_privacy') {
        _toggleMomentPrivacy(moment, !moment.isPrivate);
      } else if (value == 'delete') {
        _showDeleteDialog(moment);
      }
    });
  }

  /// Check if current user owns the moment
  bool _isOwnMoment(Moment moment) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return currentUserId != null && moment.userId == currentUserId;
  }

  /// Delete a moment from Supabase storage, local storage, and database
  Future<void> _deleteMomentCompletely(Moment moment) async {
    // Use repository for complete cleanup (storage, database, group cleanup)
    await ref.read(momentRepositoryProvider).deleteMoment(moment.id);

    // Also delete from local SQLite storage and cached media files
    try {
      await ref.read(appDatabaseProvider).deleteMoment(moment.id);
    } catch (e) {
      debugPrint('Failed to delete from local storage: $e');
    }
  }

  Future<void> _showDeleteDialog(Moment moment) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Check if user owns this moment
    if (!_isOwnMoment(moment)) {
      if (mounted) {
        HapticService.error();
        context.showErrorSnackBar('You can only delete your own moments');
      }
      return;
    }

    // Check how many moments in this group belong to the current user
    final ownMoments = _moments
        .where((m) => m.userId == currentUserId)
        .toList();
    final hasMultipleOwnMoments = ownMoments.length > 1;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: BorderSide(
            color: AppTheme.borderBlack,
            width: AppTheme.borderMedium,
          ),
        ),
        title: Text(
          'Delete Moment',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        content: Text(
          hasMultipleOwnMoments
              ? 'Delete this moment or all your moments at this location?'
              : 'Are you sure you want to delete this moment? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppTheme.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: AppTheme.textGray,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
          if (hasMultipleOwnMoments)
            TextButton(
              onPressed: () => Navigator.pop(context, 'delete_all'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(
                'Delete All Mine',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ),
        ],
      ),
    );

    if (result == null || result == 'cancel' || !mounted) return;

    try {
      HapticService.mediumTap();

      if (result == 'delete') {
        // Delete single moment completely
        await _deleteMomentCompletely(moment);

        if (mounted) {
          setState(() {
            _moments.remove(moment);
            _localPaths.remove(moment.id);
            _localVideoPaths.remove(moment.id);
            _imageUrls.remove(moment.id);
          });

          if (_moments.isEmpty) {
            HapticService.success();
            Navigator.pop(context);
          } else {
            HapticService.success();
            context.showSuccessSnackBar('Moment deleted');
          }
        }
      } else if (result == 'delete_all') {
        // Delete all moments owned by current user at this location
        for (final m in ownMoments) {
          await _deleteMomentCompletely(m);
        }

        if (mounted) {
          setState(() {
            for (final m in ownMoments) {
              _moments.remove(m);
              _localPaths.remove(m.id);
              _localVideoPaths.remove(m.id);
              _imageUrls.remove(m.id);
            }
          });

          if (_moments.isEmpty) {
            HapticService.success();
            context.showSuccessSnackBar('All your moments deleted');
            Navigator.pop(context);
          } else {
            HapticService.success();
            context.showSuccessSnackBar('${ownMoments.length} moments deleted');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        context.showErrorSnackBar('Failed to delete: $e');
      }
    }
  }

  /// Show privacy dropdown for a moment - allows toggling visibility
  void _showPrivacyDropdown(BuildContext context, Moment moment, int index) {
    HapticService.lightTap();

    final isOwner = _isOwnMoment(moment);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // Get position of the privacy badge (top left of card)
    final screenWidth = MediaQuery.of(context).size.width;
    final cardLeft =
        (screenWidth - (screenWidth * 0.8)) /
        2; // Approximate carousel card position

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(cardLeft + 16, 180, 100, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: AppTheme.borderBlack,
          width: AppTheme.borderMedium,
        ),
      ),
      color: AppTheme.cardWhite,
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedSquareLock02,
                    size: 18,
                    color: AppTheme.emergencyRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Private Photo',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Only visible to you',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ),
        if (isOwner)
          PopupMenuItem<String>(
            value: 'make_public',
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSquareUnlock02,
                  size: 20,
                  color: AppTheme.vibrantGreen,
                ),
                const SizedBox(width: 12),
                Text(
                  'Make Visible',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.vibrantGreen,
                  ),
                ),
              ],
            ),
          ),
        if (!isOwner)
          PopupMenuItem<String>(
            enabled: false,
            child: Text(
              'Only the owner can change this',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppTheme.textGray,
              ),
            ),
          ),
      ],
    ).then((value) {
      if (value == 'make_public') {
        _toggleMomentPrivacy(moment, false);
      }
    });
  }

  /// Toggle moment privacy (make public/private)
  Future<void> _toggleMomentPrivacy(Moment moment, bool isPrivate) async {
    // If it's a group, we update the whole group to keep it consistent
    final groupId = moment.momentGroupId;

    // Permission check
    // If it's a group, ideally only group owner should toggle, but for now we follow moment ownership logic
    // or assume if you can toggle one, you intend to toggle the group context.
    // We'll update all moments in this group that *I* own, plus the moment_group itself if I own it.

    if (!_isOwnMoment(moment) && _userContribution?.isOwner != true) {
      // Allow if moment owner OR group owner
      context.showErrorSnackBar(
        'You can only change privacy on your own photos',
      );
      return;
    }

    // Check if group has contributors - cannot make shared groups private
    if (groupId != null && isPrivate) {
      final nonOwnerContributors = _contributors
          .where((c) => !c.isOwner)
          .toList();
      if (nonOwnerContributors.isNotEmpty) {
        context.showErrorSnackBar('Cannot make shared group private');
        return;
      }
    }

    try {
      HapticService.mediumTap();
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      if (groupId != null) {
        // 1. Update the Group Privacy
        // (Only if I am the creator of the group or we decide any member can lock it?
        // Safer to check group ownership or fall back to moment update if not owner)
        // For this user script, we'll try to update the group.

        // Optimistically update all local moments
        setState(() {
          for (int i = 0; i < _moments.length; i++) {
            if (_moments[i].momentGroupId == groupId) {
              _moments[i] = _moments[i].copyWith(isPrivate: isPrivate);
            }
          }
          _isGroupPrivate = isPrivate;
        });

        // Update moment_groups (Policies will fail if not owner, which is fine, we catch error)
        try {
          await client
              .from('moment_groups')
              .update({'is_private': isPrivate})
              .eq('id', groupId);
        } catch (_) {
          // Ignore if failed (e.g. not owner of group), continue to update my photos
        }

        // 2. Update all MY moments in this group
        await client
            .from('moments')
            .update({'is_private': isPrivate})
            .eq('moment_group_id', groupId)
            .eq('user_id', userId!); // Only update my photos

        // Sync to local storage
        await ref
            .read(appDatabaseProvider)
            .updateGroupPrivacy(groupId, isPrivate);
      } else {
        // Fallback for single moment (Legacy)
        await client
            .from('moments')
            .update({'is_private': isPrivate})
            .eq('id', moment.id);

        setState(() {
          final index = _moments.indexWhere((m) => m.id == moment.id);
          if (index != -1) {
            _moments[index] = moment.copyWith(isPrivate: isPrivate);
          }
        });

        // Also sync to local storage
        await ref
            .read(appDatabaseProvider)
            .updateMomentPrivacy(moment.id, isPrivate);
      }

      if (mounted) {
        HapticService.success();
        context.showSuccessSnackBar(
          isPrivate ? 'Group is now private' : 'Group is now visible',
        );
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        context.showErrorSnackBar('Failed to update privacy: $e');
        // Revert? (Complex to revert batch, leaving simple for now)
      }
    }
  }

  /// Show privacy menu from title long-press
  void _showTitlePrivacyMenu() {
    if (_moments.isEmpty) return;

    final currentMoment = _moments[_currentPage];
    final isOwner = _isOwnMoment(currentMoment);

    if (!isOwner) {
      context.showErrorSnackBar(
        'You can only change privacy on your own photos',
      );
      return;
    }

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final screenWidth = MediaQuery.of(context).size.width;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(screenWidth / 2 - 75, 120, 150, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: AppTheme.borderBlack,
          width: AppTheme.borderMedium,
        ),
      ),
      color: AppTheme.cardWhite,
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'Photo Privacy',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'toggle',
          child: Row(
            children: [
              HugeIcon(
                icon: currentMoment.isPrivate
                    ? HugeIcons.strokeRoundedSquareUnlock02
                    : HugeIcons.strokeRoundedSquareLock02,
                size: 20,
                color: currentMoment.isPrivate
                    ? AppTheme.vibrantGreen
                    : AppTheme.emergencyRed,
              ),
              const SizedBox(width: 12),
              Text(
                currentMoment.isPrivate ? 'Make Visible' : 'Make Private',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: currentMoment.isPrivate
                      ? AppTheme.vibrantGreen
                      : AppTheme.emergencyRed,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'toggle') {
        _toggleMomentPrivacy(currentMoment, !currentMoment.isPrivate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for realtime updates (properly handles side effects outside build)
    if (_groupId != null) {
      ref.listen(momentsByGroupStreamProvider(_groupId!), (previous, next) {
        next.whenData((updatedMoments) {
          _handleMomentsStreamUpdate(updatedMoments);
        });
      });
    }

    // Get screen height for proper sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight =
        screenHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      // Only show FAB if user can add photos (owner or accepted contributor)
      floatingActionButton: _canAddPhotos
          ? Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.borderBlack,
                  width: AppTheme.borderMedium,
                ),
                boxShadow: AppTheme.brutalShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isUploading ? null : _handleAddPhotos,
                  borderRadius: BorderRadius.circular(
                    (AppTheme.radiusMedium - 2).clamp(0.0, double.infinity),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isUploading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : HugeIcon(
                                icon: HugeIcons.strokeRoundedImageAdd02,
                                size: 20.sp,
                                color: Colors.white,
                              ),
                        SizedBox(width: 8.w),
                        Text(
                          _isUploading ? 'Adding...' : 'Add to Moment',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Animated header with spring animation - clamp scale to prevent RRect geometry errors
            Transform.scale(
              scale: _headerScale.clamp(0.01, 1.0),
              child: Opacity(
                opacity: _headerOpacity.clamp(0.0, 1.0),
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
                            child: GestureDetector(
                              onLongPress: () {
                                if (_moments.isNotEmpty &&
                                    _isOwnMoment(_moments[_currentPage])) {
                                  HapticService.mediumTap();
                                  _showTitlePrivacyMenu();
                                }
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Show lock icon for current moment's privacy state
                                      if (_moments.isNotEmpty &&
                                          _moments[_currentPage].isPrivate)
                                        GestureDetector(
                                          onTap: () => _showPrivacyDropdown(
                                            context,
                                            _moments[_currentPage],
                                            _currentPage,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6.0,
                                            ),
                                            child: HugeIcon(
                                              icon: HugeIcons
                                                  .strokeRoundedSquareLock02,
                                              size: 20,
                                              color: AppTheme.emergencyRed,
                                            ),
                                          ),
                                        ),
                                      Flexible(
                                        child: Text(
                                          _moments.isNotEmpty
                                              ? _moments.first.title
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
                          ),
                          // Save offline button
                          IconButton(
                            onPressed: _isSavingOffline
                                ? null
                                : _saveAllOffline,
                            icon: _isSavingOffline
                                ? SizedBox(
                                    width: 24.w,
                                    height: 24.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  )
                                : HugeIcon(
                                    icon: _allSavedOffline
                                        ? HugeIcons.strokeRoundedDownload04
                                        : HugeIcons.strokeRoundedDownload02,
                                    size: 24.sp,
                                    color: _allSavedOffline
                                        ? Colors.green
                                        : AppTheme.textDark,
                                  ),
                            tooltip: _allSavedOffline
                                ? 'Saved offline'
                                : 'Save offline',
                          ),
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
                        '${_moments.length} ${_moments.length == 1 ? 'photo' : 'photos'}  •  ${_getDateRange()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Avatar stack of contributors (tappable to show full list)
                    // Always show for owners so they can invite friends
                    if (_getAvatarsToDisplay().isNotEmpty ||
                        _contributors.isNotEmpty ||
                        _isOwner)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: GestureDetector(
                          onTap: _showContributorsModal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_getAvatarsToDisplay().isNotEmpty)
                                _buildAvatarStack()
                              else if (_isOwner)
                                // Show invite prompt for owners with no contributors yet
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.primaryBlue.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const HugeIcon(
                                        icon: HugeIcons.strokeRoundedUserAdd01,
                                        size: 16,
                                        color: AppTheme.primaryBlue,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Invite friends',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_contributors.length > 1) ...[
                                const SizedBox(width: 8),
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedArrowRight01,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ],
                          ),
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
                itemCount: _moments.length,
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
                  final moment = _moments[index];
                  final imageUrl = _imageUrls[moment.id];

                  // Get animation values - clamp scale to prevent RRect geometry errors
                  final scale = (index < _scales.length ? _scales[index] : 0.85)
                      .clamp(0.01, 1.0);
                  final opacity = index < _opacities.length
                      ? _opacities[index].clamp(0.0, 1.0)
                      : 0.0;

                  // Slight rotation for natural feel
                  final rotation = (((index * 37) % 5) - 2) * 0.5;

                  return GestureDetector(
                    onDoubleTap: () => _handleDoubleTapHeart(index),
                    onLongPressStart: (details) {
                      HapticService.longPress();
                      _showMomentActionsMenu(
                        moment,
                        imageUrl,
                        details.globalPosition,
                      );
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
                                  // Privacy tag above card -> ensures full image visibility
                                  if (moment.isPrivate)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                        left: 4.0,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: GestureDetector(
                                          onTap: () => _showPrivacyDropdown(
                                            context,
                                            moment,
                                            index,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.emergencyRed,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const HugeIcon(
                                                  icon: HugeIcons
                                                      .strokeRoundedSquareLock02,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Private',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Image card with white border - 4:5 aspect ratio
                                  // Image card - Soft Minimalism
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 30,
                                          offset: const Offset(0, 15),
                                        ),
                                      ],
                                    ),
                                    child: AspectRatio(
                                      aspectRatio: 4 / 5,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          14,
                                        ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          _buildMediaContent(moment, imageUrl),
                                          // Heart/Dislike animation overlay (dotLottie)
                                          if (_showingHeartAtIndex == index)
                                            Center(
                                              child: HeartAnimation(
                                                size: 120,
                                                isLike: _isLikeAnimation,
                                              ),
                                            ),
                                          // Heart count badge (bottom right of image)
                                          // Only show when count > 1 (not for single heart)
                                          if ((_photoHeartCounts[index] ?? 0) >
                                              1)
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                          _userHeartedPhoto[index] ==
                                                              true
                                                            ? Icons.favorite
                                                            : Icons
                                                                  .favorite_border,
                                                      size: 14,
                                                      color:
                                                          _userHeartedPhoto[index] ==
                                                              true
                                                          ? Colors.red
                                                          : Colors.white,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${_photoHeartCounts[index]}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          // Show heart icon only when user hearted but count is 1
                                          if ((_photoHeartCounts[index] ?? 0) ==
                                                  1 &&
                                              _userHeartedPhoto[index] == true)
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.6),
                                                  shape: BoxShape.circle,
                                                ),
                                                  child: const Icon(
                                                    Icons.favorite,
                                                  size: 14,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                        ],
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
                                        Text(
                                          _formatDate(moment.timestamp),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppTheme.textGray,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Double-tap to ❤️  •  Hold to share',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: AppTheme.textGray.withValues(
                                              alpha: 0.6,
                                            ),
                                            fontStyle: FontStyle.italic,
                                          ),
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
