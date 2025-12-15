import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:image_picker/image_picker.dart' as picker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:wechat_assets_picker/wechat_assets_picker.dart' hide LatLng;
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/map_cache_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../data/models/moment.dart';
import '../../../widgets/blurred_app_bar.dart';
import '../../../widgets/spring_button.dart';
import '../../moments/presentation/add_moment_page.dart';
import '../../moments/presentation/moment_details_page.dart';
import '../../moments/presentation/timeline_gallery_page.dart';
import '../../social/presentation/friends_page.dart';
import '../../profile/profile_page.dart';
import '../widgets/stacked_moment_marker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final AuthService _authService = AuthService();
  String _cityName = 'Loading...';
  geo.Position? _currentPosition;
  final MapCacheService _mapCacheService = MapCacheService();
  final MapController _mapController = MapController();
  double _currentZoom = 14.0; // Track current zoom level for clustering

  @override
  void initState() {
    super.initState();
    _initializeMap();
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
        // Show dialog to enable location services
        if (mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text(
                'Please enable location services to see your current position on the map.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('ENABLE'),
                ),
              ],
            ),
          );
          if (shouldOpenSettings == true) {
            await geo.Geolocator.openLocationSettings();
          }
        }
        return;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          return; // User denied, don't throw
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        // Show dialog to open app settings
        if (mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Permission Required'),
              content: const Text(
                'Location permission is permanently denied. Please enable it in app settings to see your current position.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('OPEN SETTINGS'),
                ),
              ],
            ),
          );
          if (shouldOpenSettings == true) {
            await geo.Geolocator.openAppSettings();
          }
        }
        return;
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
    
    // First, group by moment_group_id for moments that have one
    final groupedMoments = <String, List<Moment>>{};
    final ungroupedMoments = <Moment>[];
    
    for (final moment in moments) {
      if (moment.momentGroupId != null) {
        // Group by moment_group_id
        if (groupedMoments.containsKey(moment.momentGroupId)) {
          groupedMoments[moment.momentGroupId]!.add(moment);
        } else {
          groupedMoments[moment.momentGroupId!] = [moment];
        }
      } else {
        // No group ID - treat as standalone
        ungroupedMoments.add(moment);
      }
    }
    
    // Add grouped moments
    for (final entry in groupedMoments.entries) {
      final groupMoments = entry.value;
      final firstMoment = groupMoments.first;
      final placeName = _extractPlaceName(firstMoment.location);

      groups.add({
        'placeName': placeName,
        'moments': groupMoments,
        'lat': firstMoment.latitude,
        'lng': firstMoment.longitude,
        'groupId': entry.key,
        'isCluster': false,
        'clusterCount': 1,
      });
    }
    
    // Add ungrouped moments - each as its own marker, but group by location for nearby ones
    final locationGroups = <String, List<Moment>>{};
    for (final moment in ungroupedMoments) {
      // Use a location key based on truncated lat/lng to group nearby moments
      final locationKey = '${moment.latitude.toStringAsFixed(4)}_${moment.longitude.toStringAsFixed(4)}';
      if (locationGroups.containsKey(locationKey)) {
        locationGroups[locationKey]!.add(moment);
      } else {
        locationGroups[locationKey] = [moment];
      }
    }
    
    for (final entry in locationGroups.entries) {
      final locationMoments = entry.value;
      final firstMoment = locationMoments.first;
      final placeName = _extractPlaceName(firstMoment.location);

      groups.add({
        'placeName': placeName,
        'moments': locationMoments,
        'lat': firstMoment.latitude,
        'lng': firstMoment.longitude,
        'groupId': 'loc_${entry.key}',
        'isCluster': false,
        'clusterCount': 1,
      });
    }
    
    // Apply zoom-aware clustering
    return _applyZoomClustering(groups);
  }
  
  /// Apply zoom-aware clustering to group nearby moment groups
  /// At low zoom levels, cluster more aggressively
  List<Map<String, dynamic>> _applyZoomClustering(List<Map<String, dynamic>> groups) {
    if (groups.length <= 1) return groups;
    
    // Calculate clustering threshold based on zoom level
    // At zoom 5 (country view): cluster groups ~100km apart
    // At zoom 10 (city view): cluster groups ~5km apart
    // At zoom 14+ (street view): minimal clustering
    final double clusterThreshold = _calculateClusterThreshold(_currentZoom);
    
    if (clusterThreshold <= 0) {
      // At high zoom, just apply minor offsets but no clustering
      return _applyProximityOffsets(groups);
    }
    
    final clustered = <Map<String, dynamic>>[];
    final processed = <int>{};
    
    for (int i = 0; i < groups.length; i++) {
      if (processed.contains(i)) continue;
      
      final baseLat = groups[i]['lat'] as double;
      final baseLng = groups[i]['lng'] as double;
      final clusterMembers = <Map<String, dynamic>>[groups[i]];
      processed.add(i);
      
      // Find all groups close to this one
      for (int j = i + 1; j < groups.length; j++) {
        if (processed.contains(j)) continue;
        
        final otherLat = groups[j]['lat'] as double;
        final otherLng = groups[j]['lng'] as double;
        
        final latDiff = (baseLat - otherLat).abs();
        final lngDiff = (baseLng - otherLng).abs();
        
        if (latDiff < clusterThreshold && lngDiff < clusterThreshold) {
          clusterMembers.add(groups[j]);
          processed.add(j);
        }
      }
      
      if (clusterMembers.length > 1) {
        // Create a cluster from multiple groups
        final allMoments = <Moment>[];
        double totalLat = 0, totalLng = 0;
        
        for (final member in clusterMembers) {
          allMoments.addAll(member['moments'] as List<Moment>);
          totalLat += member['lat'] as double;
          totalLng += member['lng'] as double;
        }
        
        // Use centroid for cluster position
        final centerLat = totalLat / clusterMembers.length;
        final centerLng = totalLng / clusterMembers.length;
        
        clustered.add({
          'placeName': '${clusterMembers.length} locations',
          'moments': allMoments,
          'lat': centerLat,
          'lng': centerLng,
          'groupId': 'cluster_${clusterMembers.map((m) => m['groupId']).join('_')}',
          'isCluster': true,
          'clusterCount': clusterMembers.length,
        });
      } else {
        // Single group, no clustering needed
        clustered.add(groups[i]);
      }
    }
    
    return clustered;
  }
  
  /// Calculate the clustering threshold based on zoom level
  double _calculateClusterThreshold(double zoom) {
    // Zoom levels:
    // 3-5: World/continent view -> cluster aggressively (threshold ~5 degrees)
    // 6-8: Country view -> moderate clustering (threshold ~1 degree)
    // 9-11: Region/city view -> light clustering (threshold ~0.1 degrees)
    // 12-15: Neighborhood view -> very light clustering for nearby groups
    // 16+: Street view -> no clustering (threshold 0)
    
    if (zoom >= 16) return 0; // No clustering at street level
    if (zoom >= 14) return 0.002; // ~200m - still cluster very close groups
    if (zoom >= 12) return 0.005; // ~500m
    if (zoom >= 10) return 0.02; // ~2km
    if (zoom >= 8) return 0.1; // ~10km
    if (zoom >= 6) return 0.5; // ~50km
    if (zoom >= 4) return 2.0; // ~200km
    return 5.0; // ~500km at world view
  }
  
  /// Apply small lat/lng offsets to groups that are very close to each other
  /// This prevents markers from stacking directly on top of each other
  List<Map<String, dynamic>> _applyProximityOffsets(List<Map<String, dynamic>> groups) {
    if (groups.length <= 1) return groups;
    
    const double proximityThreshold = 0.0005; // ~50 meters
    const double offsetStep = 0.0003; // ~30 meters offset
    
    // Track which groups have been processed
    final processed = <int>{};
    
    for (int i = 0; i < groups.length; i++) {
      if (processed.contains(i)) continue;
      
      final baseLat = groups[i]['lat'] as double;
      final baseLng = groups[i]['lng'] as double;
      
      // Find all groups close to this one
      final nearbyIndices = <int>[i];
      for (int j = i + 1; j < groups.length; j++) {
        if (processed.contains(j)) continue;
        
        final otherLat = groups[j]['lat'] as double;
        final otherLng = groups[j]['lng'] as double;
        
        final latDiff = (baseLat - otherLat).abs();
        final lngDiff = (baseLng - otherLng).abs();
        
        if (latDiff < proximityThreshold && lngDiff < proximityThreshold) {
          nearbyIndices.add(j);
        }
      }
      
      // If multiple groups are close, spread them out in a circular pattern
      if (nearbyIndices.length > 1) {
        for (int k = 0; k < nearbyIndices.length; k++) {
          final idx = nearbyIndices[k];
          processed.add(idx);
          
          // Calculate offset based on position in cluster (alternating pattern)
          final latOffset = offsetStep * k * (k % 2 == 0 ? 1 : -1) * 0.5;
          final lngOffset = offsetStep * k * (k % 2 == 0 ? -1 : 1) * 0.7;
          
          groups[idx]['lat'] = (groups[idx]['lat'] as double) + latOffset;
          groups[idx]['lng'] = (groups[idx]['lng'] as double) + lngOffset;
        }
      } else {
        processed.add(i);
      }
    }
    
    return groups;
  }

  /// Build cluster badge showing number of locations and moments
  Widget _buildClusterBadge(int locationCount, int momentCount) {
    return Transform.rotate(
      angle: 0.05, // Slight tilt for neubrutalism style
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderBlack,
            width: 2,
          ),
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
              Icons.location_on,
              color: Colors.white,
              size: 12,
            ),
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
            const Icon(
              Icons.photo_library,
              color: Colors.white,
              size: 12,
            ),
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

  Future<void> _pickFromCamera() async {
    if (_currentPosition == null) {
      if (mounted) {
        context.showErrorSnackBar('Unable to get current location');
      }
      return;
    }

    // Show dialog to choose between photo and video
    final mediaType = await showDialog<String>(
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

    if (mediaType == null || !mounted) return;

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
        context.showErrorSnackBar('Error opening camera: $e');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_currentPosition == null) {
      if (mounted) {
        context.showErrorSnackBar('Unable to get current location');
      }
      return;
    }

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
        context.showErrorSnackBar('Error picking media: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the moments stream from Riverpod
    final momentsAsync = ref.watch(momentsStreamProvider);

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
        // Group moments by place
        final placeGroups = _groupMomentsByPlace(moments);
        return Scaffold(
          backgroundColor: AppTheme.backgroundBeige,
          extendBodyBehindAppBar: true,
          appBar: BlurredAppBar(
            title: 'Moments',

            profileImageUrl: _authService.currentUserPhotoUrl,
            onFriendsPressed: () {
              HapticService.lightTap();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsPage()),
              );
            },
            onGalleryPressed: () {
              HapticService.lightTap();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TimelineGalleryPage()),
              );
            },
            onProfilePressed: () {
              HapticService.lightTap();
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
                  initialZoom: 18.0,
                  minZoom: 5.0,
                  maxZoom: 22.0,
                  onPositionChanged: (position, hasGesture) {
                    // Track zoom level for dynamic clustering
                    if (position.zoom != _currentZoom) {
                      setState(() {
                        _currentZoom = position.zoom;
                      });
                    }
                  },
                ),
                children: [
                  // Mapbox Streets v11 - 512px tiles for better performance
                  TileLayer(
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/512/{z}/{x}/{y}@2x?access_token=pk.eyJ1Ijoid29sZmVsZW8iLCJhIjoiY21oYXRxMW82MW5nNjJqcGc4aDA0YndoeSJ9.gvLhQFM-46KlcUdAKFGMYg',
                    userAgentPackageName: 'com.moments.app',
                    tileProvider: _mapCacheService.tileProvider,
                    tileSize: 512,
                    zoomOffset: -1,
                    retinaMode: true,
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
                  MarkerLayer(
                    markers: placeGroups.asMap().entries.map((entry) {
                      final placeGroup = entry.value;
                      final moments = placeGroup['moments'] as List<Moment>;
                      final lat = placeGroup['lat'] as double;
                      final lng = placeGroup['lng'] as double;
                      final placeName = placeGroup['placeName'] as String;
                      final isCluster = placeGroup['isCluster'] as bool? ?? false;
                      final clusterCount = placeGroup['clusterCount'] as int? ?? 1;
                      
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
                              onTap: () =>
                                  _onPlaceMarkerTapped(moments, placeName, 0),
                              heroTag: null,
                            ),
                            // Cluster count badge (only show if multiple groups clustered)
                            if (isCluster && clusterCount > 1)
                              Positioned(
                                bottom: -5,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _buildClusterBadge(clusterCount, moments.length),
                                ),
                              ),
                          ],
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
                        boxShadow: AppTheme.brutalShadow,
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
                                ..color = AppTheme.borderBlack,
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
