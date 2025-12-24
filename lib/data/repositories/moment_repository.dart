import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import '../models/moment.dart';
import '../models/moment_reaction.dart';
import '../models/moment_group.dart';
import '../models/moment_contributor.dart';
import '../sources/supabase_config.dart';
import '../../core/services/media_compression_service.dart';

class MomentRepository {
  static const _uuid = Uuid();

  // Get all moments
  Future<List<Moment>> getMoments() async {
    try {
      final response = await SupabaseConfig.momentsTable.select().order(
        'created_at',
        ascending: false,
      );

      return (response as List)
          .map((json) => Moment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch moments: $e');
    }
  }

  // Get moment by ID
  Future<Moment?> getMomentById(String id) async {
    try {
      final response = await SupabaseConfig.momentsTable
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return Moment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch moment: $e');
    }
  }

  // Create new moment (delegates to batch creation for consistency)
  Future<Moment> createMoment(
    File mediaFile,
    String title,
    String caption,
    String locationName,
    double latitude,
    double longitude, {
    bool isPrivate = false,
    bool isGroupPrivate = false,
    String? momentGroupId,
    String? description,
    bool isVideo = false,
    int? videoDuration,
  }) async {
    // Delegate to batch creation with single item
    final moments = await createMomentsBatch(
      [mediaFile],
      title,
      caption,
      locationName,
      latitude,
      longitude,
      photoPrivacyList: [isPrivate],
      isGroupPrivate: isGroupPrivate,
      momentGroupId: momentGroupId,
      description: description,
    );

    if (moments.isEmpty) {
      throw Exception('Failed to create moment: no moment returned');
    }

    return moments.first;
  }

  // Check if file is a video based on extension
  bool _isVideoFile(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    return [
      'mp4',
      'mov',
      'avi',
      'mkv',
      '3gp',
      'm4v',
      'webm',
    ].contains(extension);
  }

  // Create multiple moments in a batch (Atomic DB operation)
  // NOTE: This method now handles both images and videos properly
  Future<List<Moment>> createMomentsBatch(
    List<File> mediaFiles,
    String title,
    String caption,
    String locationName,
    double latitude,
    double longitude, {
    List<bool>? photoPrivacyList, // Per-photo privacy settings
    bool isGroupPrivate = false,
    String? momentGroupId,
    String? description,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 1. Upload all media files first, detecting video vs image per file
      final List<Map<String, dynamic>> mediaDataList = [];

      for (int i = 0; i < mediaFiles.length; i++) {
        final file = mediaFiles[i];
        // Determine individual photo privacy (default to false if not provided)
        final isPhotoPrivate =
            photoPrivacyList != null && i < photoPrivacyList.length
            ? photoPrivacyList[i]
            : false;

        if (_isVideoFile(file)) {
          // Upload as video with thumbnail
          final videoData = await _uploadVideo(file);
          mediaDataList.add({
            'media_path': videoData['videoPath'],
            'media_type': 'video',
            'thumbnail_path': videoData['thumbnailPath'],
            'duration': videoData['duration'],
            'is_private': isPhotoPrivate,
          });
        } else {
          // Upload as image
          final imagePath = await _uploadImage(file);
          mediaDataList.add({
            'media_path': imagePath,
            'media_type': 'image',
            'thumbnail_path': null,
            'duration': null,
            'is_private': isPhotoPrivate,
          });
        }
      }

      // 2. Prepare payload for RPC with full media data (including per-photo privacy)
      final momentsPayload = mediaDataList.map((mediaData) {
        return {
          'title': title,
          'location': locationName,
          'latitude': latitude,
          'longitude': longitude,
          'caption': caption,
          'media_path': mediaData['media_path'],
          'media_type': mediaData['media_type'],
          'thumbnail_path': mediaData['thumbnail_path'],
          'duration': mediaData['duration'],
          'is_private': mediaData['is_private'],
        };
      }).toList();

      // 3. Call RPC with group privacy parameter
      final response = await SupabaseConfig.client.rpc(
        'create_moment_batch',
        params: {
          'p_moments': momentsPayload,
          'p_group_id': momentGroupId,
          'p_group_title': title, // Used if creating new group
          'p_group_lat': latitude,
          'p_group_lng': longitude,
          'p_group_private': isGroupPrivate,
        },
      );

      // 4. Parse response
      final momentsJson = response['moments'] as List;
      return momentsJson
          .map((json) => Moment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Note: If image upload succeeded but RPC failed, we might have orphaned images.
      // Ideally we would track uploaded paths and delete them here in catch block.
      throw Exception('Failed to create moments batch: $e');
    }
  }

  // Update moment
  Future<Moment> updateMoment(String id, Map<String, dynamic> updates) async {
    try {
      final response = await SupabaseConfig.momentsTable
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Moment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update moment: $e');
    }
  }

  // Delete moment
  Future<void> deleteMoment(String id) async {
    try {
      // 1. Get moment details to find media path and group
      final moment = await getMomentById(id);
      if (moment == null) return;

      // 2. Delete main image file from storage
      if (moment.mediaPath != null) {
        await _deleteImage(moment.mediaPath!);
      }

      // 3. Delete the moment from database
      await SupabaseConfig.momentsTable.delete().eq('id', id);

      // 5. Check if group is empty and delete it if so
      if (moment.momentGroupId != null) {
        final groupMoments = await getMomentsByGroup(moment.momentGroupId!);
        if (groupMoments.isEmpty) {
          await SupabaseConfig.client
              .from('moment_groups')
              .delete()
              .eq('id', moment.momentGroupId!);
        }
      }
    } catch (e) {
      throw Exception('Failed to delete moment: $e');
    }
  }

  // Get moments by location (within radius)
  Future<List<Moment>> getMomentsByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    try {
      // Using Supabase PostGIS functions for geospatial queries
      final response = await SupabaseConfig.client.rpc(
        'get_moments_nearby',
        params: {'lat': latitude, 'lng': longitude, 'radius_km': radiusKm},
      );

      return (response as List)
          .map((json) => Moment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to simple query if PostGIS function doesn't exist
      return _getMomentsByLocationFallback(latitude, longitude, radiusKm);
    }
  }

  // Fallback method for location-based queries
  Future<List<Moment>> _getMomentsByLocationFallback(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    final moments = await getMoments();

    return moments.where((moment) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        moment.latitude,
        moment.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  // Upload image to Supabase storage
  Future<String> _uploadImage(File imageFile) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to upload images');
      }

      // Compress image using MediaCompressionService
      final compressedFile = await MediaCompressionService.compressImage(
        imageFile,
      );
      final fileToUpload = compressedFile ?? imageFile;

      final fileName = '${_uuid.v4()}.jpg';
      final filePath = '$userId/$fileName';

      await SupabaseConfig.momentsBucket.upload(
        filePath,
        fileToUpload,
        fileOptions: const supabase_flutter.FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      // Return the storage path, not the URL
      return filePath;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<Map<String, dynamic>> _uploadVideo(File videoFile) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to upload videos');
      }

      // Compress video using MediaCompressionService
      final compressedFile = await MediaCompressionService.compressVideo(
        videoFile,
      );
      final fileToUpload = compressedFile ?? videoFile;

      // Get video duration
      final duration = await MediaCompressionService.getVideoDuration(
        fileToUpload,
      );

      // Generate thumbnail
      final thumbnailFile =
          await MediaCompressionService.generateVideoThumbnail(fileToUpload);

      // Upload video
      final videoFileName = '${_uuid.v4()}.mp4';
      final videoPath = '$userId/$videoFileName';

      await SupabaseConfig.momentsBucket.upload(
        videoPath,
        fileToUpload,
        fileOptions: const supabase_flutter.FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      // Upload thumbnail if generated
      String? thumbnailPath;
      if (thumbnailFile != null) {
        final thumbnailFileName = '${_uuid.v4()}_thumb.jpg';
        thumbnailPath = '$userId/$thumbnailFileName';

        await SupabaseConfig.momentsBucket.upload(
          thumbnailPath,
          thumbnailFile,
          fileOptions: const supabase_flutter.FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );
      }

      return {
        'videoPath': videoPath,
        'thumbnailPath': thumbnailPath,
        'duration': duration,
      };
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  // Delete image from Supabase storage
  Future<void> _deleteImage(String mediaPath) async {
    try {
      // mediaPath is already in the format 'moments/user_id/filename.jpg'
      await SupabaseConfig.momentsBucket.remove([mediaPath]);
    } catch (e) {
      // Don't throw error if image deletion fails
      print('Failed to delete image: $e');
    }
  }

  // Calculate distance between two points in kilometers
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Delete a specific image file from storage
  Future<void> deleteImageFile(String mediaPath) async {
    await _deleteImage(mediaPath);
  }

  // ============================================
  // REALTIME STREAMS
  // ============================================

  /// Get moments by group ID
  Future<List<Moment>> getMomentsByGroup(String groupId) async {
    try {
      final response = await SupabaseConfig.momentsTable
          .select()
          .eq('moment_group_id', groupId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Moment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching group moments: $e');
      return [];
    }
  }

  /// Stream moments by group ID (realtime for moment details page)
  Stream<List<Moment>> streamMomentsByGroup(String groupId) {
    return SupabaseConfig.momentsTable
        .stream(primaryKey: ['id'])
        .eq('moment_group_id', groupId)
        .order('created_at', ascending: false)
        .map(
          (json) => (json as List)
              .map((m) => Moment.fromJson(m as Map<String, dynamic>))
              .toList(),
        )
        .handleError((e) {
          print('Error streaming group moments: $e');
          return <Moment>[];
        });
  }

  /// Stream all moments with true Realtime updates (v2.10.3+)
  /// Uses .stream() which combines initial data + Realtime PostgreSQL changes
  /// No more polling - true push updates from Supabase
  Stream<List<Moment>> streamAllMoments() {
    return SupabaseConfig.momentsTable
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (json) => (json as List)
              .map((m) => Moment.fromJson(m as Map<String, dynamic>))
              .toList(),
        )
        .handleError((e) {
          print('Error streaming moments: $e');
          return <Moment>[];
        });
  }

  /// Stream moments where user is a contributor (for shared moments) via Realtime
  /// Watches moment_contributors table for changes to rebuild list
  Stream<List<Moment>> streamSharedMoments() {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value(<Moment>[]);
    }

    // Watch the moment_contributors table to get updated list of moments
    return SupabaseConfig.client
        .from('moment_contributors')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((contributors) async {
          if (contributors.isEmpty) {
            return <Moment>[];
          }

          final momentIds = (contributors as List)
              .map((c) => c['moment_id'] as String)
              .toList();

          // Fetch the actual moments
          final response = await SupabaseConfig.momentsTable
              .select()
              .inFilter('id', momentIds)
              .order('created_at', ascending: false);

          return (response as List)
              .map((m) => Moment.fromJson(m as Map<String, dynamic>))
              .toList();
        })
        .handleError((e) {
          print('Error streaming shared moments: $e');
          return <Moment>[];
        });
  }
  // ============================================
  // MOMENT GROUPS METHODS
  // ============================================

  /// Get nearby moment groups using PostGIS RPC
  Future<List<MomentGroup>> getNearbyGroups(
    double latitude,
    double longitude, {
    double radiusMeters = 100,
  }) async {
    try {
      // Using Supabase PostGIS RPC for efficient server-side filtering
      final response = await SupabaseConfig.client.rpc(
        'get_nearby_moment_groups',
        params: {
          'lat': latitude,
          'lng': longitude,
          'radius_meters': radiusMeters,
        },
      );

      // RPC returns list of moment_groups rows
      return (response as List)
          .map((json) => MomentGroup.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching nearby groups (RPC): $e');
      // If RPC fails (e.g. not found), fallback to empty list or client-side filtering if you want
      return [];
    }
  }

  /// Create a new moment group
  Future<MomentGroup> createMomentGroup(
    String title,
    double latitude,
    double longitude,
  ) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final groupData = {
        'title': title,
        'center_latitude': latitude,
        'center_longitude': longitude,
        'created_by': userId,
        'is_public': true, // Default to public for now
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseConfig.client
          .from('moment_groups')
          .insert(groupData)
          .select()
          .single();

      return MomentGroup.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create moment group: $e');
    }
  }

  // ============================================
  // MOMENT REACTIONS
  // ============================================

  /// Get all reactions for a moment
  Future<List<MomentReaction>> getReactionsForMoment(String momentId) async {
    try {
      final response = await SupabaseConfig.client
          .from('moment_reactions')
          .select()
          .eq('moment_id', momentId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => MomentReaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reactions: $e');
    }
  }

  /// Get reaction summary for a moment (aggregated counts)
  Future<List<ReactionSummary>> getReactionSummary(String momentId) async {
    try {
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      final reactions = await getReactionsForMoment(momentId);

      // Group reactions by emoji
      final emojiCounts = <String, int>{};
      final userReacted = <String, bool>{};

      for (final reaction in reactions) {
        emojiCounts[reaction.emoji] = (emojiCounts[reaction.emoji] ?? 0) + 1;
        if (reaction.userId == currentUserId) {
          userReacted[reaction.emoji] = true;
        }
      }

      return emojiCounts.entries.map((entry) {
        return ReactionSummary(
          emoji: entry.key,
          count: entry.value,
          userReacted: userReacted[entry.key] ?? false,
        );
      }).toList()..sort(
        (a, b) => b.count.compareTo(a.count),
      ); // Sort by count descending
    } catch (e) {
      throw Exception('Failed to fetch reaction summary: $e');
    }
  }

  /// Add or update a reaction on a moment
  Future<MomentReaction> addReaction(String momentId, String emoji) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Use upsert to handle both new reactions and updates
      // Constraint: moment_reactions_user_moment_unique (moment_id, user_id)
      final response = await SupabaseConfig.client
          .from('moment_reactions')
          .upsert({
            'moment_id': momentId,
            'user_id': userId,
            'emoji': emoji,
            'created_at': DateTime.now().toIso8601String(),
          }, onConflict: 'moment_id,user_id')
          .select()
          .single();

      return MomentReaction.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  /// Remove user's reaction from a moment
  Future<void> removeReaction(String momentId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await SupabaseConfig.client
          .from('moment_reactions')
          .delete()
          .eq('moment_id', momentId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove reaction: $e');
    }
  }

  /// Get current user's reaction on a moment
  Future<MomentReaction?> getUserReaction(String momentId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await SupabaseConfig.client
          .from('moment_reactions')
          .select()
          .eq('moment_id', momentId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return MomentReaction.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Stream reactions for a moment (real-time updates)
  Stream<List<MomentReaction>> watchReactionsForMoment(String momentId) {
    return SupabaseConfig.client
        .from('moment_reactions')
        .stream(primaryKey: ['id'])
        .eq('moment_id', momentId)
        .order('created_at', ascending: true)
        .map(
          (data) => data.map((json) => MomentReaction.fromJson(json)).toList(),
        );
  }

  // ============================================
  // PHOTO REACTIONS (Double-tap heart on photos)
  // ============================================

  /// Get heart count for a moment (photo)
  Future<int> getPhotoHeartCount(String momentId, int photoIndex) async {
    try {
      // photoIndex is now ignored since each photo is its own moment
      final response = await SupabaseConfig.client
          .from('moment_reactions')
          .select('id')
          .eq('moment_id', momentId)
          .eq('emoji', '❤️');

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if user has hearted a moment (photo)
  Future<bool> hasUserHeartedPhoto(String momentId, int photoIndex) async {
    try {
      // photoIndex is now ignored since each photo is its own moment
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await SupabaseConfig.client
          .from('moment_reactions')
          .select('id')
          .eq('moment_id', momentId)
          .eq('user_id', userId)
          .eq('emoji', '❤️')
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Toggle heart on a moment/photo (double-tap behavior)
  /// Returns true if heart was added, false if removed
  Future<bool> togglePhotoHeart(String momentId, int photoIndex) async {
    try {
      // photoIndex is now ignored since each photo is its own moment
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if already hearted
      final existing = await SupabaseConfig.client
          .from('moment_reactions')
          .select('id')
          .eq('moment_id', momentId)
          .eq('user_id', userId)
          .eq('emoji', '❤️')
          .maybeSingle();

      if (existing != null) {
        // Remove heart
        await SupabaseConfig.client
            .from('moment_reactions')
            .delete()
            .eq('id', existing['id']);
        return false;
      } else {
        // Add heart
        await SupabaseConfig.client.from('moment_reactions').insert({
          'moment_id': momentId,
          'user_id': userId,
          'emoji': '❤️',
          'created_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle photo heart: $e');
    }
  }

  // ============================================
  // COLLABORATIVE MOMENTS / CONTRIBUTORS
  // ============================================

  /// Invite a friend to contribute to a moment group
  /// Only the moment owner can invite contributors
  Future<MomentContributor> inviteContributor({
    required String momentId,
    required String friendId,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await SupabaseConfig.client
          .from('moment_contributors')
          .insert({
            'moment_id': momentId,
            'user_id': friendId,
            'role': 'contributor',
            'invited_at': DateTime.now().toIso8601String(),
          })
          .select('*, profiles:user_id(*)')
          .single();

      return MomentContributor.fromJson(response);
    } catch (e) {
      throw Exception('Failed to invite contributor: $e');
    }
  }

  /// Accept an invitation to contribute to a moment
  Future<MomentContributor> acceptInvitation(String contributorId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await SupabaseConfig.client
          .from('moment_contributors')
          .update({'accepted_at': DateTime.now().toIso8601String()})
          .eq('id', contributorId)
          .eq(
            'user_id',
            userId,
          ) // Ensure user can only accept their own invites
          .select('*, profiles:user_id(*)')
          .single();

      return MomentContributor.fromJson(response);
    } catch (e) {
      throw Exception('Failed to accept invitation: $e');
    }
  }

  /// Decline/remove an invitation or leave a collaborative moment
  Future<void> removeContributor(String contributorId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await SupabaseConfig.client
          .from('moment_contributors')
          .delete()
          .eq('id', contributorId);
    } catch (e) {
      throw Exception('Failed to remove contributor: $e');
    }
  }

  /// Get all contributors for a moment (with profile info)
  Future<List<MomentContributor>> getContributors(String momentId) async {
    try {
      final response = await SupabaseConfig.client
          .from('moment_contributors')
          .select('*, profiles:user_id(*)')
          .eq('moment_id', momentId)
          .order('invited_at', ascending: true);

      return (response as List)
          .map(
            (json) => MomentContributor.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get contributors: $e');
    }
  }

  /// Get pending invitations for current user
  Future<List<MomentContributor>> getPendingInvitations() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await SupabaseConfig.client
          .from('moment_contributors')
          .select('*, profiles:user_id(*)')
          .eq('user_id', userId)
          .isFilter('accepted_at', null) // Pending = not yet accepted
          .order('invited_at', ascending: false);

      return (response as List)
          .map(
            (json) => MomentContributor.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending invitations: $e');
    }
  }

  /// Get moments where current user is a contributor (accepted)
  Future<List<Moment>> getSharedMoments() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return [];

      // Get moment IDs where user is an accepted contributor
      final contributorResponse = await SupabaseConfig.client
          .from('moment_contributors')
          .select('moment_id')
          .eq('user_id', userId)
          .not('accepted_at', 'is', null); // Only accepted

      final momentIds = (contributorResponse as List)
          .map((c) => c['moment_id'] as String)
          .toList();

      if (momentIds.isEmpty) return [];

      // Fetch the actual moments
      final momentsResponse = await SupabaseConfig.client
          .from('moments')
          .select()
          .inFilter('id', momentIds)
          .order('created_at', ascending: false);

      return (momentsResponse as List)
          .map((m) => Moment.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get shared moments: $e');
    }
  }

  /// Check if user is a contributor (owner or contributor) to a moment
  Future<MomentContributor?> getUserContribution(String momentId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await SupabaseConfig.client
          .from('moment_contributors')
          .select('*, profiles:user_id(*)')
          .eq('moment_id', momentId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return MomentContributor.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Add current user as owner when creating a moment group
  Future<void> addOwnerAsContributor(String momentId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await SupabaseConfig.client.from('moment_contributors').insert({
        'moment_id': momentId,
        'user_id': userId,
        'role': 'owner',
        'invited_at': DateTime.now().toIso8601String(),
        'accepted_at': DateTime.now()
            .toIso8601String(), // Owner is auto-accepted
      });
    } catch (e) {
      // Ignore duplicate errors (owner already added)
      print('Note: $e');
    }
  }

  /// Stream contributors for real-time updates
  Stream<List<MomentContributor>> watchContributors(String momentId) {
    return SupabaseConfig.client
        .from('moment_contributors')
        .stream(primaryKey: ['id'])
        .eq('moment_id', momentId)
        .order('invited_at', ascending: true)
        .asyncMap((data) async {
          // Fetch profiles for each contributor
          final contributors = <MomentContributor>[];
          for (final json in data) {
            final profileResponse = await SupabaseConfig.client
                .from('profiles')
                .select()
                .eq('id', json['user_id'])
                .maybeSingle();

            final enrichedJson = {...json, 'profiles': profileResponse};
            contributors.add(MomentContributor.fromJson(enrichedJson));
          }
          return contributors;
        });
  }

  /// Stream pending invitations for current user
  Stream<List<MomentContributor>> watchPendingInvitations() {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return SupabaseConfig.client
        .from('moment_contributors')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('invited_at', ascending: false)
        .asyncMap((data) async {
          // Filter to pending only and fetch profiles
          final pending = <MomentContributor>[];
          for (final json in data) {
            if (json['accepted_at'] != null) continue; // Skip accepted

            final profileResponse = await SupabaseConfig.client
                .from('profiles')
                .select()
                .eq('id', json['user_id'])
                .maybeSingle();

            final enrichedJson = {...json, 'profiles': profileResponse};
            pending.add(MomentContributor.fromJson(enrichedJson));
          }
          return pending;
        });
  }
}
