import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:moments/core/services/auth_service.dart';
import 'package:moments/core/services/avatar_cache_service.dart';
import 'package:moments/core/services/app_logger.dart';
import 'package:moments/core/services/ai_service.dart';
import 'package:moments/core/services/moment_storage_service.dart';
import 'package:moments/data/repositories/social_repository.dart';
import 'package:moments/data/repositories/notification_repository.dart';
import 'package:moments/data/models/profile.dart';
import 'package:moments/data/models/friendship.dart';
import 'package:moments/core/providers/realtime_providers.dart';
import 'package:moments/core/providers/database_provider.dart';
import 'package:moments/core/database/database.dart';
import 'package:moments/features/chat/providers/chat_providers.dart';

part 'providers.g.dart';

final _log = AppLogger('Providers');

// ============================================
// SINGLETON PROVIDERS - All with keepAlive
// ============================================

/// Auth service provider - singleton instance
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) => AuthService();

/// Social repository provider - singleton instance
@Riverpod(keepAlive: true)
SocialRepository socialRepository(Ref ref) => SocialRepository();

/// Notification repository provider - singleton instance
@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) =>
    NotificationRepository();

/// Avatar cache service provider - receives database via constructor injection
@Riverpod(keepAlive: true)
AvatarCacheService avatarCacheService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return AvatarCacheService(db);
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

/// Count of general notifications (system notifications only, excludes messages)
/// Friend requests and collab invites are counted separately in the RPC function
@riverpod
Stream<int> notificationCount(Ref ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  // RPC already counts: friend_request, moment_like, new_moment_group, etc.
  // It excludes 'message' type, so we just use it directly
  return repo.streamUnreadCount();
}

/// Provider for the list of notifications with pagination support
/// No auto-mark-as-read, user must interact with notifications to mark them read
@Riverpod(keepAlive: true)
class NotificationsList extends _$NotificationsList {
  static const int _pageSize = 30;
  int _currentOffset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    _log.d('build() called');
    _currentOffset = 0;
    _hasMore = true;
    final repo = ref.read(notificationRepositoryProvider);
    final notifications = await repo.getNotifications(
      limit: _pageSize,
      offset: 0,
    );
    _hasMore = notifications.length >= _pageSize;
    _currentOffset = notifications.length;
    return notifications;
  }

  /// Check if there are more notifications to load
  bool get hasMore => _hasMore;

  /// Check if currently loading more
  bool get isLoadingMore => _isLoadingMore;

  /// Load more notifications (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || !state.hasValue) return;

    _isLoadingMore = true;
    _log.d('Loading more notifications from offset $_currentOffset');

    try {
      final repo = ref.read(notificationRepositoryProvider);
      final moreNotifications = await repo.getNotifications(
        limit: _pageSize,
        offset: _currentOffset,
      );

      if (moreNotifications.isEmpty) {
        _hasMore = false;
      } else {
        _hasMore = moreNotifications.length >= _pageSize;
        _currentOffset += moreNotifications.length;

        // Append to existing list
        state = state.whenData((existing) {
          return [...existing, ...moreNotifications];
        });
      }
    } catch (e, stack) {
      _log.e('Error loading more notifications', error: e, stackTrace: stack);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    _currentOffset = 0;
    _hasMore = true;
    state = const AsyncValue.loading();
    final repo = ref.read(notificationRepositoryProvider);
    state = await AsyncValue.guard(() async {
      final notifications = await repo.getNotifications(
        limit: _pageSize,
        offset: 0,
      );
      _hasMore = notifications.length >= _pageSize;
      _currentOffset = notifications.length;
      return notifications;
    });
  }

  /// Remove a notification from the list (swipe to dismiss = delete)
  /// Also marks it as read before deleting
  Future<void> removeNotification(String notificationId) async {
    _log.d('removeNotification called for $notificationId');

    // Store original state for rollback
    final originalState = state.value;

    // Remove from local state immediately (optimistic)
    state = state.whenData((notifications) {
      final updated = notifications
          .where((n) => n['id'] != notificationId)
          .toList();
      _log.d('Optimistic update, remaining: ${updated.length}');
      return updated;
    });

    try {
      // Delete from DB
      final repo = ref.read(notificationRepositoryProvider);
      await repo.deleteNotification(notificationId);
      _log.d('DB delete completed for $notificationId');
      // Force badge count refresh
      ref.invalidate(notificationCountProvider);
    } catch (e, stack) {
      _log.e('Error deleting notification', error: e, stackTrace: stack);
      // Rollback on failure
      if (originalState != null) {
        state = AsyncValue.data(originalState);
      }
      rethrow;
    }
  }

  /// Mark a single notification as read (without removing from list)
  Future<void> markAsRead(String notificationId) async {
    // Store original for rollback
    final originalState = state.value;

    // Update local state immediately (optimistic)
    state = state.whenData((notifications) {
      return notifications.map((n) {
        if (n['id'] == notificationId) {
          return {...n, 'is_read': true};
        }
        return n;
      }).toList();
    });

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAsRead(notificationId);
      // Force badge count refresh
      ref.invalidate(notificationCountProvider);
    } catch (e, stack) {
      _log.e('Error marking notification as read', error: e, stackTrace: stack);
      // Rollback on failure
      if (originalState != null) {
        state = AsyncValue.data(originalState);
      }
    }
  }

  /// Mark all notifications as read (called on page open - Instagram style)
  /// With proper error handling to revert optimistic state on failure
  Future<void> markAllAsRead() async {
    final repo = ref.read(notificationRepositoryProvider);

    // Always mark all as read in DB, even if local state isn't loaded yet
    // This ensures the badge count updates via the realtime stream
    if (!state.hasValue) {
      try {
        await repo.markAllAsRead();
        _log.d('Marked all as read in DB (list not yet loaded)');
      } catch (e, stack) {
        _log.e('Error marking all as read', error: e, stackTrace: stack);
      }
      return;
    }

    final notifications = state.value!;
    final hasUnread = notifications.any((n) => n['is_read'] != true);
    if (!hasUnread) return;

    // Store original state for rollback
    final originalState = List<Map<String, dynamic>>.from(notifications);

    // Update local state immediately (optimistic)
    state = state.whenData((notifications) {
      return notifications.map((n) {
        return {...n, 'is_read': true};
      }).toList();
    });

    try {
      _log.d('Batch marking all as read');
      await repo.markAllAsRead();
      _log.d('Successfully marked all as read in DB');
      // Force badge count refresh so it drops to 0 immediately
      ref.invalidate(notificationCountProvider);
    } catch (e, stack) {
      _log.e(
        'Error marking all as read, reverting optimistic update',
        error: e,
        stackTrace: stack,
      );
      state = AsyncValue.data(originalState);
    }
  }
}

