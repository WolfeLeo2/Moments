import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/marker_generator.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/moment.dart';
import '../../../data/repositories/moment_repository.dart';
import '../../../widgets/blurred_app_bar.dart';
import '../../../widgets/spring_button.dart';
import '../../moments/presentation/add_moment_page_new.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<Moment> _moments = [];
  String _cityName = 'Loading...';
  bool _isLoading = true;
  final MomentRepository _momentRepository = MomentRepository();
  final AuthService _authService = AuthService();
  Set<Marker> _markers = {};
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _setupRealtimeSubscription();
  }
  
  void _setupRealtimeSubscription() {
    _realtimeChannel = Supabase.instance.client
        .channel('moments-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'moments',
          callback: (payload) {
            // Reload moments when any change happens
            _loadMoments();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      await _getCurrentLocation();
      await _loadCityName();
      await _loadMoments();
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to load map: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCityName() async {
    if (_currentPosition != null) {
      final city = await GeocodingService.getCityFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      setState(() {
        _cityName = city.toUpperCase();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(AppConstants.locationServiceDisabled);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(AppConstants.locationPermissionDenied);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(AppConstants.locationPermissionDenied);
    }

    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _loadMoments() async {
    try {
      final moments = await _momentRepository.getMoments();

      setState(() {
        _moments = moments;
      });
      
      // Create markers asynchronously after state update
      await _createMarkers();
      setState(() {}); // Trigger rebuild with markers
    } catch (e, stackTrace) {
      print('Error loading moments: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        context.showErrorSnackBar('Failed to load moments: $e');
      }
    }
  }

  Future<void> _createMarkers() async {
    final momentMarkers = await Future.wait(
      _moments.map((moment) async {
        // Get the count of images for this moment (with error handling)
        int imageCount = 1;
        try {
          final images = await _momentRepository.getMomentImages(moment.id);
          imageCount = images.length > 0 ? images.length : 1;
        } catch (e) {
          // If moment_images table doesn't exist yet, just use count of 1
          print('Could not fetch moment images: $e');
        }
        
        // Create custom marker bitmap (larger size for better visibility)
        const logicalSize = 180.0; // adjust globally here
        final icon = await MarkerGenerator.createMomentMarker(
          imageUrl: moment.imageUrl ?? '',
          count: imageCount,
          logicalSize: logicalSize,
          scale: 3.0,
        );
        final anchorY = MarkerGenerator.recommendedAnchorY(logicalSize: logicalSize);
        
        return Marker(
          markerId: MarkerId(moment.id),
          position: LatLng(moment.latitude, moment.longitude),
          onTap: () => _onMarkerTapped(moment),
          icon: icon,
          anchor: Offset(0.5, anchorY), // anchor computed from size/padding
        );
      }),
    );

    _markers = momentMarkers.toSet();

    // Add current location marker if available
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  void _onMarkerTapped(Moment moment) {
    AppRouter.goToMomentDetail(context, moment.id);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (_currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          AppConstants.defaultMapZoom,
        ),
      );
    }
  }

  void _onAddMomentPressed() {
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
                          _pickImageAndNavigate(ImageSource.camera);
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

  Future<void> _pickImageAndNavigate(ImageSource source) async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? image = await imagePicker.pickImage(
        source: source,
        imageQuality: AppConstants.imageQuality,
        maxWidth: AppConstants.maxImageWidth,
        maxHeight: AppConstants.maxImageHeight,
      );

      if (image != null && mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddMomentPageNew(
              imagePath: image.path,
              initialLatitude: _currentPosition?.latitude,
              initialLongitude: _currentPosition?.longitude,
            ),
          ),
        );
        
        // Reload moments only if moment was created successfully
        if (result == true && mounted) {
          await _loadMoments();
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to select image: $e');
      }
    }
  }

  Future<void> _pickMultipleImagesAndNavigate() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty && mounted) {
        // Pass all image paths
        final imagePaths = images.map((img) => img.path).toList();
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddMomentPageNew(
              imagePaths: imagePaths,
              initialLatitude: _currentPosition?.latitude,
              initialLongitude: _currentPosition?.longitude,
            ),
          ),
        );
        
        // Reload moments only if moment was created successfully
        if (result == true && mounted) {
          await _loadMoments();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      extendBodyBehindAppBar: true,
      appBar: BlurredAppBar(
        title: 'Moments',
        profileImageUrl: _authService.currentUserPhotoUrl,
        onMenuPressed: () {
          // TODO: Show menu drawer
        },
        onSearchPressed: () {
          // TODO: Show search
        },
        onProfilePressed: () async {
          // Show profile dialog with sign out option
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
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                  : const LatLng(37.7749, -122.4194), // Default to SF
              zoom: AppConstants.defaultMapZoom,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We'll add custom button
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(
              AppConstants.minMapZoom,
              AppConstants.maxMapZoom,
            ),
          ),

          // City/Area name sticker (below app bar, with container)
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
                        // Outline/stroke effect
                        Text(
                          _cityName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 3
                              ..color = Colors.black,
                          ),
                        ),
                        // Inner fill (transparent/white for cutout)
                        Text(
                          _cityName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ),
          ),

          // New Moment FAB (neubrutalism style)
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
        ],
      ),
    );
  }
}
