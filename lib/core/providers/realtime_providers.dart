import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/providers/providers.dart';

/// Stream of real-time friends list changes
final friendsRealtimeProvider = StreamProvider.autoDispose((ref) async* {
  final socialRepo = ref.watch(socialRepositoryProvider);
  final userId = ref.watch(currentUserProvider).value?.id;

  if (userId == null) return;

  // Initial load
  try {
    final friends = await socialRepo.getFriendsProfiles();
    yield friends;
  } catch (e) {
    print('Error loading initial friends: $e');
  }

  // Subscribe to friendship changes
  ref.listen(friendsListProvider, (prev, next) {
    next.whenData((friends) {
      // This will trigger whenever the provider updates
    });
  });
});

/// Stream of real-time pending friend requests
final pendingRequestsRealtimeProvider = StreamProvider.autoDispose((
  ref,
) async* {
  final socialRepo = ref.watch(socialRepositoryProvider);
  final userId = ref.watch(currentUserProvider).value?.id;

  if (userId == null) return;

  try {
    final requests = await socialRepo.getPendingRequests();
    yield requests;
  } catch (e) {
    print('Error loading initial requests: $e');
  }

  ref.listen(pendingRequestsProvider, (prev, next) {
    next.whenData((requests) {
      // This will trigger whenever requests update
    });
  });
});

/// Combine friends and requests into single stream for more efficient updates
final friendsAndRequestsProvider = StreamProvider.autoDispose((ref) async* {
  final friends = await ref.watch(friendsListProvider.future);
  final requests = await ref.watch(pendingRequestsProvider.future);

  yield {'friends': friends, 'requests': requests};
});
