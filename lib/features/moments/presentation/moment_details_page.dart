import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moments/features/moments/presentation/relive_experience_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:motor/motor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../../data/sources/supabase_config.dart';

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
import '../../../widgets/music_indicator.dart';
import '../../../widgets/collaborative_audio_list.dart';
import '../../../widgets/spring_button.dart';
import 'comments_sheet.dart';

import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:wechat_assets_picker/wechat_assets_picker.dart'
    hide LatLng, RequestType;
import 'package:photo_manager/photo_manager.dart' as pm;
import '../../../core/providers/moments_providers.dart';
import '../../../core/providers/database_provider.dart';
import 'add_moment_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moments/core/services/app_logger.dart';

final _log = AppLogger('MomentDetails');

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
  bool _allSavedOffline = false;
  // Collaborative moments state
  List<MomentContributor> _contributors = [];

  int _currentPage = 0;
  String? _groupId;
  final Map<String, String> _imageUrls = {};
  bool _isGroupPrivate = false;
  bool _isLikeAnimation = true; // true = like, false = dislike
  bool _isOwner = false;
  bool _isSavingOffline = false;
  final Map<String, String> _localPaths = {}; // Local cached paths for images
  final Map<String, String> _localVideoPaths =
      {}; // Local cached paths for videos

  // Realtime moments list (starts with widget.moments, updates via stream)
  late List<Moment> _moments;

  final List<double> _opacities = [];
  final List<SingleMotionController> _opacityControllers = [];
  // Photo heart state (double-tap to like)
  final Map<int, int> _photoHeartCounts = {}; // photo index -> heart count

  // Motor spring controllers for each card
  final List<SingleMotionController> _scaleControllers = [];

  final List<double> _scales = [];
  int? _showingHeartAtIndex; // Index of photo showing heart animation
  final Map<String, String> _userAvatars = {}; // User ID -> avatar URL
  MomentContributor? _userContribution;
  final Map<int, bool> _userHeartedPhoto = {}; // photo index -> user hearted
  final Map<String, String> _userNames = {}; // User ID -> display name
  // Video controller manager for hybrid prewarm approach
  late final VideoControllerManager _videoManager;

  @override
  void dispose() {
    _videoManager.disposeAll();
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
    // Initialize with widget moments, will be updated via stream
    _moments = List.from(widget.moments);

    // Only enable realtime updates if all moments belong to the same group
    // If it's a cluster of multiple groups, we don't watch a single group stream
    final uniqueGroupIds = widget.moments.map((m) => m.momentGroupId).toSet();

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
    _setupSpringAnimations();
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
          _isOwner =
              (_userContribution?.isOwner ?? false) ||
              (_moments.isNotEmpty && _isOwnMoment(_moments.first));

          // Populate user names from contributors
          for (final c in contributors) {
            _userNames[c.userId] = c.displayName ?? c.username ?? 'Unknown';
          }
        });

        // Reload avatars now that contributors are available
        _loadUserAvatars();
        // Load names for moment users not in contributors
        _loadMissingUserNames();
      }
    } catch (e) {
      _log.e('Failed to load contributors: $e');
    }
  }

  /// Load display names for moment users who aren't in the contributors list
  Future<void> _loadMissingUserNames() async {
    final missingUserIds = _moments
        .where((m) => m.userId != null && !_userNames.containsKey(m.userId!))
        .map((m) => m.userId!)
        .toSet()
        .toList();

    if (missingUserIds.isEmpty) return;

    try {
      final profiles = await SupabaseConfig.client
          .from('profiles')
          .select('id, username, display_name')
          .inFilter('id', missingUserIds);

      if (mounted && profiles.isNotEmpty) {
        setState(() {
          for (final p in profiles) {
            _userNames[p['id'] as String] =
                (p['display_name'] as String?) ??
                (p['username'] as String?) ??
                'Unknown';
          }
        });
      }
    } catch (e) {
      _log.e('Error loading user names: $e');
    }
  }

  /// Show invite contributors sheet
  void _showInviteSheet() {
    if (_moments.isEmpty) return;
    final groupId = _moments.first.momentGroupId;

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
              _log.e('Failed to invite ${profile.username}: $e');
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
            _log.e('Animation controller validation error: $e');
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

    // Collect paths to load - skip items already cached locally
    final pathsToLoad = <String>[];

    for (var moment in _moments) {
      if (moment.mediaType == 'video') {
        final hasLocalThumb = _localPaths.containsKey(moment.id);
        final hasLocalVideo = _localVideoPaths.containsKey(moment.id);

        // For videos, load thumbnail for preview if missing locally
        if (!hasLocalThumb &&
            moment.thumbnailPath != null &&
            moment.thumbnailPath!.isNotEmpty) {
          pathsToLoad.add(moment.thumbnailPath!);
        }
        // Also load the actual video URL for playback if missing locally
        if (!hasLocalVideo &&
            moment.mediaPath != null &&
            moment.mediaPath!.isNotEmpty) {
          pathsToLoad.add(moment.mediaPath!);
        }
      } else {
        final hasLocalImage = _localPaths.containsKey(moment.id);
        // For images, only load media path if missing locally
        if (!hasLocalImage &&
            moment.mediaPath != null &&
            moment.mediaPath!.isNotEmpty) {
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
      _log.e('Error loading signed URLs: $e');
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
    if (_userContribution != null && _userContribution!.hasAccepted) {
      return true;
    }
    // Check if user is the moment creator (fallback for moments without contributor records)
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (_moments.isNotEmpty && _moments.first.userId == userId) return true;
    return false;
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
      _log.e('Error loading user avatars: $e');
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
      _log.e('Error loading photo heart status: $e');
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
      _log.e('Error toggling photo heart: $e');
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

  /// Show comments bottom sheet for a moment
  void _showCommentsSheet(String momentId) {
    HapticService.lightTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(momentId: momentId),
    );
  }

  /// Inline engagement row: comment icon+count | share button
  Widget _buildEngagementRow() {
    final moment = _moments[_currentPage];
    final tt = Theme.of(context).textTheme;
    final repo = ref.watch(momentRepositoryProvider);

    return Row(
      children: [
        // ── Comment button with count ──
        GestureDetector(
          onTap: () => _showCommentsSheet(moment.id),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: repo.watchCommentsForMoment(moment.id),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    count > 0 ? '$count' : '',
                    style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 20),
        // ── Share button ──
        GestureDetector(
          onTap: () {
            HapticService.lightTap();
            ShareBottomSheet.show(
              context: context,
              moment: moment,
              imageUrl: _imageUrls[moment.id],
              localImagePath: _localPaths[moment.id],
            );
          },
          child: HugeIcon(icon: HugeIcons.strokeRoundedShare01, size: 20),
        ),
      ],
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
                icon: HugeIcons.strokeRoundedShare01,
                size: 20,
                color: AppTheme.textDark,
              ),
              const SizedBox(width: 12),
              Text(
                'Share',
                style: GoogleFonts.inter(
                  textStyle: Theme.of(context).textTheme.labelMedium,
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
                      ? HugeIcons.strokeRoundedSquareLock02
                      : HugeIcons.strokeRoundedSquareUnlock02,
                  size: 20,
                  color: moment.isPrivate
                      ? AppTheme.vibrantGreen
                      : AppTheme.emergencyRed,
                ),
                const SizedBox(width: 12),
                Text(
                  moment.isPrivate ? 'Make Visible' : 'Make Private',
                  style: GoogleFonts.inter(
                    textStyle: Theme.of(context).textTheme.labelMedium,
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
                    textStyle: Theme.of(context).textTheme.labelMedium,
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
      _log.e('Failed to delete from local storage: $e');
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
          _isOwner && _moments.length > 1
              ? 'Delete this moment, all your moments, or the entire group?'
              : hasMultipleOwnMoments
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
          if (_isOwner && _moments.length > 1)
            TextButton(
              onPressed: () => Navigator.pop(context, 'delete_group'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(
                'Delete Entire Group',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade900,
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
      } else if (result == 'delete_group') {
        // Delete entire group — owner only
        final groupId = moment.momentGroupId;

        // Delete all moments from local DB first
        for (final m in _moments) {
          try {
            await ref.read(appDatabaseProvider).deleteMoment(m.id);
          } catch (_) {}
        }

        // Delete group and all its moments + storage from Supabase
        await ref.read(momentRepositoryProvider).deleteGroup(groupId);

        if (mounted) {
          HapticService.success();
          context.showSuccessSnackBar('Entire group deleted');
          Navigator.pop(context);
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
                      textStyle: Theme.of(context).textTheme.labelMedium,
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
                  textStyle: Theme.of(context).textTheme.labelSmall,
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
                  size: 18,
                  color: AppTheme.vibrantGreen,
                ),
                const SizedBox(width: 12),
                Text(
                  'Make Visible',
                  style: GoogleFonts.inter(
                    textStyle: Theme.of(context).textTheme.labelMedium,
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
                textStyle: Theme.of(context).textTheme.labelMedium,
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
    if (isPrivate) {
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

      // Update all MY moments in this group
      await client
          .from('moments')
          .update({'is_private': isPrivate})
          .eq('moment_group_id', groupId)
          .eq('user_id', userId!); // Only update my photos

      // Sync to local storage
      await ref
          .read(appDatabaseProvider)
          .updateGroupPrivacy(groupId, isPrivate);

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
              textStyle: Theme.of(context).textTheme.labelSmall,
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
                  textStyle: Theme.of(context).textTheme.labelMedium,
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

  // ─── FAB ──────────────────────────────────────────────────────────

  Widget? _buildFAB() {
    if (!_canAddPhotos) return null;

    return _MomentDetailsFAB(
      onCameraTap: () => _pickFromCameraForMoment(mediaType: 'photo'),
      onVideoTap: () => _pickFromCameraForMoment(mediaType: 'video'),
      onGalleryTap: _pickFromGalleryForMoment,
    );
  }

  Future<void> _pickFromCameraForMoment({required String mediaType}) async {
    final firstMoment = _moments.isNotEmpty ? _moments.first : null;
    if (firstMoment == null) return;

    try {
      final imagePicker = picker.ImagePicker();
      picker.XFile? file;

      if (mediaType == 'photo') {
        file = await imagePicker.pickImage(source: picker.ImageSource.camera);
      } else {
        file = await imagePicker.pickVideo(
          source: picker.ImageSource.camera,
          maxDuration: const Duration(seconds: 60),
        );
      }

      if (file == null || !mounted) return;

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddMomentPage(
            mediaPath: file!.path,
            isVideo: mediaType == 'video',
            initialLatitude: firstMoment.latitude,
            initialLongitude: firstMoment.longitude,
          ),
        ),
      );

      if (result == true && mounted) {
        ref.invalidate(momentsStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error opening camera: $e');
      }
    }
  }

  Future<void> _pickFromGalleryForMoment() async {
    final firstMoment = _moments.isNotEmpty ? _moments.first : null;
    if (firstMoment == null) return;

    try {
      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 10,
          requestType: pm.RequestType.common,
          specialPickerType: SpecialPickerType.noPreview,
        ),
      );

      if (assets == null || assets.isEmpty || !mounted) return;

      final List<String> mediaPaths = [];
      bool hasVideo = false;
      int? videoDuration;

      for (final asset in assets) {
        final file = await asset.file;
        if (file != null) {
          mediaPaths.add(file.path);
          if (asset.type == AssetType.video) {
            hasVideo = true;
            videoDuration = asset.duration;
          }
        }
      }

      if (mediaPaths.isEmpty || !mounted) return;

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddMomentPage(
            mediaPaths: mediaPaths,
            isVideo: hasVideo,
            videoDuration: videoDuration ?? 0,
            initialLatitude: firstMoment.latitude,
            initialLongitude: firstMoment.longitude,
          ),
        ),
      );

      if (result == true && mounted) {
        ref.invalidate(momentsStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error picking media: $e');
      }
    }
  }

  // ─── HEADER ───────────────────────────────────────────────────────

  /// Action buttons (save) used in the app bar — share moved to inline row
  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        onPressed: _isSavingOffline ? null : _saveAllOffline,
        icon: _isSavingOffline
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryBlue,
                ),
              )
            : HugeIcon(
                icon: _allSavedOffline
                    ? HugeIcons.strokeRoundedCheckmarkCircle02
                    : HugeIcons.strokeRoundedDownloadCircle02,
                size: 22.sp,
                color: _allSavedOffline ? Colors.green : AppTheme.textDark,
              ),
        tooltip: _allSavedOffline ? 'Saved offline' : 'Save offline',
      ),
    ];
  }

  Widget _buildSummaryCard() {
    final momentCount = _moments.length;
    final locationAddress = widget.locationName;
    final hasAddress = locationAddress.isNotEmpty;
    final dateRange = _getDateRange();
    final title = _moments.isNotEmpty ? _moments.first.title : 'Moments';

    return GestureDetector(
      onLongPress: () {
        if (_moments.isNotEmpty && _isOwnMoment(_moments[_currentPage])) {
          HapticService.mediumTap();
          _showTitlePrivacyMenu();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // ── Inline engagement row: comment + share ──
            if (_moments.isNotEmpty) _buildEngagementRow(),
            const SizedBox(height: 14),
            // ── Editorial title ──
            if (_moments.isNotEmpty && _moments[_currentPage].isPrivate)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _showPrivacyDropdown(
                    context,
                    _moments[_currentPage],
                    _currentPage,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.emergencyRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedSquareLock02,
                          size: 13,
                          color: AppTheme.emergencyRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Private',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.emergencyRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                letterSpacing: -0.8,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            // ── Metadata line ──
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _buildMetaItem(CupertinoIcons.calendar, dateRange),
                _buildMetaItem(
                  CupertinoIcons.photo_on_rectangle,
                  '$momentCount moment${momentCount == 1 ? '' : 's'}',
                ),
                if (hasAddress)
                  _buildMetaItem(
                    CupertinoIcons.location_solid,
                    locationAddress,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Thin divider ──
            Container(
              height: 0.5,
              color: AppTheme.borderGray.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 14),
            // ── Contributors row ──
            _buildContributorRowInline(),
            const SizedBox(height: 12),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textGray),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textGray,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildContributorRowInline() {
    if (_getAvatarsToDisplay().isEmpty && _contributors.isEmpty && !_isOwner) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _showContributorsModal,
      child: Row(
        children: [
          if (_getAvatarsToDisplay().isNotEmpty)
            _buildAvatarStack()
          else if (_isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedUserAdd01,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Invite friends',
                    style: GoogleFonts.inter(
                      textStyle: Theme.of(context).textTheme.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          if (_contributors.length > 1) ...[
            const SizedBox(width: 8),
            Text(
              '+${_contributors.length - 1}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    bool edgeToEdge = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: edgeToEdge ? 0 : 24,
        vertical: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: edgeToEdge ? 20 : 0),
            child: Container(
              height: 0.5,
              color: AppTheme.borderGray.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: edgeToEdge ? 20 : 0),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppTheme.textGray,
              ),
            ),
          ),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── CAROUSEL ─────────────────────────────────────────────────────

  Widget _buildCarousel(double availableHeight, double bottomOffset) {
    return CarouselSlider.builder(
      itemCount: _moments.length,
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 0.72,
        enlargeCenterPage: true,
        enlargeFactor: 0.18,
        enableInfiniteScroll: false,
        initialPage: widget.initialPage,
        onPageChanged: (index, reason) {
          _currentPage = index;
          _prewarmVideoControllers();
          HapticService.cardSnap();
        },
      ),
      itemBuilder: (context, index, realIndex) {
        return _buildCarouselCard(index);
      },
    );
  }

  Widget _buildCarouselCard(int index) {
    final moment = _moments[index];
    final imageUrl = _imageUrls[moment.id];

    final scale = (index < _scales.length ? _scales[index] : 0.85).clamp(
      0.01,
      1.0,
    );
    final opacity = index < _opacities.length
        ? _opacities[index].clamp(0.0, 1.0)
        : 0.0;
    final rotation = 0.0; // Clean editorial style — no rotation

    return GestureDetector(
      onTap: () => _openRelive(index),
      onDoubleTap: () => _handleDoubleTapHeart(index),
      onLongPressStart: (details) {
        HapticService.longPress();
        _showMomentActionsMenu(moment, imageUrl, details.globalPosition);
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
                  maxWidth: 320,
                  maxHeight: 500,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Privacy tag
                    if (moment.isPrivate) _buildPrivacyTag(moment, index),
                    // Image card
                    _buildImageCard(moment, imageUrl, index),
                    // Caption + date only
                    _buildCardFooter(moment),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openRelive(int index) {
    HapticService.lightTap();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ReliveExperiencePage(
          moments: _moments,
          locationName: widget.locationName,
          initialIndex: index,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildPrivacyTag(Moment moment, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => _showPrivacyDropdown(context, moment, index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.emergencyRed,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSquareLock02,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'Private',
                  style: GoogleFonts.inter(
                    textStyle: Theme.of(context).textTheme.labelSmall,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(Moment moment, String? imageUrl, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMediaContent(moment, imageUrl),
              // Heart animation
              if (_showingHeartAtIndex == index)
                Center(
                  child: HeartAnimation(size: 120, isLike: _isLikeAnimation),
                ),
              // Heart count
              _buildHeartBadge(index),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeartBadge(int index) {
    final count = _photoHeartCounts[index] ?? 0;
    final userHearted = _userHeartedPhoto[index] == true;

    if (count > 1) {
      return Positioned(
        bottom: 8,
        right: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                userHearted ? Icons.favorite : Icons.favorite_border,
                size: 14,
                color: userHearted ? Colors.red : Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: GoogleFonts.inter(
                  textStyle: Theme.of(context).textTheme.labelSmall,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (count == 1 && userHearted) {
      return Positioned(
        bottom: 8,
        right: 8,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.heart_fill,
            size: 14,
            color: Colors.red,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCardFooter(Moment moment) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, left: 8.0, right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (moment.caption != null && moment.caption!.isNotEmpty)
            Text(
              moment.caption!,
              style: GoogleFonts.spaceMono(
                textStyle: Theme.of(context).textTheme.bodyMedium,
                color: AppTheme.textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  // ─── BOTTOM SECTIONS ──────────────────────────────────────────────

  Widget _buildAudioNotesSection() {
    return CollaborativeAudioList(
      moments: _moments,
      userAvatars: _userAvatars,
      userNames: _userNames,
    );
  }

  Widget _buildMusicSection() {
    final momentsWithMusic = _moments
        .where((m) => m.musicData != null)
        .toList();
    if (momentsWithMusic.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        height: 52,
        child: Center(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: momentsWithMusic.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final music = momentsWithMusic[index].musicData!;
              return MusicPlayerWidget(musicData: music, compact: true);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for realtime updates
    if (_groupId != null) {
      ref.listen(momentsByGroupStreamProvider(_groupId!), (previous, next) {
        next.whenData((updatedMoments) {
          _handleMomentsStreamUpdate(updatedMoments);
        });
      });
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate how much space bottom sections need
    final hasAudioNotes = _moments.any((m) => m.audioPath != null);
    final hasMusic = _moments.any((m) => m.musicData != null);

    // Carousel gets most of the screen height
    final carouselHeight = screenHeight * 0.52;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Collapsing SliverAppBar — expands to show location, collapses to compact bar
            SliverAppBar(
              pinned: false,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppTheme.backgroundBeige,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0.5,

              leading: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/Left arrow.svg',
                    width: 34.w,
                    height: 34.h,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: _buildAppBarActions(),
            ),
            // Carousel with fixed height
            SliverToBoxAdapter(
              child: SizedBox(
                height: carouselHeight,
                child: _buildCarousel(carouselHeight, 0),
              ),
            ),
            // Editorial metadata section below carousel
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 8),
                    child: Text(
                      'Tap to relive  •  Double-tap to ♥',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textGray.withValues(alpha: 0.45),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Audio notes section at bottom
            if (hasMusic)
              SliverToBoxAdapter(
                child: _buildSectionCard(
                  title: 'Soundtrack',
                  child: _buildMusicSection(),
                  edgeToEdge: true,
                ),
              ),
            if (hasAudioNotes)
              SliverToBoxAdapter(
                child: _buildSectionCard(
                  title: 'Audio Notes',
                  child: _buildAudioNotesSection(),
                  edgeToEdge: true,
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: 80 + bottomPadding)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Moment Details FAB – 3-option speed dial (Camera, Video, Gallery)
// =============================================================================

class _MomentDetailsFAB extends StatefulWidget {
  const _MomentDetailsFAB({
    required this.onCameraTap,
    required this.onVideoTap,
    required this.onGalleryTap,
  });

  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onVideoTap;

  @override
  State<_MomentDetailsFAB> createState() => _MomentDetailsFABState();
}

class _MomentDetailsFABState extends State<_MomentDetailsFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  void _toggle() {
    HapticService.lightTap();
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  void _handleAction(VoidCallback action) {
    HapticService.mediumTap();
    _toggle();
    Future.delayed(const Duration(milliseconds: 200), action);
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SpringButton(
      onTap: onTap,
      scaleFactor: 0.9,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded options (appear above the main button)
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 2, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildOption(
                      icon: CupertinoIcons.photo_on_rectangle,
                      label: 'Gallery',
                      color: AppTheme.brightYellow,
                      textColor: Colors.black,
                      onTap: () => _handleAction(widget.onGalleryTap),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildOption(
                      icon: CupertinoIcons.video_camera_solid,
                      label: 'Video',
                      color: AppTheme.coralPink,
                      textColor: Colors.white,
                      onTap: () => _handleAction(widget.onVideoTap),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildOption(
                      icon: CupertinoIcons.camera_fill,
                      label: 'Camera',
                      color: Colors.white,
                      textColor: AppTheme.primaryBlue,
                      onTap: () => _handleAction(widget.onCameraTap),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Main FAB button
        SpringButton(
          onTap: _toggle,
          scaleFactor: 0.9,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
