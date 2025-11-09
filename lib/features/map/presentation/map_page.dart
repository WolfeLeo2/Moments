import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:image_picker/image_picker.dart' as picker;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/moment.dart';
import '../../../data/repositories/moment_repository.dart';
import '../../../widgets/blurred_app_bar.dart';
import '../../../widgets/spring_button.dart';
import '../../moments/presentation/add_moment_page_new.dart';
import '../utils/moment_stack_generator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapboxMap? _mapboxController;
  geo.Position? _currentPosition;
  List<Moment> _moments = [];
  String _cityName = 'Loading...';
  bool _isLoading = true;
  final MomentRepository _momentRepository = MomentRepository();
  final AuthService _authService = AuthService();
  Set<int> _momentAnnotationIds = {}; // Track added annotations
  RealtimeChannel? _realtimeChannel;

  PointAnnotationManager? _pointAnnotationManager;

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
    geo.LocationPermission permission;

    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        return;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      return;
    }

    _currentPosition = await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high,
    );
  }

  Future<void> _loadMoments() async {
    try {
      final moments = await _momentRepository.getMoments();

      setState(() {
        _moments = moments;
      });

      // Create markers asynchronously after state update
      await _createAnnotations();
      setState(() {}); // Trigger rebuild with markers
    } catch (e, stackTrace) {
      print('Error loading moments: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        context.showErrorSnackBar('Failed to load moments: $e');
      }
    }
  }

  Future<void> _createAnnotations() async {
    if (_mapboxController == null || _moments.isEmpty) {
      print('Cannot create annotations: controller null or no moments');
      return;
    }

    try {
      // Create point annotation manager if not exists
      _pointAnnotationManager ??= await _mapboxController!.annotations
          .createPointAnnotationManager();

      // Clear existing annotations
      if (_momentAnnotationIds.isNotEmpty) {
        await _pointAnnotationManager!.deleteAll();
        _momentAnnotationIds.clear();
      }

      // Group moments by location (with tolerance for nearby locations)
      final locationGroups = _groupMomentsByLocation(_moments);

      // Create stacked annotations for each location group
      final pointAnnotationOptionsList = <PointAnnotationOptions>[];

      for (final locationGroup in locationGroups) {
        final moments = locationGroup['moments'] as List<Moment>;
        final lat = locationGroup['lat'] as double;
        final lng = locationGroup['lng'] as double;

        // Generate custom stacked marker
        final stackedMarkerBytes =
            await MomentStackGenerator.generateStackedMomentMarker(
              moments: moments,
              size: 100.0,
            );

        // Create annotation with custom image
        final pointAnnotationOptions = PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          iconSize: 1.0,
          image: stackedMarkerBytes,
        );

        pointAnnotationOptionsList.add(pointAnnotationOptions);
      }

      // Create all annotations
      final annotations = await _pointAnnotationManager!.createMulti(
        pointAnnotationOptionsList,
      );

      // Store annotation IDs for future reference
      for (int i = 0; i < annotations.length; i++) {
        _momentAnnotationIds.add(i);
      }

      // Add tap event listener
      _pointAnnotationManager!.tapEvents(
        onTap: (annotation) {
          // Find the location group associated with this annotation
          final index = annotations.indexOf(annotation);
          if (index >= 0 && index < locationGroups.length) {
            final moments = locationGroups[index]['moments'] as List<Moment>;
            _onStackedMarkerTapped(moments);
          }
        },
      );

      print('Created ${annotations.length} stacked moment annotations');
    } catch (e, stackTrace) {
      print('Error creating annotations: $e');
      print('Stack trace: $stackTrace');
    }
  }

  List<Map<String, dynamic>> _groupMomentsByLocation(List<Moment> moments) {
    final groups = <Map<String, dynamic>>[];
    const double toleranceInDegrees = 0.001; // ~100 meters

    for (final moment in moments) {
      bool addedToGroup = false;

      // Try to find an existing group within tolerance
      for (final group in groups) {
        final groupLat = group['lat'] as double;
        final groupLng = group['lng'] as double;

        final distance = _calculateDistance(
          moment.latitude,
          moment.longitude,
          groupLat,
          groupLng,
        );

        if (distance < toleranceInDegrees) {
          (group['moments'] as List<Moment>).add(moment);
          addedToGroup = true;
          break;
        }
      }

      // Create new group if not added to existing one
      if (!addedToGroup) {
        groups.add({
          'lat': moment.latitude,
          'lng': moment.longitude,
          'moments': [moment],
        });
      }
    }

    return groups;
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return ((lat1 - lat2).abs() + (lng1 - lng2).abs());
  }

  void _onStackedMarkerTapped(List<Moment> moments) {
    if (moments.length == 1) {
      // Single moment - navigate to detail page
      _onMarkerTapped(moments.first);
    } else {
      // Multiple moments - show selection dialog
      _showMomentSelectionDialog(moments);
    }
  }

  void _showMomentSelectionDialog(List<Moment> moments) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${moments.length} Moments at this location'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: moments.length,
            itemBuilder: (context, index) {
              final moment = moments[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: moment.imageUrl?.isNotEmpty == true
                        ? Image.network(
                            moment.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.primaryBlue.withOpacity(0.3),
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                ),
                title: Text(moment.title),
                subtitle: Text(moment.location),
                onTap: () {
                  Navigator.pop(context);
                  _onMarkerTapped(moment);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _enableLocationDisplay() async {
    if (_mapboxController == null) return;

    try {
      await _mapboxController!.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          showAccuracyRing: false,
          puckBearingEnabled: false,
        ),
      );
      print('Location component enabled');
    } catch (e) {
      print('Error enabling location component: $e');
    }
  }

  void _onMarkerTapped(Moment moment) {
    AppRouter.goToMomentDetail(context, moment.id);
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
    try {
      final picker.ImagePicker imagePicker = picker.ImagePicker();
      final picker.XFile? image = await imagePicker.pickImage(
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
      final picker.ImagePicker pickerInstance = picker.ImagePicker();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
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
          // Mapbox Map
          MapWidget(
            key: const ValueKey("mapWidget"),
            styleUri: MapboxStyles.STANDARD,
            androidHostingMode: AndroidPlatformViewHostingMode.TLHC_VD,
            textureView:
                true, // Use texture view with TLHC for better performance
            cameraOptions: _currentPosition != null
                ? CameraOptions(
                    center: Point(
                      coordinates: Position(
                        _currentPosition!.longitude,
                        _currentPosition!.latitude,
                      ),
                    ),
                    zoom: 14.0,
                  )
                : null,
            onMapCreated: (MapboxMap mapboxMap) {
              _mapboxController = mapboxMap;
              print('Mapbox Map Created Successfully!');

              // Enable location component (blue dot)
              _enableLocationDisplay();

              // Load moments and create annotations after map is ready
              _loadMoments();
            },
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
