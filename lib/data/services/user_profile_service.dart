import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get user profiles by their IDs
  static Future<List<UserProfile>> getUserProfiles(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', userIds);

      return (response as List<dynamic>)
          .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching user profiles: $e');
      return [];
    }
  }

  // Get a single user profile
  static Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Create or update a user profile
  static Future<UserProfile?> upsertUserProfile(UserProfile profile) async {
    try {
      final response = await _supabase
          .from('profiles')
          .upsert(profile.toJson())
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error upserting user profile: $e');
      return null;
    }
  }

  /// Get contributor avatars for given user IDs
  static Future<List<String>> getContributorAvatars(
    List<String> userIds,
  ) async {
    try {
      if (userIds.isEmpty) return [];

      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, avatar_url')
          .inFilter('id', userIds);

      final List<dynamic> data = response as List<dynamic>;

      final avatarUrls = <String>[];
      for (var profile in data) {
        final avatarUrl = profile['avatar_url'] as String?;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          avatarUrls.add(avatarUrl);
        } else {
          // Add default avatar for users without profile pictures
          avatarUrls.add(getDefaultAvatarUrl());
        }
      }

      return avatarUrls;
    } catch (e) {
      print('Error fetching contributor avatars: $e');
      // Return default avatars for all users on error
      return List.generate(userIds.length, (index) => getDefaultAvatarUrl());
    }
  }

  // Get default fallback avatar URL
  static String getDefaultAvatarUrl() {
    return 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y';
  }

  // Get avatar URL for a user ID (with fallback)
  static Future<String> getAvatarUrl(String userId) async {
    final profile = await getUserProfile(userId);
    return profile?.avatarUrl?.isNotEmpty == true
        ? profile!.avatarUrl!
        : getDefaultAvatarUrl();
  }
}
