import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/data/repositories/moment_repository.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/data/models/moment_contributor.dart';
import 'package:moments/data/models/moment_reaction.dart';
import 'package:moments/core/providers/powersync_provider.dart';
import 'package:moments/core/services/app_logger.dart';

part 'moments_providers.g.dart';

final _log = AppLogger('MomentsProviders');

/// Moments repository provider - singleton
@Riverpod(keepAlive: true)
MomentRepository momentRepository(Ref ref) => MomentRepository();

Future<void> _ensurePowerSyncReady(Ref ref, String context) async {
  final powerSync = ref.watch(chatPowerSyncServiceProvider);
  final initialized = await powerSync.ensureInitialized();
  if (!initialized) {
    throw Exception('PowerSync failed to initialize for $context.');
  }
}

/// Stream of all moments from PowerSync local SQLite.
@riverpod
Stream<List<Moment>> momentsStream(Ref ref) async* {
  await _ensurePowerSyncReady(ref, 'moments stream');
  final powerSync = ref.watch(chatPowerSyncServiceProvider);
  yield* powerSync.watchMoments();
}

/// Stream of shared moments from PowerSync local SQLite.
@riverpod
Stream<List<Moment>> sharedMomentsStream(Ref ref) async* {
  await _ensurePowerSyncReady(ref, 'shared moments stream');
  final powerSync = ref.watch(chatPowerSyncServiceProvider);
  yield* powerSync.watchSharedMoments();
}

/// Stream of pending moment invitations from PowerSync local SQLite.
@riverpod
Stream<List<MomentContributor>> pendingMomentInvitationsStream(Ref ref) async* {
  await _ensurePowerSyncReady(ref, 'pending invitations stream');
  final powerSync = ref.watch(chatPowerSyncServiceProvider);
  yield* powerSync.watchPendingMomentInvitations();
}

/// Stream moments by group ID from PowerSync local SQLite.
@riverpod
Stream<List<Moment>> momentsByGroupStream(Ref ref, String groupId) async* {
  await _ensurePowerSyncReady(ref, 'moments by group stream');
  final powerSync = ref.watch(chatPowerSyncServiceProvider);
  yield* powerSync.watchMomentsByGroup(groupId);
}

/// Single moment details from PowerSync local SQLite.
@riverpod
Future<Moment?> momentDetails(Ref ref, String momentId) async {
  await _ensurePowerSyncReady(ref, 'moment details');
  final powerSync = ref.watch(chatPowerSyncServiceProvider);
  final repo = ref.watch(momentRepositoryProvider);

  final local = await powerSync.getMomentById(momentId);
  if (local != null) return local;

  // Emergency online fallback without reintroducing manual sync loop.
  try {
    return await repo.getMomentById(momentId);
  } catch (e, stack) {
    _log.e(
      'Failed to resolve moment details fallback',
      error: e,
      stackTrace: stack,
    );
    rethrow;
  }
}

/// Helper to invalidate moments cache
void invalidateMomentsCache(WidgetRef ref) {
  ref.invalidate(momentsStreamProvider);
  ref.invalidate(sharedMomentsStreamProvider);
}

/// Realtime stream of reactions for a specific moment from PowerSync local SQLite.
@riverpod
Stream<List<MomentReaction>> reactionsForMoment(
  Ref ref,
  String momentId,
) async* {
  await _ensurePowerSyncReady(ref, 'moment reactions stream');
  final powerSync = ref.watch(chatPowerSyncServiceProvider);
  yield* powerSync.watchMomentReactionsForMoment(momentId);
}
