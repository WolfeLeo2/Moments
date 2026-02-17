import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:wechat_assets_picker/wechat_assets_picker.dart'
    hide LatLng, RequestType;
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart' as latlong2;

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/quick_actions_service.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/moment.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/services/user_profile_service.dart';
import '../../../widgets/blurred_app_bar.dart';
import '../../../widgets/spring_button.dart';
import '../../moments/presentation/add_moment_page.dart';
import '../../moments/presentation/moment_details_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../social/presentation/friends_page.dart';
import '../../profile/profile_page.dart';
import '../widgets/friend_moments_stack.dart';
import '../widgets/friends_in_view_sheet.dart';
import '../utils/map_logic_service.dart';
import '../providers/map_control_provider.dart';
import 'package:moments/core/services/app_logger.dart';

final _log = AppLogger('MapboxMap');

/// Mapbox access token - hardcoded for now
const String _mapboxAccessToken =
    'pk.eyJ1Ijoid29sZmVsZW8iLCJhIjoiY21oYXRxMW82MW5nNjJqcGc4aDA0YndoeSJ9.gvLhQFM-46KlcUdAKFGMYg';

class MapPageMapbox extends ConsumerStatefulWidget {
  const MapPageMapbox({super.key});

  @override
  ConsumerState<MapPageMapbox> createState() => _MapPageMapboxState();
}

