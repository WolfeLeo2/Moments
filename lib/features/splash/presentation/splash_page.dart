import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:location/location.dart';
import 'package:moments/core/router/app_router.dart';
import 'package:moments/core/providers/moments_providers.dart';
import 'package:moments/core/services/map_cache_service.dart';
import 'package:moments/core/services/app_logger.dart';

import 'package:moments/core/providers/providers.dart';
import 'package:moments/features/mapv2/providers/map_v2_providers.dart';
import 'package:moments/features/mapv2/presentation/map_style_picker_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = AppLogger('SplashPage');

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    final minSplashDuration = const Duration(milliseconds: 2000);

    // Start preloading data in parallel with the animation
    final preloadFuture = _preloadApp();

    await Future.wait([
      Future.delayed(minSplashDuration),
      // Await preload with timeout so we don't block forever if GPS is slow
      preloadFuture.timeout(
        const Duration(milliseconds: 2500),
        onTimeout: () {},
      ),
    ]);

    if (!mounted) return;

    // Navigate to map; router will redirect to login if not authenticated
    context.go(AppRouter.mapRoute);

    // If the user is signed in and hasn't seen the map style picker yet,
    // show it as a one-off overlay after navigating to the main scaffold.
    if (ref.read(authServiceProvider).isSignedIn) {
      final hasSeenPicker = await MapStylePrefs.hasSeenPicker();
      if (!hasSeenPicker && mounted) {
        // Small delay so the main scaffold has time to mount
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MapStylePickerPage(isOnboarding: true),
            ),
          );
        }
      }
    }
  }

  /// Preloads essential app data to minimize wait time on the home screen.
  Future<void> _preloadApp() async {
    final futures = <Future>[];

    // 0. Load saved map style preference from SharedPreferences
    futures.add(_loadMapStylePref());

    // 1. Warm up Moments Stream (SQLite load + Supabase connection)
    try {
      ref.read(momentsStreamProvider);
    } catch (e) {
      _log.w('Error warming up moments stream', error: e);
    }

    // 2. Initialize Map Caching
    futures.add(MapCacheService().initialize());

    // 3. Warm up Location Service
    futures.add(_warmUpLocation());

    await Future.wait(futures);
  }

  Future<void> _loadMapStylePref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final useV2 = prefs.getBool('map_style_v2_enabled') ?? true;
      ref.read(useMapV2Provider.notifier).set(useV2);
    } catch (e) {
      _log.w('Error loading map style pref', error: e);
    }
  }

  Future<void> _warmUpLocation() async {
    try {
      final location = Location();
      final hasPermission = await location.hasPermission();
      if (hasPermission == PermissionStatus.granted ||
          hasPermission == PermissionStatus.grantedLimited) {
        // Silently warm up the OS location cache — no dialogs
        await location.getLocation().timeout(
          const Duration(seconds: 2),
          onTimeout: () => LocationData.fromMap({}),
        );
      }
      // Never request permission here — let Mapbox handle it on the map page
    } catch (e) {
      _log.w('Location warmup failed', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
                  'assets/icons/app_icon_nobg.png',
                  width: 120.w,
                  height: 120.h,
                )
                .animate()
                .fade(duration: 600.ms)
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .shimmer(duration: 600.ms),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
