import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:moments/core/providers/database_provider.dart';

import '../data/story_repository.dart';

part 'story_providers.g.dart';

// ═══════════════════════════════════════════════════════════════════
// Repository Provider
// ═══════════════════════════════════════════════════════════════════

@Riverpod(keepAlive: true)
StoryRepository storyRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return StoryRepository(client);
}

// ═══════════════════════════════════════════════════════════════════
// Friends' Stories (grouped by user)
// ═══════════════════════════════════════════════════════════════════

/// Fetches all active stories from friends, grouped by user.
/// Auto-refreshes every 30 seconds.
@riverpod
class FriendsStories extends _$FriendsStories {
  Timer? _refreshTimer;

  @override
  FutureOr<List<StoryGroup>> build() async {
    // Set up periodic refresh
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidateSelf();
    });

    // Clean up on dispose
    ref.onDispose(() => _refreshTimer?.cancel());

    final repo = ref.watch(storyRepositoryProvider);
    return repo.getFriendsStories();
  }

  /// Force refresh stories (e.g., after posting a new story).
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// ═══════════════════════════════════════════════════════════════════
// Story Viewers
// ═══════════════════════════════════════════════════════════════════

/// Fetch viewers of a specific story.
@riverpod
Future<List<StoryViewer>> storyViewers(
  Ref ref, {
  required String storyId,
}) async {
  final repo = ref.watch(storyRepositoryProvider);
  return repo.getStoryViewers(storyId);
}
