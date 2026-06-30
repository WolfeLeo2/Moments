import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:moments/features/notifications/presentation/notifications_page.dart';
import 'package:moments/features/chat/presentation/chat_page.dart';
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
/// Cold-start: if the tap fires before the widget tree is ready, the payload
/// is stored in [_pending]. [drainIfPending] is called from the router's
/// redirect once auth is confirmed and the tree is mounted.
class NotificationNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ponytail: one pending slot is enough — a cold-start can only have one tap
  static Map<String, dynamic>? _pending;

  static void initialize() {
    FirebaseMessagingService.onNotificationTap = _handleNotificationTap;
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _log.d('NotifNavigator: no context yet, storing pending tap');
      _pending = data;
      return;
    }
    _dispatch(context, data);
  }

  /// Called from the router redirect once the app is signed-in and mounted.
  /// Uses addPostFrameCallback so navigation runs after the redirect settles.
  static void drainIfPending(BuildContext context) {
    final data = _pending;
    if (data == null) return;
    _pending = null;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentContext case final ctx?) {
        _dispatch(ctx, data);
      }
    });
  }

  static void _dispatch(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final relatedId = data['related_id'] as String?;
    final actorId = data['actor_id'] as String?;

    _log.d('NotifNavigator: dispatch type=$type relatedId=$relatedId actorId=$actorId');

    switch (type) {
      case 'friend_request':
      case 'moment_invite':
      case 'collaboration_invite':
      case 'system':
      case 'promo':
        _pushPage(context, const NotificationsPage());

      case 'message':
      case 'new_message':
      case 'chat_message':
        if (actorId != null) {
          _navigateToChat(context, actorId);
        } else {
          context.go('/chats');
        }

      case 'new_moment_group':
        if (relatedId != null) _navigateToMomentLocation(context, relatedId);

      case 'new_moment_post':
        if (relatedId != null) _navigateToMomentDetails(context, relatedId);

      default:
        _pushPage(context, const NotificationsPage());
    }
  }

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
        context.go('/chats');
      }
    } catch (e) {
      _log.e('Error navigating to chat: $e');
      if (context.mounted) context.go('/chats');
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
        context.go('/');
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
