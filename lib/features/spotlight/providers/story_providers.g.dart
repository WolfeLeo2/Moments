// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(storyRepository)
final storyRepositoryProvider = StoryRepositoryProvider._();

final class StoryRepositoryProvider
    extends
        $FunctionalProvider<StoryRepository, StoryRepository, StoryRepository>
    with $Provider<StoryRepository> {
  StoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storyRepositoryHash();

  @$internal
  @override
  $ProviderElement<StoryRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StoryRepository create(Ref ref) {
    return storyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StoryRepository>(value),
    );
  }
}

String _$storyRepositoryHash() => r'acad042ba42b6f6cd79829778bfe567680e612a7';

/// Explicit refresh signal for stories.
/// Bumped by bounded app events (post/delete/view lifecycle), not timers.

@ProviderFor(StoriesRefreshSignal)
final storiesRefreshSignalProvider = StoriesRefreshSignalProvider._();

/// Explicit refresh signal for stories.
/// Bumped by bounded app events (post/delete/view lifecycle), not timers.
final class StoriesRefreshSignalProvider
    extends $NotifierProvider<StoriesRefreshSignal, int> {
  /// Explicit refresh signal for stories.
  /// Bumped by bounded app events (post/delete/view lifecycle), not timers.
  StoriesRefreshSignalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storiesRefreshSignalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storiesRefreshSignalHash();

  @$internal
  @override
  StoriesRefreshSignal create() => StoriesRefreshSignal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$storiesRefreshSignalHash() =>
    r'47bc4419e7fd6b9b896391a74adc778f7b2e2f8b';

/// Explicit refresh signal for stories.
/// Bumped by bounded app events (post/delete/view lifecycle), not timers.

abstract class _$StoriesRefreshSignal extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Fetches all active stories from friends, grouped by user.
/// Refreshes explicitly via [storiesRefreshSignalProvider].

@ProviderFor(FriendsStories)
final friendsStoriesProvider = FriendsStoriesProvider._();

/// Fetches all active stories from friends, grouped by user.
/// Refreshes explicitly via [storiesRefreshSignalProvider].
final class FriendsStoriesProvider
    extends $AsyncNotifierProvider<FriendsStories, List<StoryGroup>> {
  /// Fetches all active stories from friends, grouped by user.
  /// Refreshes explicitly via [storiesRefreshSignalProvider].
  FriendsStoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendsStoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendsStoriesHash();

  @$internal
  @override
  FriendsStories create() => FriendsStories();
}

String _$friendsStoriesHash() => r'd2b09d1ef06e659d3ef9ada4ee0bbc162af931ea';

/// Fetches all active stories from friends, grouped by user.
/// Refreshes explicitly via [storiesRefreshSignalProvider].

abstract class _$FriendsStories extends $AsyncNotifier<List<StoryGroup>> {
  FutureOr<List<StoryGroup>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<StoryGroup>>, List<StoryGroup>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<StoryGroup>>, List<StoryGroup>>,
              AsyncValue<List<StoryGroup>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Fetch viewers of a specific story.

@ProviderFor(storyViewers)
final storyViewersProvider = StoryViewersFamily._();

/// Fetch viewers of a specific story.

final class StoryViewersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StoryViewer>>,
          List<StoryViewer>,
          FutureOr<List<StoryViewer>>
        >
    with
        $FutureModifier<List<StoryViewer>>,
        $FutureProvider<List<StoryViewer>> {
  /// Fetch viewers of a specific story.
  StoryViewersProvider._({
    required StoryViewersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'storyViewersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$storyViewersHash();

  @override
  String toString() {
    return r'storyViewersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<StoryViewer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StoryViewer>> create(Ref ref) {
    final argument = this.argument as String;
    return storyViewers(ref, storyId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StoryViewersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$storyViewersHash() => r'f9428c421a98d9581d9cf22426e6074aff5c2426';

/// Fetch viewers of a specific story.

final class StoryViewersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<StoryViewer>>, String> {
  StoryViewersFamily._()
    : super(
        retry: null,
        name: r'storyViewersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetch viewers of a specific story.

  StoryViewersProvider call({required String storyId}) =>
      StoryViewersProvider._(argument: storyId, from: this);

  @override
  String toString() => r'storyViewersProvider';
}
