import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:image_picker/image_picker.dart' as picker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../widgets/stacked_moment_marker.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Future<void> _onAddMomentPressed() async {
    _showImageSourceDialog();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusLarge),
          topRight: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add a Moment', style: context.textTheme.titleLarge),
                const SizedBox(height: AppTheme.spacing24),
                Row(
                  children: [
                    Expanded(
                      child: SpringButton(
                        onTap: () {
                          Navigator.of(context).pop();
                          _pickImageAndNavigate(picker.ImageSource.camera);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacing16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.camera_alt,
                                size: 32,
                                color: Colors.white,
                              ),
                              const SizedBox(height: AppTheme.spacing8),
                              Text(
                                'Camera',
                                style: context.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing16),
                    Expanded(
                      child: SpringButton(
                        onTap: () {
                          Navigator.of(context).pop();
                          _pickMultipleImagesAndNavigate();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spacing16),
                          decoration: BoxDecoration(
                            color: AppTheme.brightYellow,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.photo_library,
                                size: 32,
                                color: Colors.black,
                              ),
                              const SizedBox(height: AppTheme.spacing8),
                              Text(
                                'Gallery',
                                style: context.textTheme.titleSmall?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
            onMenuPressed: () {},
            onSearchPressed: () {},
            onFriendsPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsPage()),
              );
            },
            onProfilePressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(_authService.currentUserDisplayName ?? 'Profile'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_authService.currentUserPhotoUrl != null)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(
                            _authService.currentUserPhotoUrl!,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(_authService.currentUserEmail ?? ''),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _authService.signOut();
                        if (context.mounted) {
                          Navigator.pop(context);
                          AppRouter.router.go('/login');
                        }
                      },
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
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

              // New Moment FAB
              Positioned(
                bottom: AppTheme.spacing32,
                left: 0,
                right: 0,
                child: Center(
                  child: SpringButton(
                    onTap: _onAddMomentPressed,
                    scaleFactor: 0.92,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
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
                            child: const Icon(
                              Icons.add,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'New Moment',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
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
