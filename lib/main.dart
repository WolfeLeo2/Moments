import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/map_cache_service.dart';
import 'core/services/avatar_cache_service.dart';
import 'data/sources/supabase_config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // REQUIRED

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize map tile caching (async, non-blocking)
  MapCacheService().initialize();

  // Initialize avatar caching (async, non-blocking)
  // This loads cached avatars from SQLite so they're ready immediately
  AvatarCacheService().initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 0, 0, 0),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.backgroundBeige,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 💡 Call the new root widget.
  runApp(const MomentsRootApp());
}

// -------------------------------------------------------------------

// 1. Rename your root widget to avoid confusion and use the ScreenUtilInit widget
class MomentsRootApp extends StatelessWidget {
  const MomentsRootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Your chosen reference size
      minTextAdapt: true,
      splitScreenMode: true,
      // 3. Use the builder to return the rest of your app (ProviderScope and MaterialApp)
      builder: (context, child) {
        return ProviderScope(
          child: MaterialApp.router(
            title: 'Moments',
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
            builder: (context, router) {
              final mediaQueryData = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQueryData.copyWith(
                  textScaler: TextScaler.linear(1.0),
                ),
                child: router!,
              );
            },
          ),
        );
      },
    );
  }
}
