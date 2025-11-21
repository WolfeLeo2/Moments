import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/services/auth_service.dart';
import 'package:moments/data/repositories/social_repository.dart';
import 'package:moments/data/models/profile.dart';
import 'package:moments/data/models/friendship.dart';

// ============================================
// SINGLETON PROVIDERS
// ============================================

/// Auth service provider - always same instance
final authServiceProvider = Provider((ref) => AuthService());

/// Social repository provider - always same instance
final socialRepositoryProvider = Provider((ref) => SocialRepository());

// ============================================
// AUTH STATE
// ============================================

/// Current authenticated user
final currentUserProvider = StreamProvider((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((state) => state.session?.user);
});

/// Current user's profile with auto-refresh
final currentUserProfileProvider = FutureProvider<Profile?>((ref) async {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getCurrentUserProfile();
});

// ============================================
// FRIENDS & REQUESTS
// ============================================

/// List of current user's friends
final friendsListProvider = FutureProvider<List<Profile>>((ref) async {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getFriendsProfiles();
});

/// Pending friend requests
final pendingRequestsProvider = FutureProvider<List<Friendship>>((ref) async {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getPendingRequests();
});

/// Get a friend's profile by ID - cached per user to prevent API spam
final friendProfileProvider = FutureProvider.family<Profile?, String>((
  ref,
  friendId,
) async {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.getProfileById(friendId);
});

// ============================================
// NOTIFIER CLASSES FOR STATE MUTATIONS
// ============================================

/// Notifier for adding a friend
class AddFriendNotifier extends StateNotifier<AsyncValue<void>> {
  final SocialRepository _socialRepo;

  AddFriendNotifier(this._socialRepo) : super(const AsyncValue.data(null));

  Future<void> sendFriendRequest(String inviteCode) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _socialRepo.sendFriendRequest(inviteCode),
    );
    if (mounted) {
      state = result;
    }
  }
}

final addFriendProvider =
    StateNotifierProvider.autoDispose<AddFriendNotifier, AsyncValue<void>>((
      ref,
    ) {
      final socialRepo = ref.watch(socialRepositoryProvider);
      return AddFriendNotifier(socialRepo);
    });

// ============================================
// FRIEND REQUEST ACTIONS
// ============================================

class FriendRequestNotifier extends StateNotifier<AsyncValue<void>> {
  final SocialRepository _socialRepo;

  FriendRequestNotifier(this._socialRepo) : super(const AsyncValue.data(null));

  Future<void> acceptRequest(String friendshipId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _socialRepo.acceptFriendRequest(friendshipId),
    );
  }

  Future<void> rejectRequest(String friendshipId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _socialRepo.rejectFriendRequest(friendshipId),
    );
  }
}

final friendRequestProvider =
    StateNotifierProvider.autoDispose<FriendRequestNotifier, AsyncValue<void>>((
      ref,
    ) {
      final socialRepo = ref.watch(socialRepositoryProvider);
      return FriendRequestNotifier(socialRepo);
    });

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
