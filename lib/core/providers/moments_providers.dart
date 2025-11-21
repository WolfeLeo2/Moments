import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/data/repositories/moment_repository.dart';
import 'package:moments/data/models/moment.dart';

/// Moments repository provider
final momentRepositoryProvider = Provider((ref) => MomentRepository());

/// Stream of all moments (realtime)
final momentsStreamProvider = StreamProvider.autoDispose<List<Moment>>((ref) {
  final repo = ref.watch(momentRepositoryProvider);
  return repo.streamAllMoments();
});

/// Stream of shared moments (realtime - moments user is contributor to)
final sharedMomentsStreamProvider = StreamProvider.autoDispose<List<Moment>>((
  ref,
) {
  final repo = ref.watch(momentRepositoryProvider);
  return repo.streamSharedMoments();
});

/// Single moment details
final momentDetailsProvider = FutureProvider.autoDispose
    .family<Moment?, String>((ref, momentId) async {
      final repo = ref.watch(momentRepositoryProvider);
      return repo.getMomentById(momentId);
    });

/// Notifier for creating moments
class CreateMomentNotifier extends StateNotifier<AsyncValue<Moment?>> {
  final MomentRepository _repo;

  CreateMomentNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> createMoment({
    required File imageFile,
    required String title,
    required String caption,
    required String locationName,
    required double latitude,
    required double longitude,
    bool isPrivate = false,
    String? placeGroupId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.createMoment(
        imageFile,
        title,
        caption,
        locationName,
        latitude,
        longitude,
        isPrivate: isPrivate,
        momentGroupId: placeGroupId,
      ),
    );
  }
}

final createMomentProvider =
    StateNotifierProvider.autoDispose<
      CreateMomentNotifier,
      AsyncValue<Moment?>
    >((ref) {
      final repo = ref.watch(momentRepositoryProvider);
      return CreateMomentNotifier(repo);
    });

/// Notifier for deleting moments
class DeleteMomentNotifier extends StateNotifier<AsyncValue<void>> {
  final MomentRepository _repo;

  DeleteMomentNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> deleteMoment(String momentId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.deleteMoment(momentId));
  }
}

final deleteMomentProvider =
    StateNotifierProvider.autoDispose<DeleteMomentNotifier, AsyncValue<void>>((
      ref,
    ) {
      final repo = ref.watch(momentRepositoryProvider);
      return DeleteMomentNotifier(repo);
    });

/// Helper to invalidate moments cache
void invalidateMomentsCache(WidgetRef ref) {
  ref.invalidate(momentsStreamProvider);
  ref.invalidate(sharedMomentsStreamProvider);
}
