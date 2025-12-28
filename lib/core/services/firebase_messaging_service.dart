import 'dart:io';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  // Initialize local notifications for background isolate
  await FirebaseMessagingService.showRichNotification(message);
}

/// A callback type for handling notification taps.
typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static NotificationTapCallback? onNotificationTap;
  // We need a way to access the provider container or a global variable to check current chat
  // Since this is a service, we might need to pass the container or use a static variable updated by the UI
  static String? currentChatId;

  /// Cancel all local notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel a specific notification by its related ID (e.g., conversation ID)
  static Future<void> cancelNotificationByRelatedId(String relatedId) async {
    await _localNotifications.cancel(relatedId.hashCode);
  }

  // Initialize Notification Settings
  Future<void> initialize() async {
    // 1. Initialize Local Notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) async {
        // Cancel the notification that was tapped
        if (response.id != null) {
          await _localNotifications.cancel(response.id!);
        }

        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            onNotificationTap?.call(data);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    // 2. Request FCM Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    // 3. Create Android Channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'high_importance_channel',
              'Moments Notifications',
              description:
                  'Notifications for friend requests, messages, and updates',
              importance: Importance.max,
            ),
          );
    }

    // 4. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Check if we should suppress this notification
      final data = message.data;
      final relatedId = data['related_id'] as String?;
      final type = data['type'] as String?;

      // If it's a message and we are currently viewing this conversation, don't show notification
      if ((type == 'message' || type == 'chat_message') &&
          relatedId != null &&
          relatedId == currentChatId) {
        return;
      }

      showRichNotification(message);
    });

    // 6. Handle Token
    _handleToken();
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) _handleToken();
    });

    // 7. Handle Initial/Background Taps
    _handleInitialMessage();
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationTap?.call(message.data);
    });
  }

  Future<void> _handleToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) await _saveTokenToDatabase(token);
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
    }
  }

  Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      onNotificationTap?.call(initialMessage.data);
    }
  }

  /// Shows a rich notification with WhatsApp-style avatar using MessagingStyle
  /// The sender's avatar appears as the main icon with app icon as a small badge
  static Future<void> showRichNotification(RemoteMessage message) async {
    try {
      final data = message.data;
      // Use actor_name (display name) as the sender name
      final senderName =
          data['actor_name'] as String? ?? data['title'] ?? 'Moments';
      final body = data['body'] ?? message.notification?.body ?? '';
      final avatarUrl = data['avatar_url'] as String?;
      final type = data['type'] as String?;
      final actorId = data['actor_id'] as String?;

      // Download avatar if available
      Uint8List? avatarBytes;

      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(avatarUrl));
          if (response.statusCode == 200) {
            avatarBytes = response.bodyBytes;
          }
        } catch (e) {
          debugPrint('Error downloading avatar: $e');
        }
      }

      // Build the notification style
      StyleInformation styleInformation;

      if (avatarBytes != null) {
        // WhatsApp-style: MessagingStyle with Person (avatar as main icon)
        final person = Person(
          name: senderName,
          icon: ByteArrayAndroidIcon(avatarBytes),
          key: actorId,
        );

        styleInformation = MessagingStyleInformation(
          person,
          groupConversation: false,
          messages: [Message(body, DateTime.now(), person)],
        );
      } else {
        // Fallback: BigTextStyle when no avatar
        styleInformation = BigTextStyleInformation(
          body,
          contentTitle: senderName,
          summaryText: 'Moments',
        );
      }

      final androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Moments Notifications',
        channelDescription:
            'Notifications for friend requests, messages, and updates',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: styleInformation,
        color: AppTheme.primaryBlue,
        category: type == 'message'
            ? AndroidNotificationCategory.message
            : null,
        autoCancel: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Use a stable notification ID based on related_id for grouping/updating
      final relatedId = data['related_id'] as String?;
      final notificationId = relatedId?.hashCode ?? message.hashCode;

      await _localNotifications.show(
        notificationId,
        senderName,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('user_devices').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'last_active_at': DateTime.now().toIso8601String(),
      }, onConflict: 'fcm_token');
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }
}
