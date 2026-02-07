import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/notification_navigator.dart';
import 'core/services/chat_offline_service.dart';
import 'core/services/ai_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/map_cache_service.dart';
import 'data/sources/supabase_config.dart';
import 'core/providers/providers.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/router_provider.dart';
import 'core/providers/theme_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // REQUIRED

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await SupabaseConfig.initialize();

  // Initialize Firebase Messaging
  await FirebaseMessagingService().initialize();

  // Initialize notification deep-link handler
  NotificationNavigator.initialize();

  // Initialize map tile caching (async, non-blocking)
  MapCacheService().initialize();

  // Initialize Firebase AI (Gemini Developer API - free tier)
  AIService().initialize();

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
  runApp(const ProviderScope(child: MomentsRootApp()));
}

// -------------------------------------------------------------------

// 1. Rename your root widget to avoid confusion and use the ScreenUtilInit widget
class MomentsRootApp extends ConsumerStatefulWidget {
  const MomentsRootApp({super.key});

  @override
  ConsumerState<MomentsRootApp> createState() => _MomentsRootAppState();
}

class _MomentsRootAppState extends ConsumerState<MomentsRootApp> {
  @override
  void initState() {
    super.initState();

    // Initialize avatar caching (async, non-blocking)
    // This loads cached avatars from database so they're ready immediately
    ref.read(avatarCacheServiceProvider).initialize();

    // Start chat offline service for message retry and sync
    ref.read(chatOfflineServiceProvider).start();

    // Refresh badges when a notification arrives
    FirebaseMessagingService.onMessageReceived = () {
      if (mounted) {
        ref.invalidate(unreadChatCountProvider);
        ref.invalidate(notificationsListProvider);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    // Watch database initialization state
    final dbState = ref.watch(databaseInitializerProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard design size (iPhone X)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // Watch theme and router HERE, after ScreenUtil is initialized
        final appTheme = ref.watch(lightThemeProvider);
        final appRouter = ref.watch(appRouterProvider);

        return MaterialApp.router(
          title: 'Moments',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          routerConfig: appRouter,
          builder: (context, widget) {
            // Ensure textScaler is set for consistent text sizing
            final mediaQueryData = MediaQuery.of(context);
            final fixedMediaQueryData = mediaQueryData.copyWith(
              textScaler: TextScaler.linear(1.0),
            );

            if (dbState.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (dbState.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error initializing database: ${dbState.error}'),
                ),
              );
            }

            return MediaQuery(data: fixedMediaQueryData, child: widget!);
          },
        );
      },
    );
  }
}
