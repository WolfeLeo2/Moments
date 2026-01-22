import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/services/auth_service.dart';
import 'package:moments/core/services/avatar_cache_service.dart';
import 'package:moments/data/repositories/social_repository.dart';
import 'package:moments/data/repositories/notification_repository.dart';
import 'package:moments/data/models/profile.dart';
import 'package:moments/data/models/friendship.dart';
import 'package:moments/core/providers/moments_providers.dart';
import 'package:moments/core/providers/realtime_providers.dart';
import 'package:moments/features/chat/providers/chat_providers.dart';

part 'providers.g.dart';

// ============================================
// SINGLETON PROVIDERS
// ============================================

/// Auth service provider - always same instance
@riverpod
AuthService authService(Ref ref) => AuthService();

/// Social repository provider - always same instance
@riverpod
SocialRepository socialRepository(Ref ref) => SocialRepository();

/// Notification repository provider
@riverpod
NotificationRepository notificationRepository(Ref ref) =>
    NotificationRepository();

// ============================================
// AUTH STATE
// ============================================

/// Current authenticated user
@riverpod
Stream<dynamic> currentUser(Ref ref) {
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
// NOTIFICATION COUNTS
// ============================================

/// Count of pending friend requests
@riverpod
Stream<int> friendRequestCount(Ref ref) async* {
  final requestsAsync = ref.watch(pendingRequestsRealtimeProvider);
  yield requestsAsync.value?.length ?? 0;
}

/// Count of unread chats
@riverpod
Stream<int> unreadChatCount(Ref ref) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.streamUnreadCount();
}

/// Count of general notifications (system notifications only, excludes messages)
/// Friend requests and collab invites are counted separately in the RPC function
@riverpod
Stream<int> notificationCount(Ref ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  // RPC already counts: friend_request, moment_like, new_moment_group, etc.
  // It excludes 'message' type, so we just use it directly
  return repo.streamUnreadCount();
}

/// Provider for the list of notifications - simple fetch without realtime
/// No auto-mark-as-read, user must interact with notifications to mark them read
@Riverpod(keepAlive: true)
class NotificationsList extends _$NotificationsList {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    debugPrint('NotificationsList: build() called');
    final repo = ref.read(notificationRepositoryProvider);
    return repo.getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final repo = ref.read(notificationRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getNotifications());
  }

  /// Remove a notification from the list and mark as read in DB
  /// This is called when user swipes to dismiss
  /// Remove a notification from the list (swipe to dismiss = delete)
  Future<void> removeNotification(String notificationId) async {
    debugPrint(
      'NotificationsList: removeNotification called for $notificationId',
    );

    // Remove from local state immediately (optimistic)
    state = state.whenData((notifications) {
      final updated = notifications
          .where((n) => n['id'] != notificationId)
          .toList();
      debugPrint(
        'NotificationsList: Optimistic update, remaining: ${updated.length}',
      );
      return updated;
    });

    try {
      // Delete from DB (in background)
      final repo = ref.read(notificationRepositoryProvider);
      await repo.deleteNotification(notificationId);
      debugPrint('NotificationsList: DB delete requested for $notificationId');
    } catch (e) {
      debugPrint('NotificationsList: Error deleting notification: $e');
    }
  }

  /// Mark a single notification as read (without removing from list)
  Future<void> markAsRead(String notificationId) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(notificationId);

    // Update local state immediately (optimistic)
    state = state.whenData((notifications) {
      return notifications.map((n) {
        if (n['id'] == notificationId) {
          return {...n, 'is_read': true};
        }
        return n;
      }).toList();
    });
  }

  /// Mark all notifications as read (called on page open - Instagram style)
  Future<void> markAllAsRead() async {
    final repo = ref.read(notificationRepositoryProvider);

    // Get all unread notification IDs from current state
    if (!state.hasValue) return;
    final notifications = state.value!;

    final hasUnread = notifications.any((n) => n['is_read'] != true);
    if (!hasUnread) return;

    // Update local state immediately (optimistic)
    state = state.whenData((notifications) {
      return notifications.map((n) {
        return {...n, 'is_read': true};
      }).toList();
    });

    // Mark all as read in DB using batch update
    debugPrint('NotificationsList: Batch marking all as read');
    await repo.markAllAsRead();
  }
}

// ============================================
// FRIENDS & REQUESTS
// ============================================

/// List of current user's friends with offline support and realtime updates
final friendsListProvider = StreamProvider<List<Profile>>((ref) async* {
  final socialRepo = ref.watch(socialRepositoryProvider);
  final storage = ref.watch(momentStorageProvider);
  final avatarCache = AvatarCacheService();

  // 1. Load cached friends immediately
  final cachedProfiles = await storage.getProfiles();
  if (cachedProfiles.isNotEmpty) {
    // Populate avatar cache from stored profiles
    for (final profile in cachedProfiles) {
      if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
        avatarCache.updateCache(profile.id, profile.avatarUrl!);
      }
    }
    yield cachedProfiles;
  }

  // 2. Fetch fresh data initially
  try {
    final friends = await socialRepo.getFriendsProfiles();
    await storage.saveProfiles(friends);

    // Update avatar cache
    for (final profile in friends) {
      if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
        avatarCache.updateCache(profile.id, profile.avatarUrl!);
      }
    }
    yield friends;
  } catch (e) {
    // If network fails and we have cache, we're good.
    if (cachedProfiles.isEmpty) rethrow;
  }

  // 3. Subscribe to realtime updates on friendships table
  // When a friendship is added/removed/accepted, re-fetch the friends list
  await for (final _ in socialRepo.streamFriendshipChanges()) {
    try {
      final updatedFriends = await socialRepo.getFriendsProfiles();
      await storage.saveProfiles(updatedFriends);

      // Update avatar cache
      for (final profile in updatedFriends) {
        if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
          avatarCache.updateCache(profile.id, profile.avatarUrl!);
        }
      }
      yield updatedFriends;
    } catch (e) {
      // Ignore errors during stream updates to keep stream alive
      debugPrint('Error updating friends list from stream: $e');
    }
  }
});

/// Pending friend requests
@riverpod
Future<List<Friendship>> pendingRequests(Ref ref) async {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getPendingRequests();
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
