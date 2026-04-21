import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/app_logger.dart';

final _log = AppLogger('StoryRepository');

/// A single story entry.
class Story {
  final String id;
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String mediaUrl;
  final String mediaType; // 'photo' or 'video'
  final String? thumbnailUrl;
  final String? caption;
  final String? location;
  final int durationMs;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewCount;
  final bool isViewed;

  const Story({
    required this.id,
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.mediaUrl,
    required this.mediaType,
    this.thumbnailUrl,
    this.caption,
    this.location,
    this.durationMs = 5000,
    required this.createdAt,
    required this.expiresAt,
    this.viewCount = 0,
    this.isViewed = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['story_id'] as String? ?? json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      mediaUrl: json['media_url'] as String,
      mediaType: json['media_type'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      caption: json['caption'] as String?,
      location: json['location'] as String?,
      durationMs: json['duration_ms'] as int? ?? 5000,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      viewCount: json['view_count'] as int? ?? 0,
      isViewed: json['is_viewed'] as bool? ?? false,
    );
  }
}

/// A group of stories from a single user.
class StoryGroup {
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final List<Story> stories;
  final bool hasUnseen;

  const StoryGroup({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.stories,
    required this.hasUnseen,
  });
}

/// A story viewer entry.
class StoryViewer {
  final String viewerId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime viewedAt;
  final String? reaction;

  const StoryViewer({
    required this.viewerId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.viewedAt,
    this.reaction,
  });

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      viewerId: json['viewer_id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      viewedAt: DateTime.parse(json['viewed_at'] as String),
      reaction: json['reaction'] as String?,
    );
  }
}

class StoryRepository {
  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // ── Fetch ───────────────────────────────────────────────────────

  /// Get all active stories from friends (and self), grouped by user.
  Future<List<StoryGroup>> getFriendsStories() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final result = await _client.rpc(
      'get_friends_stories',
      params: {'requesting_user_id': userId},
    );

    final stories =
        (result as List).map((e) => Story.fromJson(e)).toList();

    // Group by user
    final grouped = <String, List<Story>>{};
    for (final story in stories) {
      grouped.putIfAbsent(story.userId, () => []).add(story);
    }

    // Sort groups: own first, then unseen first, then by most recent
    final currentUserId = userId;
    final groups = grouped.entries.map((entry) {
      final userStories = entry.value;
      final first = userStories.first;
      return StoryGroup(
        userId: entry.key,
        username: first.username,
        displayName: first.displayName,
        avatarUrl: first.avatarUrl,
        stories: userStories,
        hasUnseen: userStories.any((s) => !s.isViewed),
      );
    }).toList();

    groups.sort((a, b) {
      // Own stories always first
      if (a.userId == currentUserId) return -1;
      if (b.userId == currentUserId) return 1;
      // Unseen before seen
      if (a.hasUnseen && !b.hasUnseen) return -1;
      if (!a.hasUnseen && b.hasUnseen) return 1;
      // Most recent first
      return b.stories.first.createdAt.compareTo(a.stories.first.createdAt);
    });

    return groups;
  }

  /// Get viewers of a story.
  Future<List<StoryViewer>> getStoryViewers(String storyId) async {
    final result = await _client.rpc(
      'get_story_viewers',
      params: {'p_story_id': storyId},
    );
    return (result as List).map((e) => StoryViewer.fromJson(e)).toList();
  }

  // ── Create ──────────────────────────────────────────────────────

  /// Upload media and create a story.
  Future<Story> createStory({
    required File mediaFile,
    required String mediaType,
    String? caption,
    String? location,
    double? latitude,
    double? longitude,
    int? durationMs,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be authenticated to create a story');
    }
    final ext = p.extension(mediaFile.path).replaceFirst('.', '');
    final storagePath = '$userId/${_uuid.v4()}.$ext';

    // Upload to storage
    await _client.storage.from('stories').upload(
          storagePath,
          mediaFile,
          fileOptions: FileOptions(
            contentType: mediaType == 'video' ? 'video/mp4' : 'image/jpeg',
          ),
        );

    final mediaUrl =
        _client.storage.from('stories').getPublicUrl(storagePath);

    // Insert story record
    final data = {
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      if (caption != null) 'caption': caption,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (durationMs != null) 'duration_ms': durationMs,
    };

    final result =
        await _client.from('stories').insert(data).select().single();

    _log.i('Created story: ${result['id']}');
    return Story.fromJson(result);
  }

  /// Create a story from raw bytes (e.g., camera capture).
  Future<Story> createStoryFromBytes({
    required Uint8List bytes,
    required String mediaType,
    String extension = 'jpg',
    String? caption,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be authenticated to create a story');
    }
    final storagePath = '$userId/${_uuid.v4()}.$extension';

    await _client.storage.from('stories').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: mediaType == 'video' ? 'video/mp4' : 'image/jpeg',
          ),
        );

    final mediaUrl =
        _client.storage.from('stories').getPublicUrl(storagePath);

    final data = {
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      if (caption != null) 'caption': caption,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    final result =
        await _client.from('stories').insert(data).select().single();

    _log.i('Created story from bytes: ${result['id']}');
    return Story.fromJson(result);
  }

  // ── View / React ────────────────────────────────────────────────

  /// Mark a story as viewed by the current user.
  Future<void> markViewed(String storyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('story_views').upsert(
      {
        'story_id': storyId,
        'viewer_id': userId,
      },
      onConflict: 'story_id,viewer_id',
    );

    // Increment view count
    await _client.rpc('increment_story_view_count', params: {
      'p_story_id': storyId,
    }).catchError((_) {
      // Non-critical — ignore if RPC doesn't exist yet
    });
  }

  /// Send a reaction to a story.
  Future<void> reactToStory(String storyId, String reaction) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('story_views').upsert(
      {
        'story_id': storyId,
        'viewer_id': userId,
        'reaction': reaction,
      },
      onConflict: 'story_id,viewer_id',
    );
  }

  // ── Delete ──────────────────────────────────────────────────────

  /// Delete a story (and its storage file).
  Future<void> deleteStory(String storyId) async {
    // Get the story to find storage path
    final story = await _client
        .from('stories')
        .select('media_url')
        .eq('id', storyId)
        .maybeSingle();

    if (story != null) {
      final mediaUrl = story['media_url'] as String;
      // Extract storage path from public URL
      final uri = Uri.parse(mediaUrl);
      final segments = uri.pathSegments;
      // URL format: .../storage/v1/object/public/stories/{userId}/{filename}
      final storiesIdx = segments.indexOf('stories');
      if (storiesIdx >= 0 && storiesIdx < segments.length - 1) {
        final storagePath = segments.sublist(storiesIdx + 1).join('/');
        await _client.storage.from('stories').remove([storagePath]);
      }
    }

    await _client.from('stories').delete().eq('id', storyId);
    _log.i('Deleted story: $storyId');
  }
}
