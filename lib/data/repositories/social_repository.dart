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
}
