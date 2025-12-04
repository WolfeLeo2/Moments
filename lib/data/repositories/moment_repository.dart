import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import '../models/moment.dart';

import '../models/moment_group.dart';
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

  // Create new moment
  Future<Moment> createMoment(
    File mediaFile,
    String title,
    String caption,
    String locationName,
    double latitude,
    double longitude, {
    bool isPrivate = false,
    String? momentGroupId,
    String? description,
    bool isVideo = false,
    int? videoDuration,
  }) async {
    try {
      // Get current user ID
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      String mediaPath;
      String? thumbnailPath;
      int? duration;
      String mediaType;

      if (isVideo) {
        // Handle video upload
        final result = await _uploadVideo(mediaFile);
        mediaPath = result['videoPath']!;
        thumbnailPath = result['thumbnailPath'];
        duration = result['duration'] as int?;
        mediaType = 'video';
      } else {
        // Handle image upload
        mediaPath = await _uploadImage(mediaFile);
        mediaType = 'image';
      }

      // 2. Create the moment entry
      final momentData = {
        'user_id': userId,
        'title': title,
        'location': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'caption': caption,
        'description': null,
        'timestamp': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'is_private': isPrivate,
        'moment_group_id': momentGroupId,
        'is_locked': false,
        'media_path': mediaPath,
        'media_type': mediaType,
        'duration': duration,
        'thumbnail_path': thumbnailPath,
      };

      final response = await SupabaseConfig.momentsTable
          .insert(momentData)
          .select()
          .single();

      final moment = Moment.fromJson(response);

      // If this moment is part of a group, ensure the group exists and is updated
      if (moment.momentGroupId != null) {
        // The original instruction had a placeholder for _supabase, but it should be SupabaseConfig.client
        await _ensureGroupExists(
          moment.momentGroupId!,
          title,
          latitude,
          longitude,
        );
      } else {
        // If no group ID provided, check if we should create one or add to nearby?
        // For now, we assume the caller handles group creation/assignment
        // or we auto-group based on location (future enhancement)
      }

      return moment;
    } catch (e) {
      throw Exception('Failed to create moment: $e');
    }
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
    bool isPrivate = false,
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

      for (final file in mediaFiles) {
        if (_isVideoFile(file)) {
          // Upload as video with thumbnail
          final videoData = await _uploadVideo(file);
          mediaDataList.add({
            'media_path': videoData['videoPath'],
            'media_type': 'video',
            'thumbnail_path': videoData['thumbnailPath'],
            'duration': videoData['duration'],
          });
        } else {
          // Upload as image
          final imagePath = await _uploadImage(file);
          mediaDataList.add({
            'media_path': imagePath,
            'media_type': 'image',
            'thumbnail_path': null,
            'duration': null,
          });
        }
      }

      // 2. Prepare payload for RPC with full media data
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
          'is_private': isPrivate,
        };
      }).toList();

      // 3. Call RPC
      final response = await SupabaseConfig.client.rpc(
        'create_moment_batch',
        params: {
          'p_moments': momentsPayload,
          'p_group_id': momentGroupId,
          'p_group_title': title, // Used if creating new group
          'p_group_lat': latitude,
          'p_group_lng': longitude,
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

  Future<void> _ensureGroupExists(
    String groupId,
    String title,
    double lat,
    double lng,
  ) async {
    // Check if group exists
    final group = await SupabaseConfig.client
        .from('moment_groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();

    if (group == null) {
      // Create group if it doesn't exist (though it should usually exist by now)
      // Assuming createMomentGroup is a method in this class or accessible
      // For now, this part is commented out as createMomentGroup is not provided in the snippet
      // await createMomentGroup(title, lat, lng);
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

  /// Get nearby moment groups
  Future<List<MomentGroup>> getNearbyGroups(
    double latitude,
    double longitude, {
    double radiusMeters = 100,
  }) async {
    try {
      // Using Supabase PostGIS functions for geospatial queries if available
      // Or simple lat/lng filtering
      final response = await SupabaseConfig.client
          .from('moment_groups')
          .select()
          .order('created_at', ascending: false);

      final allGroups = (response as List)
          .map((json) => MomentGroup.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter by distance
      return allGroups.where((group) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          group.latitude,
          group.longitude,
        );
        return distance * 1000 <= radiusMeters; // Convert km to meters
      }).toList();
    } catch (e) {
      print('Error fetching nearby groups: $e');
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
}
