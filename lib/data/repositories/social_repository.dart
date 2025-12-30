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
      print('🔵 [FRIEND REQUEST] Starting request with code: $inviteCode');

      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ [FRIEND REQUEST] User not authenticated');
        throw Exception('User not authenticated');
      }
      print('✅ [FRIEND REQUEST] User ID: $userId');

      // Find the user with this invite code
      print('🔍 [FRIEND REQUEST] Looking up profile with invite code...');
      final friendProfile = await getProfileByInviteCode(inviteCode);
      if (friendProfile == null) {
        print('❌ [FRIEND REQUEST] No profile found with code: $inviteCode');
        throw Exception('Invalid invite code');
      }
      print(
        '✅ [FRIEND REQUEST] Found profile: ${friendProfile.id} (${friendProfile.displayName ?? friendProfile.username})',
      );

      if (friendProfile.id == userId) {
        print('❌ [FRIEND REQUEST] User tried to add themselves');
        throw Exception('Cannot add yourself as a friend');
      }

      // Check if friendship already exists
      print('🔍 [FRIEND REQUEST] Checking for existing friendship...');
      final existing = await _client
          .from('friendships')
          .select()
          .eq('user_id', userId)
          .eq('friend_id', friendProfile.id)
          .maybeSingle();

      if (existing != null) {
        print(
          '❌ [FRIEND REQUEST] Friendship already exists: ${existing['status']}',
        );
        throw Exception('Friend request already sent');
      }
      print('✅ [FRIEND REQUEST] No existing friendship found');

      // Create friendship request
      print('📝 [FRIEND REQUEST] Inserting friendship record...');
      final insertData = {
        'user_id': userId,
        'friend_id': friendProfile.id,
        'status': 'pending',
      };
      print('📝 [FRIEND REQUEST] Insert data: $insertData');

      final response = await _client
          .from('friendships')
          .insert(insertData)
          .select()
          .single();

      print('✅ [FRIEND REQUEST] Successfully created friendship!');
      print('📊 [FRIEND REQUEST] Response: $response');

      return Friendship.fromJson(response);
    } catch (e, stackTrace) {
      print('❌ [FRIEND REQUEST] Error: $e');
      print('📚 [FRIEND REQUEST] Stack trace: $stackTrace');
      throw Exception('Failed to send friend request: $e');
    }
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String friendshipId) async {
    try {
      print(
        '🔵 [ACCEPT REQUEST] Starting accept for friendship: $friendshipId',
      );

      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ [ACCEPT REQUEST] User not authenticated');
        throw Exception('User not authenticated');
      }
      print('✅ [ACCEPT REQUEST] User ID: $userId');

      print('📝 [ACCEPT REQUEST] Updating friendship status to accepted...');
      await _client
          .from('friendships')
          .update({
            'status': 'accepted',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId);

      print('✅ [ACCEPT REQUEST] Successfully accepted friendship!');
    } catch (e, stackTrace) {
      print('❌ [ACCEPT REQUEST] Error: $e');
      print('📚 [ACCEPT REQUEST] Stack trace: $stackTrace');
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
  /// Mutual friends = users who are friends with BOTH the current user AND the target user
  Future<int> getMutualFriendsCount(String friendId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      // Get current user's friend IDs
      final myFriendIds = await getFriendIds();
      if (myFriendIds.isEmpty) return 0;

      // Get the target user's friend IDs
      final theirFriendships = await _client
          .from('friendships')
          .select()
          .eq('status', 'accepted')
          .or('user_id.eq.$friendId,friend_id.eq.$friendId');

      final theirFriendIds = (theirFriendships as List).map((f) {
        final friendship = f as Map<String, dynamic>;
        final uId = friendship['user_id'] as String;
        final fId = friendship['friend_id'] as String;
        return uId == friendId ? fId : uId;
      }).toSet();

      // Count mutual: intersection of both friend lists (excluding each other)
      final mutualCount = myFriendIds
          .where(
            (id) =>
                theirFriendIds.contains(id) && id != friendId && id != userId,
          )
          .length;

      return mutualCount;
    } catch (e) {
      print('Error getting mutual friends count: $e');
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
      print('Error getting user moments count: $e');
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
      print('⚠️ [PENDING REQUESTS STREAM] No authenticated user');
      return Stream.value(<Friendship>[]);
    }

    print('🔵 [PENDING REQUESTS STREAM] Starting stream for user: $userId');

    return _client
        .from('friendships')
        .stream(primaryKey: ['id'])
        .map((data) {
          print(
            '📊 [PENDING REQUESTS STREAM] Received ${data.length} total friendships',
          );

          // Filter in Dart because .eq() is not supported on stream builder
          final requests = (data as List)
              .map((json) => Friendship.fromJson(json as Map<String, dynamic>))
              .where((f) {
                final isForMe = f.friendId == userId;
                final isPending =
                    f.status ==
                    FriendshipStatus
                        .pending; // FIX: Compare to enum, not string
                print(
                  '  - Friendship ${f.id}: friendId=${f.friendId}, status=${f.status}, isForMe=$isForMe, isPending=$isPending',
                );
                return isForMe && isPending;
              })
              .toList();

          print(
            '✅ [PENDING REQUESTS STREAM] Filtered to ${requests.length} pending requests',
          );

          // Sort by requested_at desc
          requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

          return requests;
        })
        .handleError((e) {
          print('❌ [PENDING REQUESTS STREAM] Error: $e');
          return <Friendship>[];
        });
  }
}
