import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:moments/features/notifications/presentation/notifications_page.dart';
import 'package:moments/features/chat/presentation/chat_page.dart';
import 'package:moments/features/chat/presentation/chat_list_page.dart';
import 'package:moments/core/services/firebase_messaging_service.dart';
import 'package:moments/features/mapv2/providers/map_control_provider.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/providers/moments_providers.dart';
import 'package:moments/core/providers/powersync_provider.dart';
import 'package:moments/data/models/moment.dart';

import 'package:moments/features/moments/presentation/moment_details_page.dart';
import 'package:moments/core/services/app_logger.dart';

final _log = AppLogger('NotifNavigator');

/// Handles navigation from push notification taps.
///
/// Notification types:
/// - 'friend_request' -> Notifications Page (Requests tab)
/// - 'new_message' -> Chat Page with the specific conversation
/// - 'moment_invite' -> Notifications Page (for accept/decline)
/// - 'new_moment_group' -> Map Page with camera pan
/// - 'new_moment_post' -> Moment Details Page
/// - 'system'/'promo'/default -> Notifications Page
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

    _log.d(
      'NotificationNavigator: type=$type, relatedId=$relatedId, actorId=$actorId',
    );

    final context = navigatorKey.currentContext;
    if (context == null) {
      // Cold-start: widget tree hasn't mounted yet. Retry after a short delay.
      _log.d('NotificationNavigator: No context yet, scheduling retry');
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(data);
      });
      return;
    }

    switch (type) {
      case 'friend_request':
        _pushPage(context, const NotificationsPage());
        break;

      case 'message':
      case 'new_message':
      case 'chat_message':
        if (actorId != null) {
          _navigateToChat(context, actorId);
        } else {
          _pushPage(context, const ChatListPage());
        }
        break;

      case 'moment_invite':
      case 'collaboration_invite':
        // Navigate to NotificationsPage for accept/decline actions
        _pushPage(context, const NotificationsPage());
        break;

      case 'new_moment_group':
        if (relatedId != null) {
          _navigateToMomentLocation(context, relatedId);
        }
        break;

      case 'new_moment_post':
        if (relatedId != null) {
          _navigateToMomentDetails(context, relatedId);
        }
        break;

      case 'system':
      case 'promo':
      default:
        _pushPage(context, const NotificationsPage());
        break;
    }
  }

  /// Push a page using Navigator (works with GoRouter's navigatorKey)
  static void _pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  /// Navigate to a specific chat using the social repository provider.
  static Future<void> _navigateToChat(
    BuildContext context,
    String friendId,
  ) async {
    try {
      // Use the repository via Riverpod instead of raw Supabase queries
      final container = ProviderScope.containerOf(context, listen: false);
      final socialRepo = container.read(socialRepositoryProvider);
      final profile = await socialRepo.getProfileById(friendId);

      if (profile != null && context.mounted) {
        _pushPage(
          context,
          ChatPage(
            friendId: friendId,
            friendName: profile.displayName ?? 'Friend',
            friendAvatarUrl: profile.avatarUrl,
          ),
        );
      } else if (context.mounted) {
        _pushPage(context, const ChatListPage());
      }
    } catch (e) {
      _log.e('Error navigating to chat: $e');
      if (context.mounted) {
        _pushPage(context, const ChatListPage());
      }
    }
  }

  /// Navigate to moment details using the moment repository provider.
  static Future<void> _navigateToMomentDetails(
    BuildContext context,
    String momentGroupId,
  ) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final moments = await _getMomentsByGroupLocalFirst(
        container,
        momentGroupId,
      );
      if (moments.isNotEmpty && context.mounted) {
        _pushPage(
          context,
          MomentDetailsPage(
            locationName: moments.first.location,
            moments: moments,
            initialPage: 0,
          ),
        );
      } else if (context.mounted) {
        _pushPage(context, const NotificationsPage());
      }
    } catch (e) {
      _log.e('Error navigating to moment details: $e');
      if (context.mounted) {
        _pushPage(context, const NotificationsPage());
      }
    }
  }

  /// Navigate to a moment's location on the map using the moment repository.
  static Future<void> _navigateToMomentLocation(
    BuildContext context,
    String momentGroupId,
  ) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);

      // Get moments for this group to find the location.
      final moments = await _getMomentsByGroupLocalFirst(
        container,
        momentGroupId,
      );
      if (moments.isNotEmpty && context.mounted) {
        final moment = moments.first;

        // Pop to root (map page)
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Trigger camera move via Riverpod
        container
            .read(mapCameraTargetProvider.notifier)
            .setTarget(LatLng(moment.latitude, moment.longitude));
      } else if (context.mounted) {
        _pushPage(context, const NotificationsPage());
      }
    } catch (e) {
      _log.e('Error navigating to moment location: $e');
      if (context.mounted) {
        _pushPage(context, const NotificationsPage());
      }
    }
  }

  static Future<List<Moment>> _getMomentsByGroupLocalFirst(
    ProviderContainer container,
    String groupId,
  ) async {
    final powerSync = container.read(chatPowerSyncServiceProvider);
    final initialized = await powerSync.ensureInitialized();
    if (initialized) {
      final local = await powerSync.getMomentsByGroup(groupId);
      if (local.isNotEmpty) {
        return local;
      }
    }

    final momentRepo = container.read(momentRepositoryProvider);
    return momentRepo.getMomentsByGroup(groupId);
  }
}
