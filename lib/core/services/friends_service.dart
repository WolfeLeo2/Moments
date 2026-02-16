import 'dart:async';
import 'package:moments/core/services/app_logger.dart';
import 'package:moments/core/services/avatar_cache_service.dart';
import 'package:moments/data/models/profile.dart';
import 'package:moments/data/repositories/social_repository.dart';
import 'package:moments/core/database/database.dart';

final _log = AppLogger('FriendsService');

/// Service that manages the friends list with offline-first architecture.
///
/// Responsibilities:
/// - Load cached friends from Drift for instant UI
/// - Fetch fresh data from network and update cache
/// - Subscribe to realtime friendship changes
/// - Keep avatar cache in sync
class FriendsService {
  final SocialRepository _socialRepo;
  final AppDatabase _db;
  final AvatarCacheService _avatarCache;

  FriendsService({
    required SocialRepository socialRepo,
    required AppDatabase db,
    required AvatarCacheService avatarCache,
  }) : _socialRepo = socialRepo,
       _db = db,
       _avatarCache = avatarCache;

  /// Stream of friends profiles with cache → network → realtime updates.
  Stream<List<Profile>> watchFriends() async* {
    // 1. Load cached friends immediately from Drift
    final cachedEntries = await _db.getProfiles();
    if (cachedEntries.isNotEmpty) {
      final cachedProfiles = cachedEntries.map((e) => e.toModel()).toList();
      _updateAvatarCache(cachedProfiles);
      yield cachedProfiles;
    }

    // 2. Fetch fresh data from network
    try {
      final friends = await _socialRepo.getFriendsProfiles();
      await _db.saveProfiles(friends.map((p) => p.toCompanion()).toList());
      _updateAvatarCache(friends);
      yield friends;
    } catch (e) {
      if (cachedEntries.isEmpty) rethrow;
      _log.w('Network failed for friends list, using cache', error: e);
    }

    // 3. Subscribe to realtime updates on friendships table
    await for (final _ in _socialRepo.streamFriendshipChanges()) {
      try {
        final updatedFriends = await _socialRepo.getFriendsProfiles();
        await _db.saveProfiles(
          updatedFriends.map((p) => p.toCompanion()).toList(),
        );
        _updateAvatarCache(updatedFriends);
        yield updatedFriends;
      } catch (e) {
        _log.w('Error updating friends list from stream', error: e);
      }
    }
  }

  /// Populate avatar cache from profiles
  void _updateAvatarCache(List<Profile> profiles) {
    for (final profile in profiles) {
      if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
        _avatarCache.updateCache(profile.id, profile.avatarUrl!);
      }
    }
  }
}
