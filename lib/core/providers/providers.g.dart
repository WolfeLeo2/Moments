// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auth service provider - singleton instance

@ProviderFor(authService)
const authServiceProvider = AuthServiceProvider._();

/// Auth service provider - singleton instance

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  /// Auth service provider - singleton instance
  const AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: false,
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

String _$authServiceHash() => r'c9861524ac694442ddb96da59d519ffb215bef26';

/// Social repository provider - singleton instance

@ProviderFor(socialRepository)
const socialRepositoryProvider = SocialRepositoryProvider._();

/// Social repository provider - singleton instance

final class SocialRepositoryProvider
    extends
        $FunctionalProvider<
          SocialRepository,
          SocialRepository,
          SocialRepository
        >
    with $Provider<SocialRepository> {
  /// Social repository provider - singleton instance
  const SocialRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialRepositoryProvider',
        isAutoDispose: false,
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

String _$socialRepositoryHash() => r'341a546c4f2747422d7da38ba7fabafae4d5e8b4';

/// Notification repository provider - singleton instance

@ProviderFor(notificationRepository)
const notificationRepositoryProvider = NotificationRepositoryProvider._();

/// Notification repository provider - singleton instance

final class NotificationRepositoryProvider
    extends
        $FunctionalProvider<
          NotificationRepository,
          NotificationRepository,
          NotificationRepository
        >
    with $Provider<NotificationRepository> {
  /// Notification repository provider - singleton instance
  const NotificationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationRepository create(Ref ref) {
    return notificationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationRepository>(value),
    );
  }
}

String _$notificationRepositoryHash() =>
    r'a5591d0da77c528cb80738b61fb2eda7ad0faeca';

/// Avatar cache service provider - receives database via constructor injection

@ProviderFor(avatarCacheService)
const avatarCacheServiceProvider = AvatarCacheServiceProvider._();

/// Avatar cache service provider - receives database via constructor injection

final class AvatarCacheServiceProvider
    extends
        $FunctionalProvider<
          AvatarCacheService,
          AvatarCacheService,
          AvatarCacheService
        >
    with $Provider<AvatarCacheService> {
  /// Avatar cache service provider - receives database via constructor injection
  const AvatarCacheServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'avatarCacheServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$avatarCacheServiceHash();

  @$internal
  @override
  $ProviderElement<AvatarCacheService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AvatarCacheService create(Ref ref) {
    return avatarCacheService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AvatarCacheService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AvatarCacheService>(value),
    );
  }
}

String _$avatarCacheServiceHash() =>
    r'3034cda50bc866bf5ba9a9d2d573c738c4868aff';

/// AI service provider - singleton, uses Firebase AI (Gemini Developer API free tier)

@ProviderFor(aiService)
const aiServiceProvider = AiServiceProvider._();

/// AI service provider - singleton, uses Firebase AI (Gemini Developer API free tier)

final class AiServiceProvider
    extends $FunctionalProvider<AIService, AIService, AIService>
    with $Provider<AIService> {
  /// AI service provider - singleton, uses Firebase AI (Gemini Developer API free tier)
  const AiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiServiceHash();

  @$internal
  @override
  $ProviderElement<AIService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AIService create(Ref ref) {
    return aiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AIService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AIService>(value),
    );
  }
}

String _$aiServiceHash() => r'f3676f4c3d527135c19190275905b7fddc88471a';

/// Current authenticated user — typed as User? for safety

@ProviderFor(currentUser)
const currentUserProvider = CurrentUserProvider._();

/// Current authenticated user — typed as User? for safety

final class CurrentUserProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  /// Current authenticated user — typed as User? for safety
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
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return currentUser(ref);
  }
}

String _$currentUserHash() => r'df184e2b2b619a7eea7caa5c646ae48e7709707d';

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

/// Count of pending friend requests - properly reactive

@ProviderFor(friendRequestCount)
const friendRequestCountProvider = FriendRequestCountProvider._();

/// Count of pending friend requests - properly reactive

