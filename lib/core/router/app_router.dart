import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/navigation/presentation/main_scaffold.dart';
import '../../features/moments/presentation/add_moment_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/phone_verification_page.dart';
import '../../features/mapv2/presentation/map_page_v2.dart';
import '../../features/spotlight/presentation/spotlight_page.dart';
import '../../features/explore/presentation/explore_page.dart';
import '../../features/chat/presentation/chat_list_page.dart';
import '../../data/sources/supabase_config.dart';
import '../services/auth_service.dart';
import '../services/notification_navigator.dart';

import '../../features/splash/presentation/splash_page.dart';

class AppRouter {
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String verifyPhoneRoute = '/verify-phone';
  static const String mapRoute = '/';
  static const String spotlightRoute = '/spotlight';
  static const String exploreRoute = '/explore';
  static const String chatsRoute = '/chats';
  static const String addMomentRoute = '/add-moment';

  static final _authService = AuthService(SupabaseConfig.client);
  static final _authRefresh = _AuthRefreshListenable(
    _authService.authStateChanges,
  );

  // Branch navigators keep each tab's push stack independent.
  static final _shellNavigatorMap = GlobalKey<NavigatorState>(
    debugLabel: 'shellMap',
  );

  static final GoRouter router = GoRouter(
    navigatorKey: NotificationNavigator.navigatorKey,
    initialLocation: splashRoute,
    debugLogDiagnostics: false,
    refreshListenable: _authRefresh,
    redirect: (context, state) {
      final isSignedIn = _authService.isSignedIn;
      final loc = state.matchedLocation;
      final isOnLoginPage = loc == loginRoute;
      final isOnSplashPage = loc == splashRoute;
      final isOnVerifyPhone = loc == verifyPhoneRoute;

      // Allow splash to run its course.
      if (isOnSplashPage) return null;

      // Allow verify-phone page if signed in.
      if (isOnVerifyPhone && isSignedIn) return null;

      // Not signed in → login.
      if (!isSignedIn && !isOnLoginPage) return loginRoute;

      // Signed in but sitting on login → home.
      if (isSignedIn && isOnLoginPage) return mapRoute;

      // Drain any notification tap that arrived before the widget tree was ready.
      if (isSignedIn && !isOnSplashPage) {
        NotificationNavigator.drainIfPending(context);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: splashRoute,
        name: 'splash',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const SplashPage()),
      ),
      GoRoute(
        path: loginRoute,
        name: 'login',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: verifyPhoneRoute,
        name: 'verify-phone',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PhoneVerificationPage(),
        ),
      ),

      // The 4 main tabs — each a deep-linkable branch with its own navigator.
      // The shell preserves per-branch state (no manual keep-alive needed).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMap,
            routes: [
              GoRoute(
                path: mapRoute,
                name: 'map',
                builder: (context, state) => const MapPageV2(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: spotlightRoute,
                name: 'spotlight',
                builder: (context, state) => const SpotlightPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: exploreRoute,
                name: 'explore',
                builder: (context, state) => const ExplorePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: chatsRoute,
                name: 'chats',
                builder: (context, state) => const ChatListPage(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: addMomentRoute,
        name: 'add-moment',
        pageBuilder: (context, state) {
          final latitude = double.tryParse(
            state.uri.queryParameters['lat'] ?? '',
          );
          final longitude = double.tryParse(
            state.uri.queryParameters['lng'] ?? '',
          );
          final imagePath = state.uri.queryParameters['imagePath'];
          final imagePathsStr = state.uri.queryParameters['imagePaths'];
          final imagePaths = imagePathsStr?.split('|||');

          return MaterialPage(
            key: state.pageKey,
            child: AddMomentPage(
              initialLatitude: latitude,
              initialLongitude: longitude,
              mediaPath: imagePath,
              mediaPaths: imagePaths,
            ),
          );
        },
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Page not found: ${state.matchedLocation}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(mapRoute),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // Navigation helpers
  static void goToMap(BuildContext context) => context.go(mapRoute);

  static void goToVerifyPhone(BuildContext context) =>
      context.go(verifyPhoneRoute);

  static void goToAddMoment(
    BuildContext context, {
    double? lat,
    double? lng,
    String? imagePath,
    List<String>? imagePaths,
  }) {
    final queryParams = <String, String>{};
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    if (imagePath != null) queryParams['imagePath'] = imagePath;
    if (imagePaths != null && imagePaths.isNotEmpty) {
      queryParams['imagePaths'] = imagePaths.join('|||');
    }

    final uri = Uri(
      path: addMomentRoute,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    context.push(uri.toString());
  }
}

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
