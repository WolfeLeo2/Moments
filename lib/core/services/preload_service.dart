import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import '../providers/moments_providers.dart';
import '../services/map_cache_service.dart';

class PreloadService {
  /// Preloads essential app data to minimize wait time on the home screen.
  static Future<void> preloadApp(WidgetRef ref) async {
    final futures = <Future>[];

    // 1. Warm up Moments Stream (SQLite load + Supabase connection)
    // We just 'read' it to trigger the creation of the stream.
    // The provider caches the latest value, so MapPage will get it instantly.
    try {
      ref.read(momentsStreamProvider);
    } catch (e) {
      print('Preload: Error warming up moments stream: $e');
    }

    // 2. Initialize Map Caching (if not fully ready)
    futures.add(MapCacheService().initialize());

    // 3. Warm up Location Service
    // Requesting service/permission early so the prompt happens (or check happens)
    // while the splash is visible, rather than popping up on the map.
    futures.add(_warmUpLocation());

    // Wait for all "awaitable" preloads
    // We don't await the stream (it's continuous), but we await the others.
    await Future.wait(futures);
  }

  static Future<void> _warmUpLocation() async {
    try {
      final location = Location();
      // Just check status to warm up the internal engine
      final hasPermission = await location.hasPermission();
      if (hasPermission == PermissionStatus.granted) {
        // If granted, try getting the location now so it's cached in the OS/LocationManager
        // We don't necessarily need the result here, just the action of requesting it.
        // Timeout to prevent hanging the splash screen if GPS is slow.
        await location.getLocation().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            return LocationData.fromMap({});
          },
        );
      }
    } catch (e) {
      print('Preload: Location warmup failed: $e');
    }
  }
}