final class FriendRequestCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Count of pending friend requests - properly reactive
  const FriendRequestCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendRequestCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendRequestCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return friendRequestCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$friendRequestCountHash() =>
    r'9039a29370145edd2725b808bc55338311d75fa0';

/// Count of unread chats

@ProviderFor(unreadChatCount)
const unreadChatCountProvider = UnreadChatCountProvider._();

/// Count of unread chats

final class UnreadChatCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Count of unread chats
  const UnreadChatCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadChatCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadChatCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return unreadChatCount(ref);
  }
}

String _$unreadChatCountHash() => r'67146228e2019f36bfb2122f845bf432256e8dd9';

/// Count of general notifications (system notifications only, excludes messages)
/// Friend requests and collab invites are counted separately in the RPC function

@ProviderFor(notificationCount)
const notificationCountProvider = NotificationCountProvider._();

/// Count of general notifications (system notifications only, excludes messages)
/// Friend requests and collab invites are counted separately in the RPC function

final class NotificationCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Count of general notifications (system notifications only, excludes messages)
  /// Friend requests and collab invites are counted separately in the RPC function
  const NotificationCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return notificationCount(ref);
  }
}

String _$notificationCountHash() => r'add8309690ec3cea931f5dc403ef75f0a98a09c8';

/// Provider for the list of notifications with pagination support
/// No auto-mark-as-read, user must interact with notifications to mark them read

@ProviderFor(NotificationsList)
const notificationsListProvider = NotificationsListProvider._();

/// Provider for the list of notifications with pagination support
/// No auto-mark-as-read, user must interact with notifications to mark them read
final class NotificationsListProvider
    extends
        $AsyncNotifierProvider<NotificationsList, List<Map<String, dynamic>>> {
  /// Provider for the list of notifications with pagination support
  /// No auto-mark-as-read, user must interact with notifications to mark them read
  const NotificationsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsListHash();

  @$internal
  @override
  NotificationsList create() => NotificationsList();
}

String _$notificationsListHash() => r'a34a22475fe479e3bb793a8ad668c7fce782eac5';

/// Provider for the list of notifications with pagination support
/// No auto-mark-as-read, user must interact with notifications to mark them read

