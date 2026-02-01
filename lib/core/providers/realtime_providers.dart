import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/data/models/profile.dart';
import 'package:moments/data/models/friendship.dart';

part 'realtime_providers.g.dart';

/// Stream of real-time pending friend requests
@riverpod
Stream<List<Friendship>> pendingRequestsRealtime(Ref ref) {
  final socialRepo = ref.watch(socialRepositoryProvider);
  return socialRepo.streamPendingRequests();
}

/// Combined friends and requests data - properly reactive
/// Updates whenever either friends list or pending requests change
@riverpod
({List<Profile> friends, List<Friendship> requests}) friendsAndRequests(
  Ref ref,
) {
  final friendsAsync = ref.watch(friendsListProvider);
  final requestsAsync = ref.watch(pendingRequestsRealtimeProvider);

  return (
    friends: friendsAsync.value ?? [],
    requests: requestsAsync.value ?? [],
  );
}

/// Async version that waits for both to load
@riverpod
Future<({List<Profile> friends, List<Friendship> requests})>
friendsAndRequestsAsync(Ref ref) async {
  final friends = await ref.watch(friendsListProvider.future);
  final requests = await ref.watch(pendingRequestsRealtimeProvider.future);

  return (friends: friends, requests: requests);
}
