// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(storyRepository)
const storyRepositoryProvider = StoryRepositoryProvider._();

final class StoryRepositoryProvider
    extends
        $FunctionalProvider<StoryRepository, StoryRepository, StoryRepository>
    with $Provider<StoryRepository> {
  const StoryRepositoryProvider._()
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

String _$storyRepositoryHash() => r'7020e0e71a7d041f9558434071d2708ef4402329';

/// Fetches all active stories from friends, grouped by user.
/// Auto-refreshes every 30 seconds.

@ProviderFor(FriendsStories)
const friendsStoriesProvider = FriendsStoriesProvider._();

/// Fetches all active stories from friends, grouped by user.
/// Auto-refreshes every 30 seconds.
final class FriendsStoriesProvider
    extends $AsyncNotifierProvider<FriendsStories, List<StoryGroup>> {
  /// Fetches all active stories from friends, grouped by user.
  /// Auto-refreshes every 30 seconds.
  const FriendsStoriesProvider._()
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

String _$friendsStoriesHash() => r'b9f5f2b42cc6879f69d50d54991354881c17b039';

/// Fetches all active stories from friends, grouped by user.
/// Auto-refreshes every 30 seconds.

abstract class _$FriendsStories extends $AsyncNotifier<List<StoryGroup>> {
  FutureOr<List<StoryGroup>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
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
    element.handleValue(ref, created);
  }
}

/// Fetch viewers of a specific story.

@ProviderFor(storyViewers)
const storyViewersProvider = StoryViewersFamily._();

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
  const StoryViewersProvider._({
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
  const StoryViewersFamily._()
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
