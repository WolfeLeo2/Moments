import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moments/core/router/app_router.dart';
import '../../../core/services/preload_service.dart';
import '../../../core/router/app_router.dart';

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
    // We pass 'ref' to access providers
    final preloadFuture = PreloadService.preloadApp(ref);

    // Check if user is logged in (to decide if we should preload heavy user data)
    // For now, simpler to just attempt preload. logic inside preload can handle exceptions.

    // Wait for BOTH the minimum animation time AND the preload (optional)
    // Actually, improved UX: Wait for min animation time.
    // If preload finishes fast -> good, we wait for animation.
    // If preload is slow -> we can choose to wait for it (no loading spinner on map)
    //                      OR go to map immediately and show loading spinner there.
    // User requested "wont this make the wait longer".
    // Strategy: Wait for min animation. If preload isn't done, we go anyway,
    // and the MapPage will just continue waiting for the futures we started.
    // BUT getting location might trigger a dialog, which we want on the map not splash?
    // Actually PreloadService only asks for location if permission is granted.

    await Future.wait([
      Future.delayed(minSplashDuration),
      // We await preload but with a timeout so we don't block forever if GPS is stuck
      preloadFuture.timeout(
        const Duration(milliseconds: 2500),
        onTimeout: () {},
      ),
    ]);

    if (!mounted) return;

    // Simple approach: attempting to go to home/map, if protected, Router will send to login.
    context.go(AppRouter.mapRoute);
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

            // Optional: Loading indicator or text
            // CircularProgressIndicator(strokeWidth: 2).animate().fade(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
