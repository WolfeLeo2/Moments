import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:moments/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moments/core/services/app_logger.dart';
import 'package:moments/core/services/chat_encryption_service.dart';

final _log = AppLogger('FCM');
// Action keys
const String _actionReply = 'REPLY';
const String _actionMarkRead = 'MARK_READ';

// Supabase config (hardcoded for background isolates)
const String _supabaseUrl = 'https://voxutceosbctxfmlqjfk.supabase.co';
const String _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZveHV0Y2Vvc2JjdHhmbWxxamZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI0NTEzNjcsImV4cCI6MjA3ODAyNzM2N30.s2oXwNXV6UcJ4tMHWjZFxxG6JvsA32gqrToGoFhTwC0';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _log.d("Handling a background message: ${message.messageId}");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Load env vars for encryption key
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      _log.w("Failed to load .env in background handler");
    }

    try {
      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
    } catch (_) {}
  } catch (e) {
    _log.e("Failed to initialize background services: $e");
  }

  await FirebaseMessagingService.showRichNotification(message);
}

// Top-level handler for notification actions (required for background)
@pragma('vm:entry-point')
Future<void> _notificationActionHandler(NotificationResponse response) async {
  _log.d('=== BACKGROUND ACTION HANDLER TRIGGERED ===');
  _log.d('ActionId: ${response.actionId}');
  _log.d('Input: ${response.input}');
  _log.d('Payload: ${response.payload}');

  // Initialize services first
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  // Load env vars for encryption key
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    _log.w("Failed to load .env in action handler");
  }

  try {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  } catch (_) {}

  await FirebaseMessagingService._handleNotificationAction(response);
}

