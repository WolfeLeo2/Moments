// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ghost_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton GhostModeService scoped to the current user.

@ProviderFor(ghostModeService)
const ghostModeServiceProvider = GhostModeServiceProvider._();

/// Provides a singleton GhostModeService scoped to the current user.

final class GhostModeServiceProvider
    extends
        $FunctionalProvider<
          GhostModeService,
          GhostModeService,
          GhostModeService
        >
    with $Provider<GhostModeService> {
  /// Provides a singleton GhostModeService scoped to the current user.
  const GhostModeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ghostModeServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ghostModeServiceHash();

  @$internal
  @override
  $ProviderElement<GhostModeService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GhostModeService create(Ref ref) {
    return ghostModeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GhostModeService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GhostModeService>(value),
    );
  }
}

String _$ghostModeServiceHash() => r'a509d5c2730b8b742d2fef996325bdb672eb46ca';

/// Stream provider for live friends on the map.

@ProviderFor(liveFriends)
const liveFriendsProvider = LiveFriendsProvider._();

/// Stream provider for live friends on the map.

final class LiveFriendsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, LiveFriend>>,
          Map<String, LiveFriend>,
          Stream<Map<String, LiveFriend>>
        >
    with
        $FutureModifier<Map<String, LiveFriend>>,
        $StreamProvider<Map<String, LiveFriend>> {
  /// Stream provider for live friends on the map.
  const LiveFriendsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveFriendsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveFriendsHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, LiveFriend>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, LiveFriend>> create(Ref ref) {
    return liveFriends(ref);
  }
}

String _$liveFriendsHash() => r'92e3298a8195b5737db2494bff9cdf745265ceb3';

/// Whether the current user is broadcasting live.
/// Uses a Notifier instead of deprecated StateProvider.

@ProviderFor(IsGhostLive)
const isGhostLiveProvider = IsGhostLiveProvider._();

/// Whether the current user is broadcasting live.
/// Uses a Notifier instead of deprecated StateProvider.
final class IsGhostLiveProvider extends $NotifierProvider<IsGhostLive, bool> {
  /// Whether the current user is broadcasting live.
  /// Uses a Notifier instead of deprecated StateProvider.
  const IsGhostLiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isGhostLiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isGhostLiveHash();

  @$internal
  @override
  IsGhostLive create() => IsGhostLive();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isGhostLiveHash() => r'2edd7098c166a45f2c7e2a84bf8a7f1582ad779b';

/// Whether the current user is broadcasting live.
/// Uses a Notifier instead of deprecated StateProvider.

abstract class _$IsGhostLive extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
