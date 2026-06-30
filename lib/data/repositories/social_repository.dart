import 'package:moments/core/services/app_logger.dart';
import 'package:moments/core/services/phone_hash_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/friendship.dart';
import '../sources/supabase_config.dart';

final _log = AppLogger('SocialRepository');

/// Repository for managing user profiles and friendships
class SocialRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  // ============================================
  // PROFILE MANAGEMENT
  // ============================================

  /// Get current user's profile
  Future<Profile?> getCurrentUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch current user profile: $e');
    }
  }

  /// Get profile by user ID
  Future<Profile?> getProfileById(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Get profile by invite code
  Future<Profile?> getProfileByInviteCode(String inviteCode) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('invite_code', inviteCode.toUpperCase())
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to find user with invite code: $e');
    }
  }

  /// Create or update profile
  Future<Profile> upsertProfile(Profile profile) async {
    try {
      final response = await _client
          .from('profiles')
          .upsert(profile.toJson())
          .select()
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  /// Update current user's profile
  Future<Profile> updateCurrentUserProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? phoneNumber,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;
      if (phoneNumber != null) {
        updates['phone_number'] = phoneNumber;
        updates['phone_hash'] = PhoneHashService.hashNumber(phoneNumber);
      }
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // ============================================
  // FRIENDSHIP MANAGEMENT
  // ============================================

  /// Send friend request using invite code
  Future<Friendship> sendFriendRequest(String inviteCode) async {
    try {
      _log.d('Starting friend request with code: $inviteCode');

      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        _log.e('User not authenticated');
        throw Exception('User not authenticated');
      }
      _log.d('User ID: $userId');

      // Find the user with this invite code
      _log.d('Looking up profile with invite code...');
      final friendProfile = await getProfileByInviteCode(inviteCode);
      if (friendProfile == null) {
        _log.e('No profile found with code: $inviteCode');
        throw Exception('Invalid invite code');
      }
      _log.d(
        'Found profile: ${friendProfile.id} (${friendProfile.displayName ?? friendProfile.username})',
      );

      if (friendProfile.id == userId) {
        _log.w('User tried to add themselves as friend');
        throw Exception('Cannot add yourself as a friend');
      }

      // Check if friendship already exists IN EITHER DIRECTION
      _log.d('Checking for existing friendship...');
      final existingOutgoing = await _client
          .from('friendships')
          .select()
          .eq('user_id', userId)
          .eq('friend_id', friendProfile.id)
          .maybeSingle();

      if (existingOutgoing != null) {
        throw Exception('Friend request already sent');
      }

      // Check if THEY already sent US a request
      final existingIncoming = await _client
          .from('friendships')
          .select()
          .eq('user_id', friendProfile.id)
          .eq('friend_id', userId)
          .maybeSingle();

      if (existingIncoming != null) {
        final status = existingIncoming['status'] as String;
        if (status == 'pending') {
          throw Exception(
            'This user has already sent you a friend request. Check your notifications!',
          );
        } else if (status == 'accepted') {
          throw Exception('You are already friends with this user');
        }
      }
      _log.d('No existing friendship found');

      // Create friendship request
      _log.d('Inserting friendship record...');
      final insertData = {
        'user_id': userId,
        'friend_id': friendProfile.id,
        'status': 'pending',
      };
      _log.d('Insert data: $insertData');

      final response = await _client
          .from('friendships')
          .insert(insertData)
          .select()
          .single();

      _log.i('Successfully created friendship!');
      _log.d('Response: $response');

      return Friendship.fromJson(response);
    } catch (e, stackTrace) {
      _log.e('Friend request error: $e', stackTrace: stackTrace);
      throw Exception('Failed to send friend request: $e');
    }
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String friendshipId) async {
    try {
      _log.d('Starting accept for friendship: $friendshipId');

      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        _log.e('User not authenticated');
        throw Exception('User not authenticated');
      }
      _log.d('User ID: $userId');

      _log.d('Updating friendship status to accepted...');
      await _client
          .from('friendships')
          .update({
            'status': 'accepted',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId);

      _log.i('Successfully accepted friendship!');
    } catch (e, stackTrace) {
      _log.e('Accept friend request error: $e', stackTrace: stackTrace);
      throw Exception('Failed to accept friend request: $e');
    }
  }

  /// Reject friend request
  Future<Friendship> rejectFriendRequest(String friendshipId) async {
    try {
      final response = await _client
          .from('friendships')
          .update({
            'status': 'rejected',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId)
          .select()
          .single();

      return Friendship.fromJson(response);
    } catch (e) {
      throw Exception('Failed to reject friend request: $e');
    }
  }

  /// Remove friend (delete friendship in either direction)
  Future<void> removeFriend(String friendUserId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('friendships')
          .delete()
          .or('and(user_id.eq.$userId,friend_id.eq.$friendUserId),and(user_id.eq.$friendUserId,friend_id.eq.$userId)');
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }

  /// Get pending friend requests (received by current user)
  Future<List<Friendship>> getPendingRequests() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      // We need to fetch the sender's profile as well
      // But Friendship model doesn't have profile data.
      // We can fetch it separately or use a join if we update the model.
      // For now, let's just fetch the friendships.
      // The UI (NotificationsPage) seems to expect 'actorName' etc.
      // Wait, NotificationsPage combines 'Friendship' objects into 'NotificationItem'.
      // But 'Friendship' object only has IDs.
      // Where does 'actorName' come from for Friend Requests?
      // In _combineNotifications:
      // items.add(NotificationItem(..., body: 'sent you a friend request', ...));
      // It doesn't seem to fetch the profile!
      // This is why the card might be missing info or looking generic.

      final response = await _client
          .from('friendships')
          .select()
          .eq('friend_id', userId)
          .eq('status', 'pending')
          .order('requested_at', ascending: false);

      return (response as List)
          .map((json) => Friendship.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending requests: $e');
    }
  }

  /// Get sent friend requests (outgoing, not yet accepted)
  Future<List<Friendship>> getSentRequests() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('friendships')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending')
          .order('requested_at', ascending: false);

      return (response as List)
          .map((json) => Friendship.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch sent requests: $e');
    }
  }

  /// Get all friends (accepted friendships)
  Future<List<Friendship>> getFriends() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('friendships')
          .select()
          .eq('status', 'accepted')
          .or('user_id.eq.$userId,friend_id.eq.$userId');

      return (response as List)
          .map((json) => Friendship.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch friends: $e');
    }
  }

  /// Get friend IDs for current user
  Future<List<String>> getFriendIds() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final friendships = await getFriends();

      return friendships.map((f) {
        // Return the other user's ID
        return f.userId == userId ? f.friendId : f.userId;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch friend IDs: $e');
    }
  }

  /// Get friends' profiles
  Future<List<Profile>> getFriendsProfiles() async {
    try {
      final friendIds = await getFriendIds();
      if (friendIds.isEmpty) return [];

      final response = await _client
          .from('profiles')
          .select()
          .inFilter('id', friendIds);

      return (response as List)
          .map((json) => Profile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch friends profiles: $e');
    }
  }

  /// Get mutual friends count between current user and another user
  /// Uses a SECURITY DEFINER RPC to bypass RLS limitations.
  Future<int> getMutualFriendsCount(String friendId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final result = await _client.rpc(
        'get_mutual_friends_count',
        params: {'user_a': userId, 'user_b': friendId},
      );

      return (result as int?) ?? 0;
    } catch (e) {
      _log.e('Error getting mutual friends count: $e');
      return 0;
    }
  }

  /// Get count of public moments for a specific user
  Future<int> getUserMomentsCount(String userId) async {
    try {
      final response = await _client
          .from('moments')
          .select('id')
          .eq('user_id', userId)
          .eq('is_private', false);

      return (response as List).length;
    } catch (e) {
      _log.e('Error getting user moments count: $e');
      return 0;
    }
  }
  // ============================================
  // REALTIME STREAMS
  // ============================================

  /// Stream of ANY friendship changes (for triggering refreshes)
  Stream<void> streamFriendshipChanges() {
    return _client.from('friendships').stream(primaryKey: ['id']).map((_) {});
  }

  /// Stream of pending requests (Realtime)
  Stream<List<Friendship>> streamPendingRequests() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _log.w('No authenticated user for pending requests stream');
      return Stream.value(<Friendship>[]);
    }

    _log.d('Starting pending requests stream for user: $userId');

    return _client
        .from('friendships')
        .stream(primaryKey: ['id'])
        .eq('friend_id', userId)
        .map((data) {
          final requests = data
              .map((json) => Friendship.fromJson(json as Map<String, dynamic>))
              .where((f) => f.status == FriendshipStatus.pending)
              .toList()
            ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          _log.d('Pending requests: ${requests.length}');
          return requests;
        })
        .handleError((e) {
          _log.e('Pending requests stream error: $e');
          return <Friendship>[];
        });
  }

  // ============================================
  // FRIEND DISCOVERY
  // ============================================

  /// Search profiles by username, display_name, or phone number
  Future<List<Profile>> searchProfiles(String query) async {
    try {
      if (query.trim().length < 2) return [];
      final response = await _client.rpc(
        'search_profiles',
        params: {'query': query.trim()},
      );
      return (response as List)
          .map((json) => Profile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log.e('Search profiles error: $e');
      return [];
    }
  }

  /// Find profiles by list of phone hashes (blind matching).
  /// Phone numbers are hashed client-side before being sent.
  Future<List<Profile>> findProfilesByPhone(List<String> phoneHashes) async {
    try {
      if (phoneHashes.isEmpty) return [];
      final response = await _client.rpc(
        'find_profiles_by_phone',
        params: {'phone_hashes': phoneHashes},
      );
      return (response as List)
          .map((json) => Profile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log.e('Find by phone hash error: $e');
      return [];
    }
  }

  /// Find nearby users based on location
  Future<List<Map<String, dynamic>>> findNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    try {
      final response = await _client.rpc(
        'find_nearby_users',
        params: {
          'user_lat': latitude,
          'user_lng': longitude,
          'radius_km': radiusKm,
        },
      );
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _log.e('Find nearby users error: $e');
      return [];
    }
  }

  /// Update current user's phone number (stores both raw + hash)
  Future<void> updatePhoneNumber(String phoneNumber) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      await _client.from('profiles').update({
        'phone_number': phoneNumber,
        'phone_hash': PhoneHashService.hashNumber(phoneNumber),
      }).eq('id', userId);
    } catch (e) {
      _log.e('Update phone number error: $e');
    }
  }

  /// Check friendship status with a specific user
  Future<String?> getFriendshipStatus(String otherUserId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('friendships')
          .select('status')
          .or('and(user_id.eq.$userId,friend_id.eq.$otherUserId),and(user_id.eq.$otherUserId,friend_id.eq.$userId)')
          .maybeSingle();

      return response?['status'] as String?;
    } catch (e) {
      _log.e('Get friendship status error: $e');
      return null;
    }
  }

  /// Send friend request by user ID (instead of invite code)
  Future<void> sendFriendRequestById(String friendId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      if (userId == friendId) {
        throw Exception('Cannot send friend request to yourself');
      }

      // Check for existing friendship
      final existing = await _client
          .from('friendships')
          .select()
          .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)')
          .maybeSingle();

      if (existing != null) {
        final status = existing['status'];
        if (status == 'accepted') throw Exception('Already friends');
        if (status == 'pending') throw Exception('Request already pending');
        if (status == 'blocked') throw Exception('Unable to send request');
      }

      await _client.from('friendships').insert({
        'user_id': userId,
        'friend_id': friendId,
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      });

      _log.i('Sent friend request to $friendId');
    } catch (e) {
      _log.e('Send friend request by ID error: $e');
      rethrow;
    }
  }
}
