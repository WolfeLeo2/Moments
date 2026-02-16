import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ghost_mode_service.dart';

part 'ghost_mode_provider.g.dart';

/// Provides a singleton GhostModeService scoped to the current user.
@Riverpod(keepAlive: true)
GhostModeService ghostModeService(Ref ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  final service = GhostModeService(currentUserId: userId);
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
}

/// Stream provider for live friends on the map.
@riverpod
Stream<Map<String, LiveFriend>> liveFriends(Ref ref) {
  final service = ref.watch(ghostModeServiceProvider);
  return service.liveFriendsStream;
}

/// Whether the current user is broadcasting live.
/// Uses a Notifier instead of deprecated StateProvider.
@riverpod
class IsGhostLive extends _$IsGhostLive {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}
