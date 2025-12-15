// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auth service provider - always same instance

@ProviderFor(authService)
const authServiceProvider = AuthServiceProvider._();

/// Auth service provider - always same instance

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  /// Auth service provider - always same instance
  const AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<AuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthService>(value),
    );
  }
}

String _$authServiceHash() => r'ed0872794ec8e4cb3f50cb37b9c0b9467eb51ddb';

/// Social repository provider - always same instance

@ProviderFor(socialRepository)
const socialRepositoryProvider = SocialRepositoryProvider._();

/// Social repository provider - always same instance

final class SocialRepositoryProvider
    extends
        $FunctionalProvider<
          SocialRepository,
          SocialRepository,
          SocialRepository
        >
    with $Provider<SocialRepository> {
  /// Social repository provider - always same instance
  const SocialRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socialRepositoryHash();

  @$internal
  @override
  $ProviderElement<SocialRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SocialRepository create(Ref ref) {
    return socialRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SocialRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SocialRepository>(value),
    );
  }
}

String _$socialRepositoryHash() => r'65582ff92e381f034f4ac9892315123d4eb621e3';

/// Current authenticated user

@ProviderFor(currentUser)
const currentUserProvider = CurrentUserProvider._();

/// Current authenticated user

final class CurrentUserProvider
    extends $FunctionalProvider<AsyncValue<dynamic>, dynamic, Stream<dynamic>>
    with $FutureModifier<dynamic>, $StreamProvider<dynamic> {
  /// Current authenticated user
  const CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $StreamProviderElement<dynamic> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<dynamic> create(Ref ref) {
    return currentUser(ref);
  }
}

String _$currentUserHash() => r'901f17b44ebfcc072cefe9729ae92fa4703cb895';

/// Current user's profile with auto-refresh

@ProviderFor(currentUserProfile)
const currentUserProfileProvider = CurrentUserProfileProvider._();

/// Current user's profile with auto-refresh

final class CurrentUserProfileProvider
    extends
        $FunctionalProvider<AsyncValue<Profile?>, Profile?, FutureOr<Profile?>>
    with $FutureModifier<Profile?>, $FutureProvider<Profile?> {
  /// Current user's profile with auto-refresh
  const CurrentUserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserProfileHash();

  @$internal
  @override
  $FutureProviderElement<Profile?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Profile?> create(Ref ref) {
    return currentUserProfile(ref);
  }
}

String _$currentUserProfileHash() =>
    r'fd95b4c2e4e9c6f2e8c123ebd71e6a7ae0f65ae9';

/// Pending friend requests

@ProviderFor(pendingRequests)
const pendingRequestsProvider = PendingRequestsProvider._();

/// Pending friend requests

final class PendingRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Friendship>>,
          List<Friendship>,
          FutureOr<List<Friendship>>
        >
    with $FutureModifier<List<Friendship>>, $FutureProvider<List<Friendship>> {
  /// Pending friend requests
  const PendingRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingRequestsHash();

  @$internal
  @override
  $FutureProviderElement<List<Friendship>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Friendship>> create(Ref ref) {
    return pendingRequests(ref);
  }
}

String _$pendingRequestsHash() => r'37d33371cb6118f599f3c7591cdc90bc39781618';

/// Get a friend's profile by ID - cached per user to prevent API spam

@ProviderFor(friendProfile)
const friendProfileProvider = FriendProfileFamily._();

/// Get a friend's profile by ID - cached per user to prevent API spam

final class FriendProfileProvider
    extends
        $FunctionalProvider<AsyncValue<Profile?>, Profile?, FutureOr<Profile?>>
    with $FutureModifier<Profile?>, $FutureProvider<Profile?> {
  /// Get a friend's profile by ID - cached per user to prevent API spam
  const FriendProfileProvider._({
    required FriendProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'friendProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$friendProfileHash();

  @override
  String toString() {
    return r'friendProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Profile?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Profile?> create(Ref ref) {
    final argument = this.argument as String;
    return friendProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FriendProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$friendProfileHash() => r'9d35c9d4d087d32981ce2a42412911d1795b6d52';

/// Get a friend's profile by ID - cached per user to prevent API spam

final class FriendProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Profile?>, String> {
  const FriendProfileFamily._()
    : super(
        retry: null,
        name: r'friendProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get a friend's profile by ID - cached per user to prevent API spam

  FriendProfileProvider call(String friendId) =>
      FriendProfileProvider._(argument: friendId, from: this);

  @override
  String toString() => r'friendProfileProvider';
}

/// Notifier for adding a friend

@ProviderFor(AddFriend)
const addFriendProvider = AddFriendProvider._();

/// Notifier for adding a friend
final class AddFriendProvider
    extends $NotifierProvider<AddFriend, AsyncValue<void>> {
  /// Notifier for adding a friend
  const AddFriendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addFriendProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addFriendHash();

  @$internal
  @override
  AddFriend create() => AddFriend();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$addFriendHash() => r'fc1dad1a9d2b704386430366e3908ab39b9d1793';

/// Notifier for adding a friend

abstract class _$AddFriend extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(FriendRequest)
const friendRequestProvider = FriendRequestProvider._();

final class FriendRequestProvider
    extends $NotifierProvider<FriendRequest, AsyncValue<void>> {
  const FriendRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendRequestProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendRequestHash();

  @$internal
  @override
  FriendRequest create() => FriendRequest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$friendRequestHash() => r'f00f2f8493b88638afe24d1659d3384ec109934a';

abstract class _$FriendRequest extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
