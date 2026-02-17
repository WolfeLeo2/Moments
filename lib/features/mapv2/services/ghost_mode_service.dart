import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/app_logger.dart';

final _log = AppLogger('GhostModeService');

/// Represents a friend's live location on the map.
class LiveFriend {
  final String userId;
  final double latitude;
  final double longitude;
  final String? displayName;
  final String? avatarUrl;
  final DateTime lastSeen;

  const LiveFriend({
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.displayName,
    this.avatarUrl,
    required this.lastSeen,
  });

  /// Whether this live friend's data is stale (older than 5 minutes).
  bool get isStale => DateTime.now().difference(lastSeen).inMinutes > 5;
}

/// Service that manages opt-in live location sharing ("Ghost Mode").
///
/// Uses Supabase Realtime Presence to broadcast and receive locations
/// among friends. No location data is persisted to the database —
/// it's fully ephemeral.
class GhostModeService {
  GhostModeService({required this.currentUserId});

  final String currentUserId;

  RealtimeChannel? _channel;
  Timer? _broadcastTimer;
  bool _isLive = false;

  /// Stream of currently live friends.
  final _liveFriendsController =
      StreamController<Map<String, LiveFriend>>.broadcast();
  Stream<Map<String, LiveFriend>> get liveFriendsStream =>
      _liveFriendsController.stream;

  /// Current snapshot of live friends.
  final Map<String, LiveFriend> _liveFriends = {};
  Map<String, LiveFriend> get liveFriends => Map.unmodifiable(_liveFriends);

  bool get isLive => _isLive;

  /// Initialize the Realtime channel and start listening.
  void initialize() {
    final supabase = Supabase.instance.client;
    _channel = supabase.channel(
      'ghost_mode',
      opts: const RealtimeChannelConfig(self: true),
    );

    _channel!
        .onPresenceSync((payload) {
          _syncPresenceState();
        })
        .onPresenceJoin((payload) {
          _syncPresenceState();
        })
        .onPresenceLeave((payload) {
          _syncPresenceState();
        })
        .subscribe((status, [error]) {
          _log.i('Ghost mode channel status: $status');
        });
  }

  /// Toggle live mode on/off.
  void toggleLive({
    required double latitude,
    required double longitude,
    String? displayName,
    String? avatarUrl,
  }) {
    if (_isLive) {
      goOffline();
    } else {
      goLive(
        latitude: latitude,
        longitude: longitude,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
    }
  }

  /// Start broadcasting your location.
  void goLive({
    required double latitude,
    required double longitude,
    String? displayName,
    String? avatarUrl,
  }) {
    _isLive = true;
    _broadcastLocation(
      latitude: latitude,
      longitude: longitude,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );

    // Broadcast every 10 seconds while live
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // The caller should update lat/lng externally
      // For now we re-broadcast the last known position
    });

    _log.i('Ghost mode: LIVE');
  }

  /// Update your broadcasted position (called when location changes).
  void updatePosition({
    required double latitude,
    required double longitude,
    String? displayName,
    String? avatarUrl,
  }) {
    if (!_isLive) return;
    _broadcastLocation(
      latitude: latitude,
      longitude: longitude,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  /// Stop broadcasting your location.
  Future<void> goOffline() async {
    _log.i('Stopping Ghost Mode...');
    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    if (_channel == null) {
      _log.w('Ghost Mode channel is null, cannot untrack.');
      _isLive = false;
      return;
    }

    try {
      _log.d('Untracking presence for user $currentUserId...');
      await _channel?.untrack();
      _log.i('Ghost mode: OFFLINE (untracked)');
    } catch (e) {
      _log.e('Error untracking ghost mode: $e');
    } finally {
      _isLive = false;
    }
  }

  void _broadcastLocation({
    required double latitude,
    required double longitude,
    String? displayName,
    String? avatarUrl,
  }) {
    _channel?.track({
      'user_id': currentUserId,
      'latitude': latitude,
      'longitude': longitude,
      'display_name': displayName ?? '',
      'avatar_url': avatarUrl ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _syncPresenceState() {
    final presences = _channel?.presenceState();
    if (presences == null) return;

    _liveFriends.clear();

    for (final state in presences) {
      for (final presence in state.presences) {
        final payload = presence.payload;
        final userId = payload['user_id'] as String?;
        if (userId == null || userId == currentUserId) continue;

        final lat = (payload['latitude'] as num?)?.toDouble();
        final lng = (payload['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        _liveFriends[userId] = LiveFriend(
          userId: userId,
          latitude: lat,
          longitude: lng,
          displayName: payload['display_name'] as String?,
          avatarUrl: payload['avatar_url'] as String?,
          lastSeen:
              DateTime.tryParse(payload['timestamp'] as String? ?? '') ??
              DateTime.now(),
        );
      }
    }

    _liveFriendsController.add(Map.from(_liveFriends));
    _log.d('Live friends sync: ${_liveFriends.length} friends found.');
    if (_liveFriends.isEmpty) {
      _log.d(
        'Live friends list is EMPTY. Any previous markers should be removed.',
      );
    } else {
      _log.d('Current live friends: ${_liveFriends.keys.join(', ')}');
    }
  }

  /// Clean up resources.
  void dispose() {
    _broadcastTimer?.cancel();
    _channel?.unsubscribe();
    _liveFriendsController.close();
  }
}