/// A callback type for handling notification taps.
typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  SupabaseClient get _supabase => Supabase.instance.client;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Platform channel for native Android calls
  static const platform = MethodChannel('com.wolfeleo2.moments/notifications');

  static NotificationTapCallback? onNotificationTap;
  static VoidCallback? onMessageReceived;
  static String? currentChatId;

  /// Cancel all local notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel a specific notification by its related ID
  static Future<void> cancelNotificationByRelatedId(String relatedId) async {
    await _localNotifications.cancel(relatedId.hashCode);
  }

  // Initialize Notification Settings
  Future<void> initialize() async {
    // 1. Initialize Local Notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleNotificationAction,
      onDidReceiveBackgroundNotificationResponse: _notificationActionHandler,
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

    // 3. Create Android Notification Channels
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Chats channel - for direct messages
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'chats',
          'Messages',
          description: 'Chat messages and conversations',
          importance: Importance.max,
        ),
      );

      // Social channel - for friend requests, reactions
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'social',
          'Social',
          description: 'Friend requests, likes, and reactions',
          importance: Importance.high,
        ),
      );

      // Moments channel - for collab invites, new moments
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'moments',
          'Moments',
          description: 'Collaboration invites and new moment notifications',
          importance: Importance.high,
        ),
      );
    }

    // 4. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final relatedId = data['related_id'] as String?;
      final type = data['type'] as String?;

      // Suppress if user is viewing this chat
      if ((type == 'message' || type == 'chat_message') &&
          relatedId != null &&
          relatedId == currentChatId) {
        return;
      }

      showRichNotification(message);
      onMessageReceived?.call();
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

  /// Handle notification action buttons (Reply, Mark as Read)
  static Future<void> _handleNotificationAction(
    NotificationResponse response,
  ) async {
    final actionId = response.actionId;
    final payload = response.payload;
    final inputText = response.input;

    _log.d('Action received - id: $actionId, input: $inputText');
    _log.d('Payload: $payload');

    if (payload == null) {
      _log.d('No payload, cannot process action');
      return;
    }

    // Parse payload
    final data = Uri.splitQueryString(payload);
    final conversationId = data['related_id'];

    // Debug info
    _log.d('Parsed conversationId: $conversationId');

    if (conversationId == null) {
      _log.d('No conversation ID in payload');
      return;
    }

    // Initialize Firebase and Supabase for background
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      _log.d('Firebase already initialized or init failed: $e');
    }

    // Load env vars for encryption key (just in case not loaded yet)
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      _log.d('Dotenv already loaded or load failed: $e');
    }

    try {
      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
    } catch (e) {
      _log.d('Supabase already initialized or init failed: $e');
    }

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    _log.d('Current user ID: $currentUserId');

    if (currentUserId == null) {
      _log.d('User not authenticated - cannot process action');
      // Still dismiss the notification
      await _localNotifications.cancel(conversationId.hashCode);
      return;
    }

    switch (actionId) {
      case _actionReply:
        if (inputText != null && inputText.trim().isNotEmpty) {
          _log.d('Sending reply: "$inputText"');
          await _sendReply(supabase, conversationId, currentUserId, inputText);
        } else {
          _log.d('Empty reply text');
        }
        break;
      case _actionMarkRead:
        _log.d('Marking as read');
        await _markAsRead(supabase, conversationId, currentUserId);
        break;
      default:
        // Regular tap - navigate to chat
        _log.d('Regular tap, navigating');
        onNotificationTap?.call(data);
    }
  }

  /// Send a reply message via Supabase
  static Future<void> _sendReply(
    SupabaseClient supabase,
    String conversationId,
    String senderId,
    String content,
  ) async {
    try {
      _log.d('Inserting message to conversation: $conversationId');

      // Encrypt content
      final encryption = ChatEncryptionService.instance;
      final encryptedContent = encryption.encrypt(
        content.trim(),
        conversationId,
      );

      // Insert the message
      await supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': encryptedContent,
        // 'created_at': Let Postgres default to now()
      });

      // Update conversation's updated_at timestamp
      await supabase
          .from('conversations')
          .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', conversationId);

      _log.d('Reply sent successfully');

      // Dismiss the notification
      await _localNotifications.cancel(conversationId.hashCode);
    } catch (e, stack) {
      _log.e('Error sending reply: $e');
      _log.e('Stack: $stack');
      // Still dismiss the notification even on error
      await _localNotifications.cancel(conversationId.hashCode);
    }
  }

  /// Mark all messages in conversation as read
  static Future<void> _markAsRead(
    SupabaseClient supabase,
    String conversationId,
    String userId,
  ) async {
    try {
      _log.d('Marking messages as read in: $conversationId');

      // Mark all unread messages from OTHER people as read
      final result = await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false)
          .select();

      _log.d('Mark as read result: ${result.length} messages updated');

      // Dismiss the notification
      await _localNotifications.cancel(conversationId.hashCode);
    } catch (e, stack) {
      _log.e('Error marking as read: $e');
      _log.e('Stack: $stack');
      // Still dismiss the notification even on error
      await _localNotifications.cancel(conversationId.hashCode);
    }
  }

  Future<void> _handleToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) await _saveTokenToDatabase(token);
    } catch (e) {
      _log.e("Error getting FCM token: $e");
    }
  }

  Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      onNotificationTap?.call(initialMessage.data);
    }
  }

  /// Downloads an avatar image and returns its bytes
  static Future<Uint8List?> _downloadAvatar(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      _log.e('Error downloading avatar: $e');
    }
    return null;
  }

  /// Crops an image to a circle
  static Future<Uint8List?> _cropToCircle(Uint8List imageBytes) async {
    try {
      // Decode the image
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Create a square crop (use smaller dimension)
      final size = image.width < image.height ? image.width : image.height;

      // Create a picture recorder
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Create circular clip path
      final paint = ui.Paint()..isAntiAlias = true;
      final path = ui.Path()
        ..addOval(ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
      canvas.clipPath(path);

      // Draw the image centered
      final srcRect = ui.Rect.fromLTWH(
        (image.width - size) / 2,
        (image.height - size) / 2,
        size.toDouble(),
        size.toDouble(),
      );
      final dstRect = ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
      canvas.drawImageRect(image, srcRect, dstRect, paint);

      // Convert to image
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(size, size);
      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      _log.e('Error cropping image to circle: $e');
      return imageBytes; // Return original if cropping fails
    }
  }

  /// Shows a rich notification with MessagingStyle for Android
  static Future<void> showRichNotification(RemoteMessage message) async {
    try {
      final data = message.data;
      final senderName =
          data['actor_name'] as String? ?? data['title'] ?? 'Moments';
      var body = data['body'] ?? message.notification?.body ?? '';
      final avatarUrl =
          data['avatar_url'] as String? ?? data['sender_avatar_url'] as String?;
      final actorId = data['actor_id'] as String?;
      final conversationId = data['related_id'] as String?;

      // Decrypt body if encrypted
      if (conversationId != null) {
        final encryption = ChatEncryptionService.instance;
        // Clean potential encrypted body
        if (encryption.decrypt(body, conversationId) != body) {
          body = encryption.decrypt(body, conversationId);
        } else if (body.startsWith('enc:')) {
          body = encryption.decrypt(body, conversationId);
        }
      }

      // Download avatar
      Uint8List? avatarBytes = await _downloadAvatar(avatarUrl);

      // Manually crop to circle for reliable rounding
      if (avatarBytes != null) {
        avatarBytes = await _cropToCircle(avatarBytes);
      }

      // Determine notification type and channel
      final notificationType = data['type'] as String?;
      final isChat =
          notificationType == 'message' ||
          notificationType == 'chat_message' ||
          notificationType == null;
      final isSocial =
          notificationType == 'friend_request' ||
          notificationType == 'moment_like';
      // Note: Everything else (moment_invite, new_moment_group, etc.) routes to 'moments' channel

      // Channel routing
      String channelId;
      String channelName;
      String channelDesc;
      AndroidNotificationCategory category;

      if (isChat) {
        channelId = 'chats';
        channelName = 'Messages';
        channelDesc = 'Chat messages and conversations';
        category = AndroidNotificationCategory.message;
      } else if (isSocial) {
        channelId = 'social';
        channelName = 'Social';
        channelDesc = 'Friend requests, likes, and reactions';
        category = AndroidNotificationCategory.social;
      } else {
        channelId = 'moments';
        channelName = 'Moments';
        channelDesc = 'Collaboration invites and new moment notifications';
        category = AndroidNotificationCategory.recommendation;
      }

      // Avatar is used as largeIcon for all notification types
      // Android's small icon (@mipmap/launcher_icon) handles app branding with theme support

      // Push Dynamic Shortcut for Android 11+ (only for chats)
      if (Platform.isAndroid && conversationId != null && isChat) {
        try {
          _log.d(
            'Pushing shortcut for $conversationId with avatar bytes: ${avatarBytes?.lengthInBytes}',
          );
          await platform.invokeMethod('pushConversationShortcut', {
            'shortcutId': conversationId,
            'personName': senderName,
            'personIconBytes': avatarBytes,
          });
        } catch (e) {
          _log.e('Error pushing conversation shortcut: $e');
        }
      }

      // Build notification style based on type
      StyleInformation? styleInformation;
      List<AndroidNotificationAction>? actions;

      if (Platform.isAndroid && isChat) {
        // Chat message - use MessagingStyle with reply actions
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        final me = Person(name: 'Me', key: currentUserId, important: true);
        final sender = Person(
          name: senderName,
          key: actorId,
          icon: avatarBytes != null ? ByteArrayAndroidIcon(avatarBytes) : null,
          important: true,
        );

        // Fetch unread messages for history threading
        List<Message> messages = [];
        try {
          final supabase = Supabase.instance.client;
          final recentMessagesData = await supabase
              .from('messages')
              .select('content, created_at, sender_id')
              .eq('conversation_id', conversationId!)
              .eq('is_read', false)
              .order('created_at', ascending: true)
              .limit(10);

          final encryption = ChatEncryptionService.instance;

          for (final msgData in recentMessagesData) {
            var content = msgData['content'] as String? ?? '';
            // Decrypt history content
            try {
              content = encryption.decrypt(content, conversationId);
            } catch (_) {}

            final timestamp =
                DateTime.tryParse(msgData['created_at'].toString()) ??
                DateTime.now();
            final senderId = msgData['sender_id'] as String?;
            final isFromMe = senderId == currentUserId;
            messages.add(Message(content, timestamp, isFromMe ? null : sender));
          }
        } catch (e) {
          _log.e('Error fetching chat history: $e');
        }

        if (messages.isEmpty ||
            (messages.isNotEmpty && messages.last.text != body)) {
          messages.add(Message(body, DateTime.now(), sender));
        }

        styleInformation = MessagingStyleInformation(
          me,
          groupConversation: false,
          messages: messages,
          conversationTitle: senderName,
        );

        // Reply and Mark as Read actions for chats
        actions = [
          const AndroidNotificationAction(
            _actionReply,
            'Reply',
            inputs: [
              AndroidNotificationActionInput(label: 'Type a message...'),
            ],
            showsUserInterface: false,
            cancelNotification: false,
          ),
          const AndroidNotificationAction(
            _actionMarkRead,
            'Mark as Read',
            showsUserInterface: false,
            cancelNotification: false,
          ),
        ];
      } else {
        // Non-chat notifications - use BigTextStyle
        styleInformation = BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: senderName,
          htmlFormatContentTitle: true,
        );
        actions = null; // No actions for non-chat notifications
      }

      // Build Android notification details with correct channel
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: isChat ? Importance.max : Importance.high,
        priority: Priority.high,
        styleInformation: styleInformation,
        largeIcon: avatarBytes != null
            ? ByteArrayAndroidBitmap(avatarBytes)
            : null,
        category: category,
        groupKey: isChat ? conversationId : notificationType,
        shortcutId: isChat ? conversationId : null,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: isChat,
        actions: actions,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Use stable notification ID based on conversation
      final notificationId = conversationId?.hashCode ?? message.hashCode;

      // Encode payload as query string for easy parsing
      final payload = Uri(
        queryParameters: data.map((k, v) => MapEntry(k, v.toString())),
      ).query;

      await _localNotifications.show(
        notificationId,
        senderName,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );
    } catch (e) {
      _log.e('Error showing notification: $e');
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
        'last_active_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'fcm_token');
    } catch (e) {
      _log.e("Error saving FCM token: $e");
    }
  }
}
