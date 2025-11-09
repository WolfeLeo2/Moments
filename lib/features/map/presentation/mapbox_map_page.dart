import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../core/theme/app_theme.dart';
import '../../../widgets/blurred_app_bar.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/router/app_router.dart';

class MapboxMapPage extends StatefulWidget {
  const MapboxMapPage({super.key});

  @override
  State<MapboxMapPage> createState() => _MapboxMapPageState();
}

class _MapboxMapPageState extends State<MapboxMapPage> {
  MapboxMap? _mapboxController;
  geo.Position? _currentPosition;
  String _cityName = 'Loading...';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _cityName = 'Location disabled');
        }
        return;
      }

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          if (mounted) {
            setState(() => _cityName = 'Location permission denied');
          }
          return;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _cityName = 'Location permission permanently denied');
        }
        return;
      }

      _currentPosition = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _cityName = 'Current Location';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cityName = 'Location error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Simple Mapbox Map
          MapWidget(
            key: const ValueKey("mapWidget"),
            styleUri: MapboxStyles.MAPBOX_STREETS,
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
            },
          ),

          // City name overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.brightYellow,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _cityName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),

          // Simple New Moment Button
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Add Moment feature coming soon!'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    border: Border.all(color: Colors.black, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'New Moment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
