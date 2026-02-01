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
  }

  /// Preloads essential app data to minimize wait time on the home screen.
  Future<void> _preloadApp() async {
    final futures = <Future>[];

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

  Future<void> _warmUpLocation() async {
    try {
      final location = Location();
      final hasPermission = await location.hasPermission();
      if (hasPermission == PermissionStatus.granted) {
        // Try getting location so it's cached in OS/LocationManager
        await location.getLocation().timeout(
          const Duration(seconds: 2),
          onTimeout: () => LocationData.fromMap({}),
        );
      }
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
