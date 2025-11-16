import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:image_picker/image_picker.dart' as picker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spring/spring.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../data/models/moment.dart';
import '../../../widgets/blurred_app_bar.dart';
import '../../../widgets/spring_button.dart';
import '../../moments/presentation/add_moment_page_new.dart';
import '../../moments/presentation/moment_details_page.dart';
import '../../social/presentation/friends_page.dart';
import '../../profile/profile_page.dart';
import '../widgets/stacked_moment_marker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();
  geo.Position? _currentPosition;
  String _cityName = 'Loading...';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
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
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      if (mounted) {
        setState(() => _cityName = city);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      if (mounted) {
        setState(() => _currentPosition = position);
        // Auto-center map to user's location
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          14.0,
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  List<Map<String, dynamic>> _groupMomentsByPlace(List<Moment> moments) {
    final groups = <Map<String, dynamic>>[];
    final placeMap = <String, List<Moment>>{};

    for (final moment in moments) {
      final placeName = _extractPlaceName(moment.location);
      if (placeMap.containsKey(placeName)) {
        placeMap[placeName]!.add(moment);
      } else {
        placeMap[placeName] = [moment];
      }
    }

    for (final entry in placeMap.entries) {
      final moments = entry.value;
      final placeName = entry.key;
      final firstMoment = moments.first;

      groups.add({
        'placeName': placeName,
        'moments': moments,
        'lat': firstMoment.latitude,
        'lng': firstMoment.longitude,
      });
    }

    return groups;
  }

  String _extractPlaceName(String location) {
    // Extract the main place name from location string
    // e.g., "Kitengela, Kajiado, Kenya" -> "Kitengela"
    return location.split(',').first.trim();
  }

  // Old _onPlaceMarkerTapped (Hero) removed in favor of rect-based transform transition

  void _onPlaceMarkerTapped(
    List<Moment> moments,
    String placeName,
    int markerIndex,
  ) {
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

  Future<void> _pickImageAndNavigate(picker.ImageSource source) async {
    if (_currentPosition == null) {
      if (mounted) {
        context.showErrorSnackBar('Unable to get current location');
      }
      return;
    }

    try {
      final imagePicker = picker.ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null || !mounted) return;

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddMomentPageNew(
            imagePath: pickedFile.path,
            initialLatitude: _currentPosition!.latitude,
            initialLongitude: _currentPosition!.longitude,
          ),
        ),
      );

      // Invalidate moments cache to refresh if moment was created successfully
      if (result == true && mounted) {
        ref.invalidate(momentsStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error picking image: $e');
      }
    }
  }

  Future<void> _pickMultipleImagesAndNavigate() async {
    if (_currentPosition == null) {
      if (mounted) {
        context.showErrorSnackBar('Unable to get current location');
      }
      return;
    }

    try {
      final pickerInstance = picker.ImagePicker();
      final List<picker.XFile> images = await pickerInstance.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty && mounted) {
        // Pass all image paths
        final imagePaths = images.map((img) => img.path).toList();
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddMomentPageNew(
              imagePaths: imagePaths,
              initialLatitude: _currentPosition!.latitude,
              initialLongitude: _currentPosition!.longitude,
            ),
          ),
        );

        // Invalidate moments cache to refresh if moment was created successfully
        if (result == true && mounted) {
          ref.invalidate(momentsStreamProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error picking images: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the moments stream from Riverpod
    final momentsAsync = ref.watch(momentsStreamProvider);

    return momentsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      ),
      error: (error, stackTrace) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundBeige,
          body: Center(child: Text('Error loading moments: $error')),
        );
      },
      data: (moments) {
        // Group moments by place
        final placeGroups = _groupMomentsByPlace(moments);
        return Scaffold(
          backgroundColor: AppTheme.backgroundBeige,
          extendBodyBehindAppBar: true,
          appBar: BlurredAppBar(
            title: 'Moments',
            profileImageUrl: _authService.currentUserPhotoUrl,
            onFriendsPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsPage()),
              );
            },
            onProfilePressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          body: Stack(
            children: [
              // Flutter Map with Mapbox tiles
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition != null
                      ? LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        )
                      : const LatLng(0, 0),
                  initialZoom: 14.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                ),
                children: [
                  // Mapbox tile layer - Standard style (blueish)
                  TileLayer(
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoid29sZmVsZW8iLCJhIjoiY21oYXRxMW82MW5nNjJqcGc4aDA0YndoeSJ9.gvLhQFM-46KlcUdAKFGMYg',
                    userAgentPackageName: 'com.moments.app',
                    tileSize: 512,
                    zoomOffset: -1,
                  ),

                  // User location marker (BEFORE moment markers so it appears below)
                  if (_currentPosition != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
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
                  MarkerLayer(
                    markers: placeGroups.asMap().entries.map((entry) {
                      final placeGroup = entry.value;
                      final moments = placeGroup['moments'] as List<Moment>;
                      final lat = placeGroup['lat'] as double;
                      final lng = placeGroup['lng'] as double;
                      final placeName = placeGroup['placeName'] as String;

                      return Marker(
                        point: LatLng(lat, lng),
                        width: 140,
                        height: 180,
                        child: StackedMomentMarker(
                          moments: moments,
                          onTap: () =>
                              _onPlaceMarkerTapped(moments, placeName, 0),
                          heroTag: null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // City name sticker
              Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 5,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.rotate(
                    angle: -0.01,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.brightYellow,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Text(
                            _cityName.toUpperCase(),
                            style: GoogleFonts.bangers(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3
                                ..color = Colors.black,
                            ),
                          ),
                          Text(
                            _cityName.toUpperCase(),
                            style: GoogleFonts.bangers(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Animated FAB
              Positioned(
                bottom: AppTheme.spacing32,
                left: 0,
                right: 0,
                child: Center(
                  child: _AnimatedFAB(
                    onCameraTap: () =>
                        _pickImageAndNavigate(picker.ImageSource.camera),
                    onGalleryTap: _pickMultipleImagesAndNavigate,
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
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '© Mapbox © OpenStreetMap',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black.withOpacity(0.7),
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
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  const _AnimatedFAB({required this.onCameraTap, required this.onGalleryTap});

  @override
  State<_AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<_AnimatedFAB>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _heightAnimation;
  late final Animation<double> _widthAnimation;
  late final Animation<double> _opacityAnimation;

  // FAB dimensions - grow both width and height
  static const double _collapsedHeight = 60.0;
  static const double _expandedHeight =
      72.0; // Proportional height for 2 buttons
  static const double _collapsedWidth = 190.0; // Stable width for resting FAB

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
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
    _toggleExpansion();
    Future.delayed(const Duration(milliseconds: 300), widget.onCameraTap);
  }

  void _handleGalleryTap() {
    _toggleExpansion();
    Future.delayed(const Duration(milliseconds: 300), widget.onGalleryTap);
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
              scaleFactor: 0.92,
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

  Widget _buildCollapsedContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
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
          const SizedBox(width: 12),
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
                    fontSize: 16,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    size: 18,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Camera',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    size: 18,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Gallery',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Close button (X) - static, no animation
          SpringButton(
            onTap: _toggleExpansion,
            scaleFactor: 0.9,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