abstract class _$NotificationsList
    extends $AsyncNotifier<List<Map<String, dynamic>>> {
  FutureOr<List<Map<String, dynamic>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<Map<String, dynamic>>>,
              List<Map<String, dynamic>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<Map<String, dynamic>>>,
                List<Map<String, dynamic>>
              >,
              AsyncValue<List<Map<String, dynamic>>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// List of current user's friends with offline support and realtime updates

@ProviderFor(friendsList)
const friendsListProvider = FriendsListProvider._();

/// List of current user's friends with offline support and realtime updates

final class FriendsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Profile>>,
          List<Profile>,
          Stream<List<Profile>>
        >
    with $FutureModifier<List<Profile>>, $StreamProvider<List<Profile>> {
  /// List of current user's friends with offline support and realtime updates
  const FriendsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'friendsListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$friendsListHash();

  @$internal
  @override
  $StreamProviderElement<List<Profile>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Profile>> create(Ref ref) {
    return friendsList(ref);
  }
}

String _$friendsListHash() => r'9747e35a1ffaecb03d47792f707d6166b1a40115';

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

/// Sent friend requests (outgoing, awaiting response)

@ProviderFor(sentRequests)
const sentRequestsProvider = SentRequestsProvider._();

/// Sent friend requests (outgoing, awaiting response)

final class SentRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Friendship>>,
          List<Friendship>,
          FutureOr<List<Friendship>>
        >
    with $FutureModifier<List<Friendship>>, $FutureProvider<List<Friendship>> {
  /// Sent friend requests (outgoing, awaiting response)
  const SentRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sentRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sentRequestsHash();

  @$internal
  @override
  $FutureProviderElement<List<Friendship>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Friendship>> create(Ref ref) {
    return sentRequests(ref);
  }
}

String _$sentRequestsHash() => r'069ed7f328a03ba18d520a5104967da620bea387';

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

/// Get mutual friends count between current user and a friend

@ProviderFor(mutualFriendsCount)
const mutualFriendsCountProvider = MutualFriendsCountFamily._();

/// Get mutual friends count between current user and a friend

final class MutualFriendsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Get mutual friends count between current user and a friend
  const MutualFriendsCountProvider._({
    required MutualFriendsCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mutualFriendsCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mutualFriendsCountHash();

  @override
  String toString() {
    return r'mutualFriendsCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return mutualFriendsCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MutualFriendsCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mutualFriendsCountHash() =>
    r'eee86c80b0cc4e1289e42277504d5df58bb4cf83';

/// Get mutual friends count between current user and a friend

final class MutualFriendsCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  const MutualFriendsCountFamily._()
    : super(
        retry: null,
        name: r'mutualFriendsCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get mutual friends count between current user and a friend

  MutualFriendsCountProvider call(String friendId) =>
      MutualFriendsCountProvider._(argument: friendId, from: this);

  @override
  String toString() => r'mutualFriendsCountProvider';
}

/// Get public moments count for a user

@ProviderFor(userMomentsCount)
const userMomentsCountProvider = UserMomentsCountFamily._();

/// Get public moments count for a user

final class UserMomentsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Get public moments count for a user
  const UserMomentsCountProvider._({
    required UserMomentsCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userMomentsCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userMomentsCountHash();

  @override
  String toString() {
    return r'userMomentsCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return userMomentsCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserMomentsCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userMomentsCountHash() => r'794cb29ffd9e317bdff0a221f4ae31aa258de540';

/// Get public moments count for a user

final class UserMomentsCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  const UserMomentsCountFamily._()
    : super(
        retry: null,
        name: r'userMomentsCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get public moments count for a user

  UserMomentsCountProvider call(String userId) =>
      UserMomentsCountProvider._(argument: userId, from: this);

  @override
  String toString() => r'userMomentsCountProvider';
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

/// Moment storage service provider - singleton for local media caching

@ProviderFor(momentStorageService)
const momentStorageServiceProvider = MomentStorageServiceProvider._();

/// Moment storage service provider - singleton for local media caching

final class MomentStorageServiceProvider
    extends
        $FunctionalProvider<
          MomentStorageService,
          MomentStorageService,
          MomentStorageService
        >
    with $Provider<MomentStorageService> {
  /// Moment storage service provider - singleton for local media caching
  const MomentStorageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'momentStorageServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$momentStorageServiceHash();

  @$internal
  @override
  $ProviderElement<MomentStorageService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MomentStorageService create(Ref ref) {
    return momentStorageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MomentStorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MomentStorageService>(value),
    );
  }
}

String _$momentStorageServiceHash() =>
    r'd1d57948a08e6caa59e4ce88cfdd25e948ea24cc';

/// Tracks which notification IDs have been dismissed (swiped away) in the
/// current session. Using a keepAlive provider so dismissals survive page
/// pops and re-pushes — unlike a Set on widget State.

@ProviderFor(DismissedNotificationIds)
const dismissedNotificationIdsProvider = DismissedNotificationIdsProvider._();

/// Tracks which notification IDs have been dismissed (swiped away) in the
/// current session. Using a keepAlive provider so dismissals survive page
/// pops and re-pushes — unlike a Set on widget State.
final class DismissedNotificationIdsProvider
    extends $NotifierProvider<DismissedNotificationIds, Set<String>> {
  /// Tracks which notification IDs have been dismissed (swiped away) in the
  /// current session. Using a keepAlive provider so dismissals survive page
  /// pops and re-pushes — unlike a Set on widget State.
  const DismissedNotificationIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dismissedNotificationIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dismissedNotificationIdsHash();

  @$internal
  @override
  DismissedNotificationIds create() => DismissedNotificationIds();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$dismissedNotificationIdsHash() =>
    r'd1257b1a748b9bbec1be1564dc4e64e19a1c0274';

/// Tracks which notification IDs have been dismissed (swiped away) in the
/// current session. Using a keepAlive provider so dismissals survive page
/// pops and re-pushes — unlike a Set on widget State.

abstract class _$DismissedNotificationIds extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
