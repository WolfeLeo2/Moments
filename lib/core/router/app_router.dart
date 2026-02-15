import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/navigation/presentation/main_scaffold.dart';
import '../../features/moments/presentation/add_moment_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/phone_verification_page.dart';
import '../services/auth_service.dart';
import '../services/notification_navigator.dart';

import '../../features/splash/presentation/splash_page.dart'; // Import SplashPage

class AppRouter {
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String verifyPhoneRoute = '/verify-phone';
  static const String mapRoute = '/';
  static const String momentDetailRoute = '/moment/:id';
  static const String addMomentRoute = '/add-moment';

  static final _authService = AuthService();

  static final GoRouter router = GoRouter(
    navigatorKey: NotificationNavigator.navigatorKey,
    initialLocation: splashRoute, // Start at splash
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isSignedIn = _authService.isSignedIn;
      final isOnLoginPage = state.matchedLocation == loginRoute;
      final isOnSplashPage = state.matchedLocation == splashRoute;
      final isOnVerifyPhone = state.matchedLocation == verifyPhoneRoute;

      // Allow splash to run its course
      if (isOnSplashPage) return null;

      // If signed in, check if phone is verified
      // Allow verify-phone page if signed in
      if (isOnVerifyPhone && isSignedIn) return null;

      // Redirect to login if not signed in and not already on login page
      if (!isSignedIn && !isOnLoginPage) {
        return loginRoute;
      }

      // Redirect to map if signed in and on login page
      if (isSignedIn && isOnLoginPage) {
        return mapRoute;
      }

      // Redirect to login if not signed in and not already on login page
      // Note: If on verify phone page but not signed in, we should probably go to login
      if (!isSignedIn && !isOnLoginPage) {
        return loginRoute;
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
      GoRoute(
        path: mapRoute,
        name: 'map',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const MainScaffold()),
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
          final imagePaths = imagePathsStr?.split(
            '|||',
          ); // Use ||| as delimiter

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
  static void goToMap(BuildContext context) {
    context.go(mapRoute);
  }

  static void goToVerifyPhone(BuildContext context) {
    context.go(verifyPhoneRoute);
  }

  static void goToMomentDetail(BuildContext context, String momentId) {
    context.go('/moment/$momentId');
  }

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
      queryParams['imagePaths'] = imagePaths.join(
        '|||',
      ); // Use ||| as delimiter
    }

    final uri = Uri(
      path: addMomentRoute,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    context.push(uri.toString());
  }
}
