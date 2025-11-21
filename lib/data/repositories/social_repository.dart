import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/friendship.dart';
import '../sources/supabase_config.dart';

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
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;
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
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Find the user with this invite code
      final friendProfile = await getProfileByInviteCode(inviteCode);
      if (friendProfile == null) {
        throw Exception('Invalid invite code');
      }

      if (friendProfile.id == userId) {
        throw Exception('Cannot add yourself as a friend');
      }

      // Check if friendship already exists
      final existing = await _client
          .from('friendships')
          .select()
          .eq('user_id', userId)
          .eq('friend_id', friendProfile.id)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Friend request already sent');
      }

      // Create friendship request
      final response = await _client
          .from('friendships')
          .insert({
            'user_id': userId,
            'friend_id': friendProfile.id,
            'status': 'pending',
          })
          .select()
          .single();

      return Friendship.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send friend request: $e');
    }
  }

  /// Accept friend request
  Future<Friendship> acceptFriendRequest(String friendshipId) async {
    try {
      final response = await _client
          .from('friendships')
          .update({
            'status': 'accepted',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId)
          .select()
          .single();

      return Friendship.fromJson(response);
    } catch (e) {
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

  /// Remove friend (delete friendship)
  Future<void> removeFriend(String friendshipId) async {
    try {
      await _client.from('friendships').delete().eq('id', friendshipId);
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }

  /// Get pending friend requests (received by current user)
  Future<List<Friendship>> getPendingRequests() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

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
  // ============================================
  // REALTIME STREAMS
  // ============================================

  /// Stream of friends profiles (Realtime)
  /// Watches friendships table and fetches profiles when it changes
  Stream<List<Profile>> streamFriends() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value(<Profile>[]);
    }

    // Watch friendships table for any accepted friendship involving the user
    // Note: stream() does not support eq() directly in this version of the SDK for all platforms/versions
    // or it behaves differently. The correct way usually is to just stream and filter in client
    // or use eq() BEFORE stream() if supported (but stream() returns SupabaseStreamBuilder which might not have eq).
    // Actually, in supabase_flutter v2, stream() takes filters as arguments or we filter on the collection BEFORE .stream()?
    // No, .stream() is on the Table.
    // Let's check the SDK version. It's ^2.10.3.
    // In v2, we should use: .stream(primaryKey: ['id']).eq('status', 'accepted')
    // If that fails, it means the builder returned by stream() doesn't have eq.
    // Wait, the error says "The method 'eq' isn't defined for the type 'SupabaseStreamBuilder'".
    // This means we cannot filter a stream on the server side with this SDK version using .eq() AFTER .stream().
    // We must accept all events and filter in Dart, OR use a different approach.

    // However, for 'streamPendingRequests', we really want to filter by user_id.
    // Let's try to filter in Dart for now to be safe and fix the error.

    return _client
        .from('friendships')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          // We just re-fetch everything to be safe and simple
          return getFriendsProfiles();
        })
        .handleError((e) {
          print('Error streaming friends: $e');
          return <Profile>[];
        });
  }

  /// Stream of pending requests (Realtime)
  Stream<List<Friendship>> streamPendingRequests() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value(<Friendship>[]);
    }

    return _client
        .from('friendships')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter in Dart because .eq() is not supported on stream builder
          final requests = (data as List)
              .map((json) => Friendship.fromJson(json as Map<String, dynamic>))
              .where((f) => f.friendId == userId && f.status == 'pending')
              .toList();

          // Sort by requested_at desc
          requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

          return requests;
        })
        .handleError((e) {
          print('Error streaming pending requests: $e');
          return <Friendship>[];
        });
  }
}
