import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:moments/features/notifications/presentation/notifications_page.dart';
import 'package:moments/features/chat/presentation/chat_page.dart';
import 'package:moments/features/chat/presentation/chat_list_page.dart';
import 'package:moments/core/services/firebase_messaging_service.dart';
import 'package:moments/features/map/providers/map_control_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:moments/data/models/moment.dart';
import 'package:moments/features/moments/presentation/moment_details_page.dart';

/// Handles navigation from push notification taps.
///
/// Notification types:
/// - 'friend_request' -> Notifications Page (Requests tab)
/// - 'new_message' -> Chat Page with the specific conversation
/// - 'moment_invite' -> Map Page with camera pan
/// - 'system' -> Notifications Page
class NotificationNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Initialize the notification tap handler.
  /// Call this early in the app lifecycle (e.g., in main.dart after runApp).
  static void initialize() {
    FirebaseMessagingService.onNotificationTap = _handleNotificationTap;
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final relatedId = data['related_id'] as String?;
    final actorId = data['actor_id'] as String?;

    debugPrint(
      'NotificationNavigator: type=$type, relatedId=$relatedId, actorId=$actorId',
    );

    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('NotificationNavigator: No context available');
      return;
    }

    switch (type) {
      case 'friend_request':
        // Navigate to Notifications page (Requests tab is index 1)
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
        break;

      case 'message': // The type in DB is 'message', not 'new_message'
      case 'new_message':
        if (actorId != null) {
          // Use actor_id (sender) to open chat
          _navigateToChat(context, actorId);
        } else if (relatedId != null) {
          // Fallback: if relatedId is conversation_id, we can't easily get friend details without query.
          // Just go to chat list.
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ChatListPage()));
        } else {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ChatListPage()));
        }
        break;

      case 'moment_invite':
      case 'collaboration_invite': // The type in DB is 'collaboration_invite'
        // User requested: "Why navigate to the moment detail page yet the accepting or rejecting part is in the notifications page?"
        // So we navigate to NotificationsPage for invites.
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
        break;

      case 'new_moment_group':
        // User requested: "Friend A posted a new moment... it moves to the map"
        if (relatedId != null) {
          _navigateToMomentLocation(context, relatedId);
        }
        break;

      case 'new_moment_post':
        // User requested: "Same for newly added moments in a moment group... opens the moment details page"
        if (relatedId != null) {
          _navigateToMomentDetails(context, relatedId);
        }
        break;

      case 'system':
      case 'promo':
      default:
        // Default to notifications page
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
        break;
    }
  }

  /// Navigate to a specific chat.
  /// [friendId] should be the friend's user_id.
  static Future<void> _navigateToChat(
    BuildContext context,
    String friendId,
  ) async {
    try {
      // Fetch friend's profile to get name and avatar
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('profiles')
          .select('id, display_name, avatar_url')
          .eq('id', friendId)
          .maybeSingle();

      if (response != null) {
        final friendName = response['display_name'] as String? ?? 'Friend';
        final friendAvatarUrl = response['avatar_url'] as String?;

        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatPage(
                friendId: friendId,
                friendName: friendName,
                friendAvatarUrl: friendAvatarUrl,
              ),
            ),
          );
        }
      } else {
        // Fallback to chat list
        if (context.mounted) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ChatListPage()));
        }
      }
    } catch (e) {
      debugPrint('Error navigating to chat: $e');
      if (context.mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ChatListPage()));
      }
    }
  }

  static Future<void> _navigateToMomentDetails(
    BuildContext context,
    String momentGroupId,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch the moment group details
      final groupResponse = await supabase
          .from('moment_groups')
          .select('place_name')
          .eq('id', momentGroupId)
          .maybeSingle();

      final placeName = groupResponse?['place_name'] as String? ?? 'Moment';

      // 2. Fetch the moments for this group
      final momentsResponse = await supabase
          .from('moments')
          .select('*')
          .eq('moment_group_id', momentGroupId)
          .order('created_at', ascending: false);

      final List<dynamic> data = momentsResponse as List<dynamic>;
      final List<Moment> moments = data
          .map((json) => Moment.fromJson(json))
          .toList();

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MomentDetailsPage(
              locationName: placeName,
              moments: moments,
              initialPage: 0,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to moment details: $e');
      if (context.mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
      }
    }
  }

  static Future<void> _navigateToMomentLocation(
    BuildContext context,
    String momentId,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      // Check moment_groups first (for invites)
      final response = await supabase
          .from('moment_groups')
          .select('latitude, longitude')
          .eq('id', momentId)
          .maybeSingle();

      if (response != null &&
          response['latitude'] != null &&
          response['longitude'] != null) {
        final lat = response['latitude'] as double;
        final lng = response['longitude'] as double;

        if (context.mounted) {
          // Pop until we are at the root (MapPage)
          Navigator.of(context).popUntil((route) => route.isFirst);

          // Trigger camera move via Riverpod
          // We use the container from the context to access the provider
          ProviderScope.containerOf(
            context,
          ).read(mapCameraTargetProvider.notifier).setTarget(LatLng(lat, lng));
        }
      } else {
        // Fallback to notifications page
        if (context.mounted) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
        }
      }
    } catch (e) {
      debugPrint('Error navigating to moment: $e');
      if (context.mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
      }
    }
  }
}
