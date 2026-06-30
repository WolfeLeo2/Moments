// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auth service provider - singleton instance

@ProviderFor(authService)
final authServiceProvider = AuthServiceProvider._();

/// Auth service provider - singleton instance

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  /// Auth service provider - singleton instance
  AuthServiceProvider._()
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
final socialRepositoryProvider = SocialRepositoryProvider._();

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
  SocialRepositoryProvider._()
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

String _$socialRepositoryHash() => r'b2c2010c6c889d26108ea3bd041109f17162110b';

/// Notification repository provider - singleton instance

@ProviderFor(notificationRepository)
final notificationRepositoryProvider = NotificationRepositoryProvider._();

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
  NotificationRepositoryProvider._()
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

/// Avatar cache service provider.

@ProviderFor(avatarCacheService)
final avatarCacheServiceProvider = AvatarCacheServiceProvider._();

/// Avatar cache service provider.

final class AvatarCacheServiceProvider
    extends
        $FunctionalProvider<
          AvatarCacheService,
          AvatarCacheService,
          AvatarCacheService
        >
    with $Provider<AvatarCacheService> {
  /// Avatar cache service provider.
  AvatarCacheServiceProvider._()
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
    r'386c558f190c24f15d755f054d0fc383d7ad8636';

/// AI service provider - singleton, uses Firebase AI (Gemini Developer API free tier)

@ProviderFor(aiService)
final aiServiceProvider = AiServiceProvider._();

/// AI service provider - singleton, uses Firebase AI (Gemini Developer API free tier)

final class AiServiceProvider
    extends $FunctionalProvider<AIService, AIService, AIService>
    with $Provider<AIService> {
  /// AI service provider - singleton, uses Firebase AI (Gemini Developer API free tier)
  AiServiceProvider._()
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

/// Current authenticated user

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// Current authenticated user

final class CurrentUserProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  /// Current authenticated user
  CurrentUserProvider._()
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
final currentUserProfileProvider = CurrentUserProfileProvider._();

/// Current user's profile with auto-refresh

final class CurrentUserProfileProvider
    extends
        $FunctionalProvider<AsyncValue<Profile?>, Profile?, FutureOr<Profile?>>
    with $FutureModifier<Profile?>, $FutureProvider<Profile?> {
  /// Current user's profile with auto-refresh
  CurrentUserProfileProvider._()
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
final friendRequestCountProvider = FriendRequestCountProvider._();

/// Count of pending friend requests - properly reactive

final class FriendRequestCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Count of pending friend requests - properly reactive
  FriendRequestCountProvider._()
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
final unreadChatCountProvider = UnreadChatCountProvider._();

/// Count of unread chats

final class UnreadChatCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Count of unread chats
  UnreadChatCountProvider._()
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
final notificationCountProvider = NotificationCountProvider._();

/// Count of general notifications (system notifications only, excludes messages)
/// Friend requests and collab invites are counted separately in the RPC function

final class NotificationCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Count of general notifications (system notifications only, excludes messages)
  /// Friend requests and collab invites are counted separately in the RPC function
  NotificationCountProvider._()
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
final notificationsListProvider = NotificationsListProvider._();

/// Provider for the list of notifications with pagination support
/// No auto-mark-as-read, user must interact with notifications to mark them read
final class NotificationsListProvider
    extends
        $AsyncNotifierProvider<NotificationsList, List<Map<String, dynamic>>> {
  /// Provider for the list of notifications with pagination support
  /// No auto-mark-as-read, user must interact with notifications to mark them read
  NotificationsListProvider._()
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

String _$notificationsListHash() => r'f83251bcce82ac7827e3b9f94c87d9e32f198d83';

/// Provider for the list of notifications with pagination support
/// No auto-mark-as-read, user must interact with notifications to mark them read

abstract class _$NotificationsList
    extends $AsyncNotifier<List<Map<String, dynamic>>> {
  FutureOr<List<Map<String, dynamic>>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}

/// List of current user's friends with offline support and realtime updates

@ProviderFor(friendsList)
final friendsListProvider = FriendsListProvider._();

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
  FriendsListProvider._()
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

String _$friendsListHash() => r'0e55591f53c3768c6c7ddbb2bc676c559f809105';

/// Pending friend requests

@ProviderFor(pendingRequests)
final pendingRequestsProvider = PendingRequestsProvider._();

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
  PendingRequestsProvider._()
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
final sentRequestsProvider = SentRequestsProvider._();

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
  SentRequestsProvider._()
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
final friendProfileProvider = FriendProfileFamily._();

/// Get a friend's profile by ID - cached per user to prevent API spam

final class FriendProfileProvider
    extends
        $FunctionalProvider<AsyncValue<Profile?>, Profile?, FutureOr<Profile?>>
    with $FutureModifier<Profile?>, $FutureProvider<Profile?> {
  /// Get a friend's profile by ID - cached per user to prevent API spam
  FriendProfileProvider._({
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
  FriendProfileFamily._()
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
final mutualFriendsCountProvider = MutualFriendsCountFamily._();

/// Get mutual friends count between current user and a friend

final class MutualFriendsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Get mutual friends count between current user and a friend
  MutualFriendsCountProvider._({
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
  MutualFriendsCountFamily._()
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
final userMomentsCountProvider = UserMomentsCountFamily._();

/// Get public moments count for a user

final class UserMomentsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Get public moments count for a user
  UserMomentsCountProvider._({
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
  UserMomentsCountFamily._()
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
final addFriendProvider = AddFriendProvider._();

/// Notifier for adding a friend
final class AddFriendProvider
    extends $NotifierProvider<AddFriend, AsyncValue<void>> {
  /// Notifier for adding a friend
  AddFriendProvider._()
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
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(FriendRequest)
final friendRequestProvider = FriendRequestProvider._();

final class FriendRequestProvider
    extends $NotifierProvider<FriendRequest, AsyncValue<void>> {
  FriendRequestProvider._()
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
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
