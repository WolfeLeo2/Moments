import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/data/repositories/moment_repository.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/data/models/moment_contributor.dart';
import 'package:moments/data/models/moment_reaction.dart';
import 'package:moments/core/database/database.dart';
import 'package:moments/core/providers/database_provider.dart';
import 'package:moments/core/services/app_logger.dart';

part 'moments_providers.g.dart';

final _log = AppLogger('MomentsProviders');

/// Moments repository provider - singleton
@Riverpod(keepAlive: true)
MomentRepository momentRepository(Ref ref) => MomentRepository();

/// Stream of all moments with offline-first approach using Drift
/// 1. Immediately yields cached moments from Drift
/// 2. Watches Drift for reactive updates
/// 3. Syncs with Supabase in parallel
@riverpod
Stream<List<Moment>> momentsStream(Ref ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final repo = ref.watch(momentRepositoryProvider);

  final remoteSub = repo.streamAllMoments().listen(
    (moments) {
      unawaited(db.saveMoments(moments.map((m) => m.toCompanion()).toList()));
    },
    onError: (e, stack) {
      _log.e('Error in moments stream', error: e, stackTrace: stack);
    },
  );
  ref.onDispose(remoteSub.cancel);

  yield* db.watchMoments().map(
    (entries) => entries.map((e) => e.toModel()).toList(),
  );
}

/// Stream of shared moments (realtime - moments user is contributor to)
@riverpod
Stream<List<Moment>> sharedMomentsStream(Ref ref) {
  final repo = ref.watch(momentRepositoryProvider);
  return repo.streamSharedMoments();
}

/// Stream of pending moment invitations (realtime)
@riverpod
Stream<List<MomentContributor>> pendingMomentInvitationsStream(Ref ref) {
  final repo = ref.watch(momentRepositoryProvider);
  return repo.watchPendingInvitations();
}

/// Stream moments by group ID (realtime for moment details page)
@riverpod
Stream<List<Moment>> momentsByGroupStream(Ref ref, String groupId) {
  final repo = ref.watch(momentRepositoryProvider);
  return repo.streamMomentsByGroup(groupId);
}

/// Single moment details - Drift first, then remote
@riverpod
Future<Moment?> momentDetails(Ref ref, String momentId) async {
  final db = ref.watch(appDatabaseProvider);
  final repo = ref.watch(momentRepositoryProvider);

  // Try local Drift first
  final cached = await db.getMomentById(momentId);
  if (cached != null) {
    return cached.toModel();
  }

  // Fallback to remote
  return repo.getMomentById(momentId);
}

/// Helper to invalidate moments cache
void invalidateMomentsCache(WidgetRef ref) {
  ref.invalidate(momentsStreamProvider);
  ref.invalidate(sharedMomentsStreamProvider);
}

/// Realtime stream of reactions for a specific moment
/// Used by MomentDetailsPage for instant reaction updates
@riverpod
Stream<List<MomentReaction>> reactionsForMoment(Ref ref, String momentId) {
  final repo = ref.watch(momentRepositoryProvider);
  return repo.watchReactionsForMoment(momentId);
}
