import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/data/repositories/moment_repository.dart';
import 'package:moments/data/models/moment.dart';

part 'moments_providers.g.dart';

/// Moments repository provider
@riverpod
MomentRepository momentRepository(Ref ref) => MomentRepository();

/// Stream of all moments (realtime)
@riverpod
Stream<List<Moment>> momentsStream(Ref ref) {
  final repo = ref.watch(momentRepositoryProvider);
  return repo.streamAllMoments();
}

/// Stream of shared moments (realtime - moments user is contributor to)
@riverpod
Stream<List<Moment>> sharedMomentsStream(Ref ref) {
  final repo = ref.watch(momentRepositoryProvider);
  return repo.streamSharedMoments();
}

/// Single moment details
@riverpod
Future<Moment?> momentDetails(Ref ref, String momentId) async {
  final repo = ref.watch(momentRepositoryProvider);
  return repo.getMomentById(momentId);
}

/// Helper to invalidate moments cache
void invalidateMomentsCache(WidgetRef ref) {
  ref.invalidate(momentsStreamProvider);
  ref.invalidate(sharedMomentsStreamProvider);
}
