// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtime_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stream of real-time pending friend requests

@ProviderFor(pendingRequestsRealtime)
final pendingRequestsRealtimeProvider = PendingRequestsRealtimeProvider._();

/// Stream of real-time pending friend requests

final class PendingRequestsRealtimeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Friendship>>,
          List<Friendship>,
          Stream<List<Friendship>>
        >
    with $FutureModifier<List<Friendship>>, $StreamProvider<List<Friendship>> {
  /// Stream of real-time pending friend requests
  PendingRequestsRealtimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingRequestsRealtimeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingRequestsRealtimeHash();

  @$internal
  @override
  $StreamProviderElement<List<Friendship>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Friendship>> create(Ref ref) {
    return pendingRequestsRealtime(ref);
  }
}

String _$pendingRequestsRealtimeHash() =>
    r'47b524a25f7212eee71c5c3705b5fdeac9036bb3';

/// Combined friends and requests data - properly reactive
/// Updates whenever either friends list or pending requests change

@ProviderFor(friendsAndRequests)
final friendsAndRequestsProvider = FriendsAndRequestsProvider._();

/// Combined friends and requests data - properly reactive
/// Updates whenever either friends list or pending requests change

final class FriendsAndRequestsProvider
    extends
        $FunctionalProvider<
          ({List<Profile> friends, List<Friendship> requests}),
          ({List<Profile> friends, List<Friendship> requests}),
          ({List<Profile> friends, List<Friendship> requests})
        >
    with $Provider<({List<Profile> friends, List<Friendship> requests})> {
  /// Combined friends and requests data - properly reactive
  /// Updates whenever either friends list or pending requests change
  FriendsAndRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendsAndRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendsAndRequestsHash();

  @$internal
  @override
  $ProviderElement<({List<Profile> friends, List<Friendship> requests})>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ({List<Profile> friends, List<Friendship> requests}) create(Ref ref) {
    return friendsAndRequests(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ({List<Profile> friends, List<Friendship> requests}) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            ({List<Profile> friends, List<Friendship> requests})
          >(value),
    );
  }
}

String _$friendsAndRequestsHash() =>
    r'd72a0eb5d3689901fef57c5df05f1bb2b224dbc2';

/// Async version that waits for both to load

@ProviderFor(friendsAndRequestsAsync)
final friendsAndRequestsAsyncProvider = FriendsAndRequestsAsyncProvider._();

/// Async version that waits for both to load

final class FriendsAndRequestsAsyncProvider
    extends
        $FunctionalProvider<
          AsyncValue<({List<Profile> friends, List<Friendship> requests})>,
          ({List<Profile> friends, List<Friendship> requests}),
          FutureOr<({List<Profile> friends, List<Friendship> requests})>
        >
    with
        $FutureModifier<({List<Profile> friends, List<Friendship> requests})>,
        $FutureProvider<({List<Profile> friends, List<Friendship> requests})> {
  /// Async version that waits for both to load
  FriendsAndRequestsAsyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendsAndRequestsAsyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendsAndRequestsAsyncHash();

  @$internal
  @override
  $FutureProviderElement<({List<Profile> friends, List<Friendship> requests})>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<({List<Profile> friends, List<Friendship> requests})> create(
    Ref ref,
  ) {
    return friendsAndRequestsAsync(ref);
  }
}

String _$friendsAndRequestsAsyncHash() =>
    r'f510ee66d50079bc8e722e768625bd74ede51ae8';
