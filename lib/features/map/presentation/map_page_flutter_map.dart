import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:wechat_assets_picker/wechat_assets_picker.dart' hide LatLng;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/map_cache_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/quick_actions_service.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../data/models/moment.dart';
import '../../../widgets/blurred_app_bar.dart';
import '../../../widgets/spring_button.dart';
import '../../moments/presentation/add_moment_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../moments/presentation/moment_details_page.dart';
import '../../social/presentation/friends_page.dart';
import '../../moments/presentation/timeline_gallery_page.dart';
import '../../profile/profile_page.dart';
import '../widgets/stacked_moment_marker.dart';
import '../widgets/friend_moments_stack.dart';
import '../widgets/friends_in_view_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moments/data/models/user_profile.dart';
import 'package:moments/data/services/user_profile_service.dart';

import 'package:moments/core/providers/providers.dart';

import 'package:moments/features/map/utils/map_logic_service.dart';
import 'package:moments/features/map/providers/map_control_provider.dart';

final _log = AppLogger('MapPage');

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key, this.scrollController});

  /// Scroll controller from BottomBar (not used for maps but needed for consistency)
  final ScrollController? scrollController;

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  String _cityName = 'Loading...';
  LocationData? _currentPosition;
  final MapCacheService _mapCacheService = MapCacheService();
  final MapController _mapController = MapController();
  final ValueNotifier<double> _zoomNotifier = ValueNotifier(14.0);
  bool _isMapReady = false; // Flag to track if map is rendered
  double _lastThreshold =
      -1; // Track last threshold to prevent excessive rebuilds

  // Dynamic viewport location
  LatLng? _mapCenterPosition;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMap();
    _initializeQuickActions();

    // Check for Year in Review (December only)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkYearInReview();
    });
  }

  /// Initialize home screen quick actions (long-press shortcuts)
  void _initializeQuickActions() {
    QuickActionsService().initialize(
      onShortcutSelected: (String shortcutType) {
        // Handle the shortcut after the app is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleQuickAction(shortcutType);
        });
      },
    );
  }

  /// Handle quick action shortcut selection
  void _handleQuickAction(String shortcutType) {
    switch (shortcutType) {
      case QuickActionType.camera:
        // Pass 'photo' to skip the dialog and go straight to camera
        _pickFromCamera(mediaType: 'photo');
        break;
      case QuickActionType.video:
        // Pass 'video' to skip the dialog and go straight to video recorder
        _pickFromCamera(mediaType: 'video');
        break;
      case QuickActionType.gallery:
        _pickFromGallery();
        break;
    }
  }

  void _checkYearInReview() async {
    final now = DateTime.now();
    // Only show in December (Month 12)
    if (now.month != 12) return;

    // Check if already dismissed for this year
    final prefs = await SharedPreferences.getInstance();
    final dismissedYear = prefs.getInt('year_in_review_dismissed_year');
    if (dismissedYear == now.year) return; // Already dismissed for this year

    if (!mounted) return;

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(
          '${now.year} Wrapped is here! See your year in moments.',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1DB954),
        leading: const Icon(Icons.auto_awesome, color: Colors.white),
        actions: [
          TextButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              // Mark as dismissed for this year
              await prefs.setInt('year_in_review_dismissed_year', now.year);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: Text(
              'VIEW',
              style: GoogleFonts.bebasNeue(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              // Mark as dismissed for this year
              await prefs.setInt('year_in_review_dismissed_year', now.year);
            },
            child: Text(
              'DISMISS',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _geocodeDebounce?.cancel();
    _zoomNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, check location permissions/status again
    // But skip if we just navigated from a notification (to preserve target location)
    if (state == AppLifecycleState.resumed) {
      final notifier = ref.read(mapCameraTargetProvider.notifier);
      if (notifier.skipNextLocationUpdate) {
        notifier.clearSkipFlag();
        return; // Skip location update to preserve notification navigation target
      }
      _getCurrentLocation();
    }
  }

  Future<void> _initializeMap() async {
    try {
      // Initialize map caching first
      await _mapCacheService.initialize();
      await _getCurrentLocation();
      await _loadCityName();
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to load map: $e');
      }
    }
  }

  Future<void> _loadCityName() async {
    if (_currentPosition != null) {
      final city = await GeocodingService.getCityFromCoordinates(
        _currentPosition!.latitude!,
        _currentPosition!.longitude!,
      );
      if (mounted) {
        setState(() => _cityName = city);
      }
    }
  }

  /// Update location name based on current viewport center (debounced)
  Future<void> _updateLocationFromViewport() async {
    if (_mapCenterPosition == null) return;

    try {
      final city = await GeocodingService.getCityFromCoordinates(
        _mapCenterPosition!.latitude,
        _mapCenterPosition!.longitude,
      );
      if (mounted && city.isNotEmpty) {
        setState(() => _cityName = city);
      }
    } catch (e) {
      _log.e('Failed to geocode viewport center: $e');
    }
  }

  void _onMapReady() {
    setState(() {
      _isMapReady = true;
    });
    // Trigger location update now that map is ready
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = Location();

      // Check if location services are enabled
      bool serviceEnabled = await location.serviceEnabled();
      _log.d('Location service enabled: $serviceEnabled');
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _log.w('User declined to enable location service');
          return;
        }
      }

      // Check permission status
      PermissionStatus permission = await location.hasPermission();
      _log.d('Location permission: $permission');

      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission == PermissionStatus.denied) {
          _log.w('User denied location permission');
          return;
        }
      }

      if (permission == PermissionStatus.deniedForever) {
        _log.w('Location permission denied forever');
        return;
      }

      // Get the current position
      _log.d('Getting location...');
      final position = await location.getLocation();
      _log.d(
        'Got location: lat=${position.latitude}, lng=${position.longitude}',
      );

      if (mounted && position.latitude != null && position.longitude != null) {
        // Check if coordinates are valid (not 0,0 which is ocean)
        if (position.latitude == 0.0 && position.longitude == 0.0) {
          _log.w('Location is (0,0) - likely invalid!');
        }

        setState(() => _currentPosition = position);

        // Auto-center map to user's location if map is ready
        if (_isMapReady) {
          try {
            _mapController.move(
              LatLng(position.latitude!, position.longitude!),
              14.0,
            );
            _log.d(
              '📍 Map moved to: ${position.latitude}, ${position.longitude}',
            );
          } catch (e) {
            _log.e('⚠️ Error moving map: $e');
          }
        } else {
          _log.d('📍 Map not ready yet, skipping auto-center');
        }

        // Ensure city name is updated effectively
        _loadCityName();
      } else {
        _log.w('Location has null coordinates or widget not mounted');
      }
    } catch (e) {
      _log.e('Error getting location: $e');
    }
  }

  // Removed: _groupMomentsByPlace, _applyZoomClustering, _calculateClusterThreshold, _applyProximityOffsets
  // Logic moved to MapLogicService

  /// Build cluster badge showing number of locations and moments
  Widget _buildClusterBadge(int locationCount, int momentCount) {
    return Transform.rotate(
      angle: 0.05, // Slight tilt for neubrutalism style
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderBlack, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Colors.white, size: 12),
            const SizedBox(width: 2),
            Text(
              '$locationCount',
              style: GoogleFonts.bangers(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Container(
              width: 1,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const Icon(Icons.photo_library, color: Colors.white, size: 12),
            const SizedBox(width: 2),
            Text(
              '$momentCount',
              style: GoogleFonts.bangers(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPlaceMarkerTapped(
    List<Moment> moments,
    String placeName,
    int markerIndex,
  ) {
    // Haptic feedback on tap
    HapticService.mediumTap();

    // Use moments in chronological order (newest first, as they come from database)
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MomentDetailsPage(
                  locationName: placeName,
                  moments:
                      moments, // Use original order - topmost card is first
                  heroTag: null, // No Hero, just spring animations
                  initialPage: 0, // Start with topmost card (newest moment)
                ),
            transitionDuration: const Duration(
              milliseconds: 200,
            ), // Reduced from 300ms
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Simple fade in transition with spring curve
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut, // Smoother curve
                    ),
                    child: child,
                  );
                },
          ),
        )
        .whenComplete(() {
          // Invalidate cache to refresh moments after navigation
          ref.invalidate(momentsStreamProvider);
        });
  }

  // Removed - replaced with AnimatedFAB widget

  // Removed - replaced with AnimatedFAB widget

  /// Build the friends-in-view avatar stack widget
  Widget _buildFriendsInViewStack(List<Moment> visibleMoments) {
    // Get current map viewport bounds safely
    if (!_isMapReady) return const SizedBox.shrink();

    LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (e) {
      _log.e('⚠️ Error getting map bounds: $e');
      return const SizedBox.shrink();
    }

    // Filter moments to only those within the current viewport
    final momentsInViewport = visibleMoments.where((m) {
      return m.latitude >= bounds.south &&
          m.latitude <= bounds.north &&
          m.longitude >= bounds.west &&
          m.longitude <= bounds.east;
    }).toList();

    // Group moments by friend (exclude current user's moments)
    final currentUserId = _authService.currentUser?.id;
    final friendMoments = momentsInViewport
        .where((m) => m.userId != null && m.userId != currentUserId)
        .toList();

    if (friendMoments.isEmpty) return const SizedBox.shrink();

    // Get unique user IDs
    final userIds = friendMoments.map((m) => m.userId!).toSet().toList();

    // Use FutureBuilder to fetch profiles
    return FutureBuilder<List<UserProfile>>(
      future: UserProfileService.getUserProfiles(userIds),
      builder: (context, snapshot) {
        // Build profile map
        final profileMap = <String, UserProfile>{};
        if (snapshot.hasData) {
          for (final profile in snapshot.data!) {
            profileMap[profile.id] = profile;
          }
        }

        // Group moments by friend with profile data
        final friendGroups = <String, FriendMomentGroup>{};
        for (final moment in friendMoments) {
          final odId = moment.userId!;
          final profile = profileMap[odId];

          if (!friendGroups.containsKey(odId)) {
            friendGroups[odId] = FriendMomentGroup(
              odId: odId,
              displayName: profile?.displayName ?? 'Friend',
              avatarUrl: profile?.avatarUrl,
              moments: [],
            );
          }
          // Add moment to existing group
          final existingGroup = friendGroups[odId]!;
          friendGroups[odId] = FriendMomentGroup(
            odId: existingGroup.odId,
            displayName: existingGroup.displayName,
            avatarUrl: existingGroup.avatarUrl,
            moments: [...existingGroup.moments, moment],
          );
        }

        final groups = friendGroups.values.toList()
          ..sort((a, b) => b.moments.length.compareTo(a.moments.length));

        return FriendMomentsStack(
          friendGroups: groups,
          onTap: () => showFriendsInViewSheet(
            context,
            friendGroups: groups,
            locationName: _cityName,
          ),
        );
      },
    );
  }

  /// Ensure location is available, fetching it if necessary
  Future<bool> _ensureLocation() async {
    if (_currentPosition != null) return true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting location...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    await _getCurrentLocation();

    if (_currentPosition == null && mounted) {
      context.showErrorSnackBar('Unable to get current location');
      return false;
    }
    return true;
  }

  Future<void> _pickFromCamera({String? mediaType}) async {
    if (!await _ensureLocation()) return;

    // If mediaType is not provided, show dialog
    String? selectedMediaType = mediaType;
    if (selectedMediaType == null) {
      selectedMediaType = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Capture'),
          content: const Text('What would you like to capture?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'photo'),
              child: const Text('Photo'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'video'),
              child: const Text('Video'),
            ),
          ],
        ),
      );
    }

    if (selectedMediaType == null || !mounted) return;

    try {
      final imagePicker = picker.ImagePicker();
      picker.XFile? file;

      if (selectedMediaType == 'photo') {
        file = await imagePicker.pickImage(source: picker.ImageSource.camera);
      } else {
        file = await imagePicker.pickVideo(
          source: picker.ImageSource.camera,
          maxDuration: const Duration(seconds: 60),
        );
      }

      if (file == null || !mounted) return;

      // Re-check location as it might be lost if app was killed/restarted
      if (!await _ensureLocation()) return;

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddMomentPage(
            mediaPath: file!.path,
            isVideo: selectedMediaType == 'video',
            initialLatitude: _currentPosition!.latitude!,
            initialLongitude: _currentPosition!.longitude!,
          ),
        ),
      );

      // Invalidate moments cache to refresh if moment was created successfully
      if (result == true && mounted) {
        ref.invalidate(momentsStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error opening camera: $e');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (!await _ensureLocation()) return;

    try {
      // Use wechat_assets_picker to pick images and videos
      final List<AssetEntity>? assets = await AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 10, // Allow up to 10 media files
          requestType: RequestType.common, // Support both images and videos
          specialPickerType: SpecialPickerType.noPreview,
        ),
      );

      if (assets == null || assets.isEmpty || !mounted) return;

      // Convert assets to file paths and check types
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

      // Navigate to AddMomentPage
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddMomentPage(
            mediaPaths: mediaPaths,
            isVideo: hasVideo,
            videoDuration: videoDuration ?? 0,
            initialLatitude: _currentPosition!.latitude!,
            initialLongitude: _currentPosition!.longitude!,
          ),
        ),
      );

      // Invalidate moments cache to refresh if moment was created successfully
      if (result == true && mounted) {
        ref.invalidate(momentsStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error picking media: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for external camera move requests (e.g. from notifications)
    ref.listen<LatLng?>(mapCameraTargetProvider, (previous, next) {
      if (next != null) {
        if (_isMapReady) {
          try {
            _mapController.move(next, 16.0); // Zoom level 16 for close-up
            // Reset the provider so we don't re-trigger on rebuilds
            ref.read(mapCameraTargetProvider.notifier).setTarget(null);
          } catch (e) {
            _log.e('⚠️ Error moving map to target: $e');
          }
        } else {
          // If map isn't ready, we should probably keep the target in the provider
          // so it can be handled when the map becomes ready.
          // For now, just log it.
          _log.w('⚠️ Map not ready for camera move request');
        }
      }
    });

    // Watch the moments stream from Riverpod
    final momentsAsync = ref.watch(momentsStreamProvider);
    // Notification count now includes friend requests + collab invites + system notifications
    final notificationCount = ref.watch(notificationCountProvider).value ?? 0;

    return momentsAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        body: Center(
          child: lottie.Lottie.asset(
            'assets/animations/loading.json',
            width: 150,
            height: 150,
          ),
        ),
      ),
      error: (error, stackTrace) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundBeige,
          body: Center(child: Text('Error loading moments: $error')),
        );
      },
      data: (moments) {
        // Filter out friends' private moments - only show:
        // 1. User's own moments (always visible to self)
        // 2. Friends' public moments (isPrivate == false)
        final currentUserId = _authService.currentUser?.id;
        final visibleMoments = moments.where((m) {
          return m.userId == currentUserId || !m.isPrivate;
        }).toList();

        // Group moments by place
        // Removed: final placeGroups = _groupMomentsByPlace(moments);
        return Scaffold(
          backgroundColor: AppTheme.backgroundBeige,
          extendBodyBehindAppBar: true,
          appBar: BlurredAppBar(
            title: 'MOMENTS',
            profileImageUrl: _authService.currentUserPhotoUrl,
            notificationCount: notificationCount,
            onMenuPressed: () {}, // Menu functionality to be implemented
            onProfilePressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            onFriendsPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsPage()),
              );
            },
            onNotificationsPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
          body: Stack(
            children: [
              // Flutter Map with Mapbox tiles
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  onMapReady: _onMapReady,
                  initialCenter: _currentPosition != null
                      ? LatLng(
                          _currentPosition!.latitude!,
                          _currentPosition!.longitude!,
                        )
                      : const LatLng(0, 0),
                  initialZoom: 18.0,
                  minZoom: 5.0,
                  maxZoom: 22.0,
                  onPositionChanged: (position, hasGesture) {
                    // Update map center for dynamic location tracking
                    _mapCenterPosition = position.center;

                    // Debounce geocoding to prevent API spam during scroll
                    _geocodeDebounce?.cancel();
                    _geocodeDebounce = Timer(
                      const Duration(milliseconds: 500),
                      () {
                        _updateLocationFromViewport();
                      },
                    );

                    // Update zoom notifier ONLY if the clustering threshold changes
                    final newThreshold = MapLogicService.getClusterThreshold(
                      position.zoom,
                    );
                    if (newThreshold != _lastThreshold) {
                      _lastThreshold = newThreshold;
                      _zoomNotifier.value = position.zoom;
                    }
                  },
                ),
                children: [
                  // Mapbox Streets v11 - 512px tiles (@2x) shown at 256px size for Retina quality
                  TileLayer(
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/512/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoid29sZmVsZW8iLCJhIjoiY21oYXRxMW82MW5nNjJqcGc4aDA0YndoeSJ9.gvLhQFM-46KlcUdAKFGMYg',
                    userAgentPackageName: 'com.moments.app',
                    // Use FMTC tile provider if available, otherwise fallback to network provider
                    tileProvider:
                        _mapCacheService.tileProvider ?? NetworkTileProvider(),
                    tileSize:
                        512, // Critical: Draw 512px image into 256px space for HiDPI/Retina crispness
                    zoomOffset:
                        -1, // Mapbox 512 tiles are 1 zoom level offset from standard 256 grid
                    panBuffer:
                        2, // Load more tiles around the screen for smoother panning
                  ),

                  // User location marker (BEFORE moment markers so it appears below)
                  if (_currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            _currentPosition!.latitude!,
                            _currentPosition!.longitude!,
                          ),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.3,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Moment markers layer (AFTER location so they appear on top)
                  // Use ValueListenableBuilder to rebuild ONLY markers when zoom changes
                  ValueListenableBuilder<double>(
                    valueListenable: _zoomNotifier,
                    builder: (context, zoom, child) {
                      // Group moments by place using the extracted service
                      final placeGroups = MapLogicService.groupMomentsByPlace(
                        visibleMoments,
                        zoom,
                      );

                      return MarkerLayer(
                        markers: placeGroups.asMap().entries.map((entry) {
                          final placeGroup = entry.value;
                          final moments = placeGroup['moments'] as List<Moment>;
                          final lat = placeGroup['lat'] as double;
                          final lng = placeGroup['lng'] as double;
                          final placeName = placeGroup['placeName'] as String;
                          final isCluster =
                              placeGroup['isCluster'] as bool? ?? false;
                          final clusterCount =
                              placeGroup['clusterCount'] as int? ?? 1;

                          // Create a stable key based on moment IDs to prevent unnecessary rebuilds
                          final markerKey = moments.map((m) => m.id).join('_');

                          return Marker(
                            point: LatLng(lat, lng),
                            width: 160, // Slightly wider for cluster badge
                            height: 200, // Taller for cluster badge
                            key: ValueKey(markerKey),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                StackedMomentMarker(
                                  key: ValueKey('marker_$markerKey'),
                                  moments: moments,
                                  onTap: () => _onPlaceMarkerTapped(
                                    moments,
                                    placeName,
                                    0,
                                  ),
                                  heroTag: null,
                                ),
                                // Cluster count badge (only show if multiple groups clustered)
                                if (isCluster && clusterCount > 1)
                                  Positioned(
                                    bottom: -5,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: _buildClusterBadge(
                                        clusterCount,
                                        moments.length,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),

              // City name sticker - Neubrutalism Style with Playful Tilt
              Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.rotate(
                    angle: -0.01, // Slight playful tilt
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: ShapeDecoration(
                        color: AppTheme.cardWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.textDark, width: 2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _cityName,
                            style: GoogleFonts.bangers(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textDark,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Friends in view avatar stack (bottom-right)
              Positioned(
                bottom: AppTheme.spacing32 + 80, // Above FAB
                right: 16,
                child: _buildFriendsInViewStack(visibleMoments),
              ),

              // Animated FAB - positioned above floating dock
              Positioned(
                bottom:
                    100, // Space for floating dock (64 height + 24 margin + padding)
                left: 0,
                right: 0,
                child: Center(
                  child: _AnimatedFAB(
                    onCameraTap: _pickFromCamera,
                    onGalleryTap: _pickFromGallery,
                  ),
                ),
              ),

              // Mapbox attribution (required)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '© Mapbox © OpenStreetMap',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Animated FAB Widget with Motor animations
class _AnimatedFAB extends StatefulWidget {
  const _AnimatedFAB({required this.onCameraTap, required this.onGalleryTap});

  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  @override
  State<_AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<_AnimatedFAB>
    with SingleTickerProviderStateMixin {
  // FAB dimensions - grow both width and height
  static const double _collapsedHeight = 60.0;

  static const double _collapsedWidth = 198.0; // Stable width for resting FAB
  static const double _expandedHeight =
      80.0; // Proportional height for 2 buttons

  late final AnimationController _controller;
  late final Animation<double> _heightAnimation;
  bool _isExpanded = false;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _widthAnimation;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Height animation
    _heightAnimation =
        Tween<double>(begin: _collapsedHeight, end: _expandedHeight).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOutCubicEmphasized,
          ),
        );

    // Width animation (grow from stable collapsed width to expanded width)
    _widthAnimation =
        Tween<double>(
          begin: _collapsedWidth,
          end: 320.0, // Wide enough for camera + gallery + close
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOutCubicEmphasized,
          ),
        );

    // Opacity animation for text fade
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void _toggleExpansion() {
    HapticService.lightTap();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _handleCameraTap() {
    HapticService.mediumTap();
    _toggleExpansion();
    Future.delayed(const Duration(milliseconds: 300), widget.onCameraTap);
  }

  void _handleGalleryTap() {
    HapticService.mediumTap();
    _toggleExpansion();
    Future.delayed(const Duration(milliseconds: 300), widget.onGalleryTap);
  }

  Widget _buildCollapsedContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.plus,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _opacityAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: const Text(
                  'New Moment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16.5,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Camera Button
          SpringButton(
            onTap: _handleCameraTap,
            scaleFactor: 0.95,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.camera,
                    size: 20,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Camera',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Gallery Button
          SpringButton(
            onTap: _handleGalleryTap,
            scaleFactor: 0.95,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.brightYellow,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.photo,
                    size: 20,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Gallery',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 5),

          // Close button (X) - static, no animation
          SpringButton(
            onTap: _toggleExpansion,
            scaleFactor: 0.9,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: SvgPicture.asset(
                'assets/icons/Close.svg',
                width: 36,
                height: 36,
                allowDrawingOutsideViewBox: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Switch content only after width has grown past a threshold to avoid cramped layout
        final showExpanded =
            _isExpanded && _widthAnimation.value >= (_collapsedWidth + 40);

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: _collapsedWidth,
              maxWidth: _widthAnimation.value,
            ),
            child: SpringButton(
              onTap: _toggleExpansion,
              scaleFactor: 0.95,
              child: Container(
                width: _widthAnimation.value,
                height: _heightAnimation.value,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  border: Border.all(color: Colors.black, width: 2.5),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: showExpanded
                      ? _buildExpandedContent()
                      : _buildCollapsedContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
