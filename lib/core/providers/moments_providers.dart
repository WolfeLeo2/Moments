import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/data/repositories/moment_repository.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/core/services/moment_storage_service.dart';

part 'moments_providers.g.dart';

/// Moment storage service provider
@riverpod
MomentStorageService momentStorage(Ref ref) {
  return MomentStorageService();
}

/// Moments repository provider
@riverpod
MomentRepository momentRepository(Ref ref) => MomentRepository();

/// Stream of all moments with offline-first approach
/// 1. Immediately yields cached moments from SQLite
/// 2. Then syncs with Supabase and yields updated moments
@riverpod
Stream<List<Moment>> momentsStream(Ref ref) async* {
  final storage = ref.watch(momentStorageProvider);
  final repo = ref.watch(momentRepositoryProvider);

  // 1. Load cached moments immediately for instant UI
  final cachedMoments = await storage.getMoments();
  if (cachedMoments.isNotEmpty) {
    yield cachedMoments;
  }

  // 2. Subscribe to Supabase realtime stream and update storage
  await for (final moments in repo.streamAllMoments()) {
    // Save to persistent storage
    await storage.saveMoments(moments);
    yield moments;
  }
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
  final storage = ref.watch(momentStorageProvider);
  final repo = ref.watch(momentRepositoryProvider);

  // Try local first
  final cached = await storage.getMomentById(momentId);
  if (cached != null) {
    return cached;
  }

  // Fallback to remote
  return repo.getMomentById(momentId);
}

/// Helper to invalidate moments cache
void invalidateMomentsCache(WidgetRef ref) {
  ref.invalidate(momentsStreamProvider);
  ref.invalidate(sharedMomentsStreamProvider);
}
