import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/story_repository.dart';

part 'story_providers.g.dart';

// ═══════════════════════════════════════════════════════════════════
// Repository Provider
// ═══════════════════════════════════════════════════════════════════

@Riverpod(keepAlive: true)
StoryRepository storyRepository(Ref ref) => StoryRepository();

/// Explicit refresh signal for stories.
/// Bumped by bounded app events (post/delete/view lifecycle), not timers.
@Riverpod(keepAlive: true)
class StoriesRefreshSignal extends _$StoriesRefreshSignal {
  @override
  int build() => 0;

  void bump() => state++;
}

// ═══════════════════════════════════════════════════════════════════
// Friends' Stories (grouped by user)
// ═══════════════════════════════════════════════════════════════════

/// Fetches all active stories from friends, grouped by user.
/// Refreshes explicitly via [storiesRefreshSignalProvider].
@riverpod
class FriendsStories extends _$FriendsStories {
  @override
  FutureOr<List<StoryGroup>> build() async {
    // Recompute only when an explicit event bumps this signal.
    ref.watch(storiesRefreshSignalProvider);

    final repo = ref.watch(storyRepositoryProvider);
    return repo.getFriendsStories();
  }

  /// Force refresh stories (e.g., after posting a new story).
  Future<void> refresh() async {
    ref.read(storiesRefreshSignalProvider.notifier).bump();
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
