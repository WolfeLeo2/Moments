import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/providers/providers.dart';

/// Stream of real-time pending friend requests
final pendingRequestsRealtimeProvider = StreamProvider((ref) {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.streamPendingRequests();
});

/// Combine friends and requests into single stream for more efficient updates
final friendsAndRequestsProvider = StreamProvider((ref) async* {
  final friends = await ref.watch(friendsListProvider.future);
  final requests = await ref.watch(pendingRequestsProvider.future);

  yield {'friends': friends, 'requests': requests};
});
