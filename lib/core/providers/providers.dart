import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moments/core/services/auth_service.dart';
import 'package:moments/core/services/avatar_cache_service.dart';
import 'dart:async';

import 'package:moments/core/services/app_logger.dart';
import 'package:moments/core/services/ai_service.dart';
import 'package:moments/core/providers/powersync_provider.dart';
import 'package:moments/data/repositories/social_repository.dart';
import 'package:moments/data/repositories/notification_repository.dart';
import 'package:moments/data/models/profile.dart';
import 'package:moments/data/models/friendship.dart';
import 'package:moments/core/providers/realtime_providers.dart';
import 'package:moments/core/providers/database_provider.dart';
import 'package:moments/features/chat/providers/chat_providers.dart';

part 'providers.g.dart';

final _log = AppLogger('Providers');

// ============================================
// SINGLETON PROVIDERS - All with keepAlive
// ============================================

/// Auth service provider - singleton instance
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
}

/// Social repository provider - singleton instance
@Riverpod(keepAlive: true)
SocialRepository socialRepository(Ref ref) => SocialRepository();

/// Notification repository provider — PS-backed reads + writes.
@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  final ps = ref.watch(chatPowerSyncServiceProvider);
  return NotificationRepository(client, ps);
}

/// Avatar cache service provider.
@Riverpod(keepAlive: true)
AvatarCacheService avatarCacheService(Ref ref) {
  return AvatarCacheService();
}

/// AI service provider - singleton, uses Firebase AI (Gemini Developer API free tier)
@Riverpod(keepAlive: true)
AIService aiService(Ref ref) {
  final service = AIService();
  service.initialize();
  return service;
}

// ============================================
// AUTH STATE
// ============================================

/// Current authenticated user
@riverpod
Stream<User?> currentUser(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((state) => state.session?.user);
}

/// Current user's profile with auto-refresh
@riverpod
Future<Profile?> currentUserProfile(Ref ref) async {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getCurrentUserProfile();
}

// ============================================
// NOTIFICATION COUNTS - Fixed reactive patterns
// ============================================

/// Count of pending friend requests - properly reactive
@riverpod
int friendRequestCount(Ref ref) {
  final requestsAsync = ref.watch(pendingRequestsRealtimeProvider);
  return requestsAsync.value?.length ?? 0;
}

/// Count of unread chats
@riverpod
Stream<int> unreadChatCount(Ref ref) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.streamUnreadCount();
}

/// Count of unread notifications — live local SQL query via PowerSync.
@riverpod
Stream<int> notificationCount(Ref ref) {
  return ref.watch(notificationRepositoryProvider).watchUnreadCount();
}

/// Live list of notifications — PowerSync-backed stream.
/// Resolves C10 (mutable offset fields) and H17/H18/H21 (offset pagination,
/// non-realtime list, racing markAllAsRead timer).
@Riverpod(keepAlive: true)
class NotificationsList extends _$NotificationsList {
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = ref.watch(notificationRepositoryProvider);

    _sub?.cancel();
    ref.onDispose(() => _sub?.cancel());

    // Single subscription: resolves the initial Future AND keeps state live.
    final first = Completer<List<Map<String, dynamic>>>();
    _sub = repo.watchNotifications().listen(
      (rows) {
        if (!first.isCompleted) first.complete(rows);
        state = AsyncData(rows);
      },
      onError: (Object e, StackTrace s) {
        if (!first.isCompleted) first.completeError(e, s);
        state = AsyncError(e, s);
      },
    );
    return first.future;
  }

  Future<void> markAsRead(String id) =>
      ref.read(notificationRepositoryProvider).markAsRead(id);

  Future<void> markAllAsRead() =>
      ref.read(notificationRepositoryProvider).markAllAsRead();

  /// PS DELETE is the source of truth — stream re-emits without the row.
  Future<void> removeNotification(String id) =>
      ref.read(notificationRepositoryProvider).deleteNotification(id);
}

// ============================================
// FRIENDS & REQUESTS
// ============================================

/// List of current user's friends with offline support and realtime updates
@Riverpod(keepAlive: true)
Stream<List<Profile>> friendsList(Ref ref) async* {
  final socialRepo = ref.watch(socialRepositoryProvider);
  final avatarCache = ref.watch(avatarCacheServiceProvider);

  void seedAvatars(List<Profile> profiles) {
    for (final profile in profiles) {
      if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
        avatarCache.updateCache(profile.id, profile.avatarUrl!);
      }
    }
  }

  // 1. Fetch current friends. (PowerSync-backed once friendships/profiles sync.)
  final friends = await socialRepo.getFriendsProfiles();
  seedAvatars(friends);
  yield friends;

  // 2. Subscribe to realtime updates on friendships.
  await for (final _ in socialRepo.streamFriendshipChanges()) {
    try {
      final updatedFriends = await socialRepo.getFriendsProfiles();
      seedAvatars(updatedFriends);
      yield updatedFriends;
    } catch (e) {
      _log.w('Error updating friends list from stream', error: e);
    }
  }
}

/// Pending friend requests
@riverpod
Future<List<Friendship>> pendingRequests(Ref ref) async {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getPendingRequests();
}

/// Sent friend requests (outgoing, awaiting response)
@riverpod
Future<List<Friendship>> sentRequests(Ref ref) async {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getSentRequests();
}

/// Get a friend's profile by ID - cached per user to prevent API spam
@riverpod
Future<Profile?> friendProfile(Ref ref, String friendId) async {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getProfileById(friendId);
}

/// Get mutual friends count between current user and a friend
@riverpod
Future<int> mutualFriendsCount(Ref ref, String friendId) async {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getMutualFriendsCount(friendId);
}

/// Get public moments count for a user
@riverpod
Future<int> userMomentsCount(Ref ref, String userId) async {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getUserMomentsCount(userId);
}

// ============================================
// NOTIFIER CLASSES FOR STATE MUTATIONS
// ============================================

/// Notifier for adding a friend
@riverpod
class AddFriend extends _$AddFriend {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> sendFriendRequest(String inviteCode) async {
    state = const AsyncValue.loading();
    final socialRepo = ref.read(socialRepositoryProvider);
    state = await AsyncValue.guard(
      () => socialRepo.sendFriendRequest(inviteCode),
    );
  }
}

// ============================================
// FRIEND REQUEST ACTIONS
// ============================================

@riverpod
class FriendRequest extends _$FriendRequest {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> acceptRequest(String friendshipId) async {
    state = const AsyncValue.loading();
    final socialRepo = ref.read(socialRepositoryProvider);
    try {
      await socialRepo.acceptFriendRequest(friendshipId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> rejectRequest(String friendshipId) async {
    state = const AsyncValue.loading();
    final socialRepo = ref.read(socialRepositoryProvider);
    state = await AsyncValue.guard(
      () => socialRepo.rejectFriendRequest(friendshipId),
    );
  }
}

// ============================================
// CACHE INVALIDATION HELPERS
// ============================================

/// Invalidate all friends-related caches
void invalidateFriendsCache(WidgetRef ref) {
  ref.invalidate(friendsListProvider);
  ref.invalidate(pendingRequestsProvider);
}

/// Invalidate profile cache
void invalidateProfileCache(WidgetRef ref) {
  ref.invalidate(currentUserProfileProvider);
}

// ============================================
// STORAGE SERVICES
// ============================================

