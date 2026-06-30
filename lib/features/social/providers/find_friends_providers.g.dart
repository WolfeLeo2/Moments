// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'find_friends_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Searches profiles when query is >= 2 chars.
/// Auto-disposed: only kept alive while the search field is visible.

@ProviderFor(searchResults)
final searchResultsProvider = SearchResultsFamily._();

/// Searches profiles when query is >= 2 chars.
/// Auto-disposed: only kept alive while the search field is visible.

final class SearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Profile>>,
          List<Profile>,
          FutureOr<List<Profile>>
        >
    with $FutureModifier<List<Profile>>, $FutureProvider<List<Profile>> {
  /// Searches profiles when query is >= 2 chars.
  /// Auto-disposed: only kept alive while the search field is visible.
  SearchResultsProvider._({
    required SearchResultsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'searchResultsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @override
  String toString() {
    return r'searchResultsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Profile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Profile>> create(Ref ref) {
    final argument = this.argument as String;
    return searchResults(ref, query: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchResultsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchResultsHash() => r'c9085a44db6879832394e250419192a422ee00e5';

/// Searches profiles when query is >= 2 chars.
/// Auto-disposed: only kept alive while the search field is visible.

final class SearchResultsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Profile>>, String> {
  SearchResultsFamily._()
    : super(
        retry: null,
        name: r'searchResultsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Searches profiles when query is >= 2 chars.
  /// Auto-disposed: only kept alive while the search field is visible.

  SearchResultsProvider call({required String query}) =>
      SearchResultsProvider._(argument: query, from: this);

  @override
  String toString() => r'searchResultsProvider';
}

/// State: null → not yet synced, empty list → synced with no matches.
/// keepAlive so the results survive page navigation.

@ProviderFor(ContactMatches)
final contactMatchesProvider = ContactMatchesProvider._();

/// State: null → not yet synced, empty list → synced with no matches.
/// keepAlive so the results survive page navigation.
final class ContactMatchesProvider
    extends $AsyncNotifierProvider<ContactMatches, List<Profile>?> {
  /// State: null → not yet synced, empty list → synced with no matches.
  /// keepAlive so the results survive page navigation.
  ContactMatchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contactMatchesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contactMatchesHash();

  @$internal
  @override
  ContactMatches create() => ContactMatches();
}

String _$contactMatchesHash() => r'c06c6ee04ea76c31bb2a1be7462e0973df6955af';

/// State: null → not yet synced, empty list → synced with no matches.
/// keepAlive so the results survive page navigation.

abstract class _$ContactMatches extends $AsyncNotifier<List<Profile>?> {
  FutureOr<List<Profile>?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Profile>?>, List<Profile>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Profile>?>, List<Profile>?>,
              AsyncValue<List<Profile>?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// State: null → not yet discovered, empty list → no nearby users.
/// keepAlive so the results survive page navigation.

@ProviderFor(NearbyUsers)
final nearbyUsersProvider = NearbyUsersProvider._();

/// State: null → not yet discovered, empty list → no nearby users.
/// keepAlive so the results survive page navigation.
final class NearbyUsersProvider
    extends $AsyncNotifierProvider<NearbyUsers, List<Map<String, dynamic>>?> {
  /// State: null → not yet discovered, empty list → no nearby users.
  /// keepAlive so the results survive page navigation.
  NearbyUsersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyUsersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyUsersHash();

  @$internal
  @override
  NearbyUsers create() => NearbyUsers();
}

String _$nearbyUsersHash() => r'7574482372394bbf8a6eb80cebb7545f5b042dbe';

/// State: null → not yet discovered, empty list → no nearby users.
/// keepAlive so the results survive page navigation.

abstract class _$NearbyUsers
    extends $AsyncNotifier<List<Map<String, dynamic>>?> {
  FutureOr<List<Map<String, dynamic>>?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<Map<String, dynamic>>?>,
              List<Map<String, dynamic>>?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<Map<String, dynamic>>?>,
                List<Map<String, dynamic>>?
              >,
              AsyncValue<List<Map<String, dynamic>>?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Fetch friendship status for a specific user. Auto-disposed per tile.

@ProviderFor(friendshipStatus)
final friendshipStatusProvider = FriendshipStatusFamily._();

/// Fetch friendship status for a specific user. Auto-disposed per tile.

final class FriendshipStatusProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Fetch friendship status for a specific user. Auto-disposed per tile.
  FriendshipStatusProvider._({
    required FriendshipStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'friendshipStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$friendshipStatusHash();

  @override
  String toString() {
    return r'friendshipStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return friendshipStatus(ref, userId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FriendshipStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$friendshipStatusHash() => r'ad69fe1f3c9d59785531fffb5ed2124995d3d0b2';

/// Fetch friendship status for a specific user. Auto-disposed per tile.

final class FriendshipStatusFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  FriendshipStatusFamily._()
    : super(
        retry: null,
        name: r'friendshipStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetch friendship status for a specific user. Auto-disposed per tile.

  FriendshipStatusProvider call({required String userId}) =>
      FriendshipStatusProvider._(argument: userId, from: this);

  @override
  String toString() => r'friendshipStatusProvider';
}

/// Tracks user IDs with in-flight friend request sends.
/// keepAlive so concurrent navigations don't lose the set.

@ProviderFor(SendingRequests)
final sendingRequestsProvider = SendingRequestsProvider._();

/// Tracks user IDs with in-flight friend request sends.
/// keepAlive so concurrent navigations don't lose the set.
final class SendingRequestsProvider
    extends $NotifierProvider<SendingRequests, Set<String>> {
  /// Tracks user IDs with in-flight friend request sends.
  /// keepAlive so concurrent navigations don't lose the set.
  SendingRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendingRequestsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendingRequestsHash();

  @$internal
  @override
  SendingRequests create() => SendingRequests();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$sendingRequestsHash() => r'e66a603857dbb08f1de832207c29b3c3a390b4de';

/// Tracks user IDs with in-flight friend request sends.
/// keepAlive so concurrent navigations don't lose the set.

abstract class _$SendingRequests extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