// ============================================
// FRIENDS & REQUESTS
// ============================================

/// List of current user's friends with offline support and realtime updates
@Riverpod(keepAlive: true)
Stream<List<Profile>> friendsList(Ref ref) async* {
  final socialRepo = ref.watch(socialRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);
  final avatarCache = ref.watch(avatarCacheServiceProvider);

  // 1. Load cached friends immediately from Drift
  final cachedEntries = await db.getProfiles();
  if (cachedEntries.isNotEmpty) {
    final cachedProfiles = cachedEntries.map((e) => e.toModel()).toList();
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
    await db.saveProfiles(friends.map((p) => p.toCompanion()).toList());

    // Update avatar cache
    for (final profile in friends) {
      if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
        avatarCache.updateCache(profile.id, profile.avatarUrl!);
      }
    }
    yield friends;
  } catch (e) {
    // If network fails and we have cache, we're good.
    if (cachedEntries.isEmpty) rethrow;
    _log.w('Network failed for friends list, using cache', error: e);
  }

  // 3. Subscribe to realtime updates on friendships table
  // When a friendship is added/removed/accepted, re-fetch the friends list
  await for (final _ in socialRepo.streamFriendshipChanges()) {
    try {
      final updatedFriends = await socialRepo.getFriendsProfiles();
      await db.saveProfiles(
        updatedFriends.map((p) => p.toCompanion()).toList(),
      );

      // Update avatar cache
      for (final profile in updatedFriends) {
        if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
          avatarCache.updateCache(profile.id, profile.avatarUrl!);
        }
      }
      yield updatedFriends;
    } catch (e) {
      // Ignore errors during stream updates to keep stream alive
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

/// Moment storage service provider - singleton for local media caching
@Riverpod(keepAlive: true)
MomentStorageService momentStorageService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return MomentStorageService(db);
}
