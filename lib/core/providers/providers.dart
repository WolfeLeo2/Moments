import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/services/auth_service.dart';
import 'package:moments/core/services/avatar_cache_service.dart';
import 'package:moments/data/repositories/social_repository.dart';
import 'package:moments/data/models/profile.dart';
import 'package:moments/data/models/friendship.dart';
import 'package:moments/core/providers/moments_providers.dart';

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
// FRIENDS & REQUESTS
// ============================================

/// List of current user's friends with offline support
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

  // 2. Fetch fresh data and update cache
  try {
    final friends = await socialRepo.getFriendsProfiles();
    await storage.saveProfiles(friends);
    
    // Update avatar cache with fresh data
    for (final profile in friends) {
      if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
        avatarCache.updateCache(profile.id, profile.avatarUrl!);
      }
    }
    
    yield friends;
  } catch (e) {
    // If network fails and we have cache, we're good. 
    // If no cache, rethrow
    if (cachedProfiles.isEmpty) rethrow;
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