class _MapPageMapboxState extends ConsumerState<MapPageMapbox>
    with WidgetsBindingObserver {
  AuthService get _authService => ref.read(authServiceProvider);
  String _cityName = 'Loading...';
  LocationData? _currentPosition;
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  bool _isMapReady = false;

  // Track annotations for tap handling
  final Map<String, List<Moment>> _annotationMoments = {};

  // Dynamic viewport location
  Position? _mapCenterPosition;
  Timer? _geocodeDebounce;
  double _currentZoom = 14.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set Mapbox access token
    MapboxOptions.setAccessToken(_mapboxAccessToken);
    _initializeLocation();
    _initializeQuickActions();

    // Check for Year in Review (December only)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkYearInReview();
    });
  }

  void _initializeQuickActions() {
    QuickActionsService().initialize(
      onShortcutSelected: (String shortcutType) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleQuickAction(shortcutType);
        });
      },
    );
  }

  void _handleQuickAction(String shortcutType) {
    switch (shortcutType) {
      case QuickActionType.camera:
        _pickFromCamera(mediaType: 'photo');
        break;
      case QuickActionType.video:
        _pickFromCamera(mediaType: 'video');
        break;
      case QuickActionType.gallery:
        _pickFromGallery();
        break;
    }
  }

  void _checkYearInReview() async {
    final now = DateTime.now();
    if (now.month != 12) return;

    final prefs = await SharedPreferences.getInstance();
    final dismissedYear = prefs.getInt('year_in_review_dismissed_year');
    if (dismissedYear == now.year) return;

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final notifier = ref.read(mapCameraTargetProvider.notifier);
      if (notifier.skipNextLocationUpdate) {
        notifier.clearSkipFlag();
        return;
      }
      _getCurrentLocation();
    }
  }

  Future<void> _initializeLocation() async {
    await _getCurrentLocation();
    await _loadCityName();
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

  Future<void> _updateLocationFromViewport() async {
    if (_mapCenterPosition == null) return;

    try {
      final city = await GeocodingService.getCityFromCoordinates(
        _mapCenterPosition!.lat.toDouble(),
        _mapCenterPosition!.lng.toDouble(),
      );
      if (mounted && city.isNotEmpty) {
        setState(() => _cityName = city);
      }
    } catch (e) {
      _log.e('Failed to geocode viewport center: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission == PermissionStatus.denied) return;
      }

      if (permission == PermissionStatus.deniedForever) return;

      final position = await location.getLocation();

      if (mounted && position.latitude != null && position.longitude != null) {
        setState(() => _currentPosition = position);

        if (_isMapReady && _mapboxMap != null) {
          await _mapboxMap!.flyTo(
            CameraOptions(
              center: Point(
                coordinates: Position(position.longitude!, position.latitude!),
              ),
              zoom: 14.0,
            ),
            MapAnimationOptions(duration: 1000),
          );
        }

        _loadCityName();
      }
    } catch (e) {
      _log.e('Error getting location: $e');
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Create annotation manager
    _annotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();

    // Set up tap listener
    _annotationManager!.tapEvents(
      onTap: (annotation) {
        final moments = _annotationMoments[annotation.id];
        if (moments != null && moments.isNotEmpty) {
          _onMomentMarkerTapped(moments);
        }
      },
    );

    setState(() {
      _isMapReady = true;
    });

    // Move to current location if available
    if (_currentPosition != null) {
      await _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(
              _currentPosition!.longitude!,
              _currentPosition!.latitude!,
            ),
          ),
          zoom: 14.0,
        ),
      );
    }
  }

  void _onCameraChanged(CameraChangedEventData data) async {
    // Get current camera position
    final cameraState = await _mapboxMap?.getCameraState();
    if (cameraState == null) return;

    final center = cameraState.center;
    _mapCenterPosition = center.coordinates;
    _currentZoom = cameraState.zoom;

    // Debounce geocoding
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 500), () {
      _updateLocationFromViewport();
    });
  }

  /// Build moment annotations from visible moments
  Future<void> _updateAnnotations(List<Moment> moments) async {
    if (_annotationManager == null) return;

    // Clear existing annotations
    await _annotationManager!.deleteAll();
    _annotationMoments.clear();

    // Group moments by place
    final placeGroups = MapLogicService.groupMomentsByPlace(
      moments,
      _currentZoom,
    );

    // Create annotations for each group
    for (final placeGroup in placeGroups) {
      final groupMoments = placeGroup['moments'] as List<Moment>;
      final lat = placeGroup['lat'] as double;
      final lng = placeGroup['lng'] as double;
      final frontMoment = groupMoments.first;

      // Try to load the moment image directly from URL
      Uint8List? imageBytes;
      final imageUrl = frontMoment.imageUrl;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final response = await HttpClient()
              .getUrl(Uri.parse(imageUrl))
              .then((req) => req.close());
          final bytes = await consolidateHttpClientResponseBytes(response);
          imageBytes = await _createCircularMarkerFromImage(bytes);
        } catch (e) {
          _log.e('Failed to load marker image: $e');
        }
      }

      final annotation = await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          image: imageBytes,
          // Use default marker if no image
          iconImage: imageBytes == null ? 'marker-15' : null,
          iconSize: imageBytes != null ? 0.5 : 1.5,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );

      // Track moments for this annotation
      _annotationMoments[annotation.id] = groupMoments;
    }
  }

  /// Create a circular marker image from raw image bytes
  Future<Uint8List?> _createCircularMarkerFromImage(
    Uint8List imageBytes,
  ) async {
    try {
      // Decode the image
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 100,
        targetHeight: 100,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Create a circular clipped version with border
      final size = 100.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw white circle background (border)
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

      // Clip to inner circle and draw image
      final clipPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(size / 2, size / 2),
            radius: size / 2 - 4,
          ),
        );
      canvas.clipPath(clipPath);

      // Draw the image centered
      final srcRect = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final dstRect = Rect.fromLTWH(4, 4, size - 8, size - 8);
      canvas.drawImageRect(image, srcRect, dstRect, Paint());

      // Convert to image bytes
      final picture = recorder.endRecording();
      final outputImage = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await outputImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      _log.e('Error creating circular marker: $e');
      return null;
    }
  }

  void _onMomentMarkerTapped(List<Moment> moments) {
    HapticService.mediumTap();

    final placeName = moments.first.location.split(',').first.trim();

    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MomentDetailsPage(
                  locationName: placeName,
                  moments: moments,
                  heroTag: null,
                  initialPage: 0,
                ),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ),
                    child: child,
                  );
                },
          ),
        )
        .whenComplete(() {
          ref.invalidate(momentsStreamProvider);
        });
  }

  Widget _buildFriendsInViewStack(List<Moment> visibleMoments) {
    if (!_isMapReady || _mapboxMap == null) return const SizedBox.shrink();

    final currentUserId = _authService.currentUser?.id;
    final friendMoments = visibleMoments
        .where((m) => m.userId != null && m.userId != currentUserId)
        .toList();

    if (friendMoments.isEmpty) return const SizedBox.shrink();

    final userIds = friendMoments.map((m) => m.userId!).toSet().toList();

    return FutureBuilder<List<UserProfile>>(
      future: UserProfileService.getUserProfiles(userIds),
      builder: (context, snapshot) {
        final profileMap = <String, UserProfile>{};
        if (snapshot.hasData) {
          for (final profile in snapshot.data!) {
            profileMap[profile.id] = profile;
          }
        }

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
            initialLatitude: _currentPosition!.latitude!,
            initialLongitude: _currentPosition!.longitude!,
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

  @override
  Widget build(BuildContext context) {
    // Listen for external camera move requests
    ref.listen<latlong2.LatLng?>(mapCameraTargetProvider, (previous, next) {
      if (next != null && _isMapReady && _mapboxMap != null) {
        _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(next.longitude, next.latitude)),
            zoom: 16.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
        ref.read(mapCameraTargetProvider.notifier).setTarget(null);
      }
    });

    final momentsAsync = ref.watch(momentsStreamProvider);
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
        final currentUserId = _authService.currentUser?.id;
        final visibleMoments = moments.where((m) {
          return m.userId == currentUserId || !m.isPrivate;
        }).toList();

        // Update annotations when moments change
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isMapReady) {
            _updateAnnotations(visibleMoments);
          }
        });

        return Scaffold(
          backgroundColor: AppTheme.backgroundBeige,
          extendBodyBehindAppBar: true,
          appBar: BlurredAppBar(
            title: 'MOMENTS',
            profileImageUrl: _authService.currentUserPhotoUrl,
            notificationCount: notificationCount,
            onMenuPressed: () {},
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
              // Mapbox Map
              MapWidget(
                key: const ValueKey('mapbox_map'),
                onMapCreated: _onMapCreated,
                cameraOptions: _currentPosition != null
                    ? CameraOptions(
                        center: Point(
                          coordinates: Position(
                            _currentPosition!.longitude!,
                            _currentPosition!.latitude!,
                          ),
                        ),
                        zoom: 14.0,
                      )
                    : CameraOptions(
                        center: Point(coordinates: Position(0, 0)),
                        zoom: 2.0,
                      ),
                styleUri: MapboxStyles.MAPBOX_STREETS,
                onCameraChangeListener: _onCameraChanged,
              ),

              // User location indicator overlay
              if (_currentPosition != null && _isMapReady)
                _UserLocationIndicator(
                  mapboxMap: _mapboxMap,
                  position: _currentPosition!,
                ),

              // City name sticker
              Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.rotate(
                    angle: -0.01,
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

              // Friends in view avatar stack
              Positioned(
                bottom: AppTheme.spacing32 + 80,
                right: 16,
                child: _buildFriendsInViewStack(visibleMoments),
              ),

              // Animated FAB
              Positioned(
                bottom: AppTheme.spacing32,
                left: 0,
                right: 0,
                child: Center(
                  child: _AnimatedFAB(
                    onCameraTap: _pickFromCamera,
                    onGalleryTap: _pickFromGallery,
                  ),
                ),
              ),

              // Mapbox attribution
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

/// User location indicator using Mapbox's location puck
class _UserLocationIndicator extends StatefulWidget {
  final MapboxMap? mapboxMap;
  final LocationData position;

  const _UserLocationIndicator({
    required this.mapboxMap,
    required this.position,
  });

  @override
  State<_UserLocationIndicator> createState() => _UserLocationIndicatorState();
}

class _UserLocationIndicatorState extends State<_UserLocationIndicator> {
  @override
  void initState() {
    super.initState();
    _setupLocationPuck();
  }

  void _setupLocationPuck() async {
    if (widget.mapboxMap == null) return;

    // Enable the default 2D location puck
    await widget.mapboxMap!.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: AppTheme.primaryBlue.value,
        showAccuracyRing: true,
        accuracyRingColor: AppTheme.primaryBlue.withValues(alpha: 0.2).value,
        accuracyRingBorderColor: AppTheme.primaryBlue.value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The location puck is rendered by Mapbox natively
    return const SizedBox.shrink();
  }
}

// ============================================================================
// Animated FAB Widget (copied from flutter_map version for consistency)
// ============================================================================

class _AnimatedFAB extends StatefulWidget {
  const _AnimatedFAB({required this.onCameraTap, required this.onGalleryTap});

  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  @override
  State<_AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<_AnimatedFAB>
    with SingleTickerProviderStateMixin {
  static const double _collapsedHeight = 60.0;
  static const double _collapsedWidth = 198.0;
  static const double _expandedHeight = 80.0;

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

    _heightAnimation =
        Tween<double>(begin: _collapsedHeight, end: _expandedHeight).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOutCubicEmphasized,
          ),
        );

    _widthAnimation = Tween<double>(begin: _collapsedWidth, end: 320.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );

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
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
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
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedCamera01,
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
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedImage02,
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
