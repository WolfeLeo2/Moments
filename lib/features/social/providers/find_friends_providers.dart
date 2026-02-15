import 'dart:async';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart' as loc;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_logger.dart';
import '../../../core/services/phone_hash_service.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/profile.dart';

part 'find_friends_providers.g.dart';

final _log = AppLogger('FindFriendsProviders');

// ═══════════════════════════════════════════════════════════════════
// Search Profiles Provider
// ═══════════════════════════════════════════════════════════════════

/// Searches profiles when query is >= 2 chars.
/// Auto-disposed: only kept alive while the search field is visible.
@riverpod
Future<List<Profile>> searchResults(Ref ref, {required String query}) async {
  if (query.trim().length < 2) return [];
  final repo = ref.watch(socialRepositoryProvider);
  return repo.searchProfiles(query);
}

// ═══════════════════════════════════════════════════════════════════
// Contacts Sync Provider
// ═══════════════════════════════════════════════════════════════════

/// State: null → not yet synced, empty list → synced with no matches.
/// keepAlive so the results survive page navigation.
@Riverpod(keepAlive: true)
class ContactMatches extends _$ContactMatches {
  @override
  FutureOr<List<Profile>?> build() => null;

  Future<void> syncContacts() async {
    state = const AsyncLoading();
    try {
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        state = AsyncError('permission_denied', StackTrace.current);
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Collect raw phone numbers from contacts
      final rawNumbers = <String>[];
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized =
              phone.number.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
          if (normalized.length >= 7) {
            rawNumbers.add(normalized);
          }
        }
      }

      _log.i('Found ${rawNumbers.length} phone numbers from contacts');

      if (rawNumbers.isEmpty) {
        state = const AsyncData([]);
        return;
      }

      // Hash all numbers locally — only hashes leave the device
      final hashes = PhoneHashService.hashBatch(rawNumbers);
      _log.i('Hashed to ${hashes.length} unique fingerprints');

      final repo = ref.read(socialRepositoryProvider);
      final matches = await repo.findProfilesByPhone(hashes);
      state = AsyncData(matches);
    } catch (e) {
      _log.e('Contacts sync error: $e');
      state = AsyncError(e, StackTrace.current);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// People Nearby Provider
// ═══════════════════════════════════════════════════════════════════

/// State: null → not yet discovered, empty list → no nearby users.
/// keepAlive so the results survive page navigation.
@Riverpod(keepAlive: true)
class NearbyUsers extends _$NearbyUsers {
  @override
  FutureOr<List<Map<String, dynamic>>?> build() => null;

  Future<void> loadNearby() async {
    state = const AsyncLoading();
    try {
      final location = loc.Location();

      var permission = await location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await location.requestPermission();
      }
      if (permission == loc.PermissionStatus.denied ||
          permission == loc.PermissionStatus.deniedForever) {
        state = AsyncError('permission_denied', StackTrace.current);
        return;
      }

      final locationData = await location.getLocation();
      if (locationData.latitude == null || locationData.longitude == null) {
        state = const AsyncData([]);
        return;
      }

      final repo = ref.read(socialRepositoryProvider);
      final nearby = await repo.findNearbyUsers(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        radiusKm: 10,
      );

      state = AsyncData(nearby);
    } catch (e) {
      _log.e('Nearby users error: $e');
      state = AsyncError(e, StackTrace.current);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Friendship Status Provider (family)
// ═══════════════════════════════════════════════════════════════════

/// Fetch friendship status for a specific user. Auto-disposed per tile.
@riverpod
Future<String> friendshipStatus(Ref ref, {required String userId}) async {
  final repo = ref.watch(socialRepositoryProvider);
  final status = await repo.getFriendshipStatus(userId);
  return status ?? 'none';
}

// ═══════════════════════════════════════════════════════════════════
// Sending Requests Tracker
// ═══════════════════════════════════════════════════════════════════

/// Tracks user IDs with in-flight friend request sends.
/// keepAlive so concurrent navigations don't lose the set.
@Riverpod(keepAlive: true)
class SendingRequests extends _$SendingRequests {
  @override
  Set<String> build() => {};

  void add(String userId) {
    state = {...state, userId};
  }

  void remove(String userId) {
    state = Set.from(state)..remove(userId);
  }
}
