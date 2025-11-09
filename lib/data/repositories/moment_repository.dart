import 'dart:io';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import '../models/moment.dart';
import '../models/moment_image.dart';
import '../sources/supabase_config.dart';

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

      return Moment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch moment: $e');
    }
  }

  // Create new moment
  Future<Moment> createMoment({
    required String title,
    required String location,
    required double latitude,
    required double longitude,
    File? imageFile,
    String? description,
    String? caption, // User's personal caption
  }) async {
    try {
      // Get current user ID
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      String? imageUrl;
      String? mediaPath;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile);
        // Extract the path from the URL (everything after /moments/)
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        final momentsIndex = pathSegments.indexOf('moments');
        if (momentsIndex >= 0 && momentsIndex < pathSegments.length - 1) {
          mediaPath = pathSegments.sublist(momentsIndex).join('/');
        }
      }

      // media_path is required, so we must have an image
      if (mediaPath == null) {
        throw Exception('Image is required to create a moment');
      }

      final momentData = {
        'user_id': userId, // Add user_id for RLS policy
        'title': title,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'media_path': mediaPath, // Required field
        'image_url': imageUrl,
        'caption': caption, // Personal caption like "Midtown Manhattan"
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseConfig.momentsTable
          .insert(momentData)
          .select()
          .single();

      return Moment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create moment: $e');
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

      return Moment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update moment: $e');
    }
  }

  // Delete moment
  Future<void> deleteMoment(String id) async {
    try {
      // Get moment to delete image if exists
      final moment = await getMomentById(id);

      if (moment?.imageUrl != null) {
        await _deleteImage(moment!.imageUrl!);
      }

      await SupabaseConfig.momentsTable.delete().eq('id', id);
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
      final fileName = '${_uuid.v4()}.jpg';
      final filePath = 'moments/$fileName';

      await SupabaseConfig.momentsBucket.upload(
        filePath,
        imageFile,
        fileOptions: const supabase_flutter.FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      final publicUrl = SupabaseConfig.momentsBucket.getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete image from Supabase storage
  Future<void> _deleteImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;
      final filePath = 'moments/$fileName';

      await SupabaseConfig.momentsBucket.remove([filePath]);
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

  // ==================== MOMENT IMAGES METHODS ====================

  /// Upload multiple images for a moment
  Future<List<MomentImage>> uploadMomentImages({
    required String momentId,
    required List<File> imageFiles,
    List<String?>? captions,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final List<MomentImage> uploadedImages = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        final caption = captions != null && i < captions.length
            ? captions[i]
            : null;

        // Upload image to storage
        final imageUrl = await _uploadImage(imageFile);

        // Extract media_path from URL
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        final momentsIndex = pathSegments.indexOf('moments');
        String mediaPath = '';
        if (momentsIndex >= 0 && momentsIndex < pathSegments.length - 1) {
          mediaPath = pathSegments.sublist(momentsIndex).join('/');
        }

        // Insert into moment_images table
        final imageData = {
          'moment_id': momentId,
          'image_url': imageUrl,
          'media_path': mediaPath,
          'caption': caption,
          'display_order': i,
          'created_at': DateTime.now().toIso8601String(),
        };

        final response = await SupabaseConfig.client
            .from('moment_images')
            .insert(imageData)
            .select()
            .single();

        uploadedImages.add(MomentImage.fromJson(response));
      }

      return uploadedImages;
    } catch (e) {
      throw Exception('Failed to upload moment images: $e');
    }
  }

  /// Get all images for a moment
  Future<List<MomentImage>> getMomentImages(String momentId) async {
    try {
      final response = await SupabaseConfig.client
          .from('moment_images')
          .select()
          .eq('moment_id', momentId)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => MomentImage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch moment images: $e');
    }
  }

  /// Delete a moment image
  Future<void> deleteMomentImage(String imageId) async {
    try {
      // Get image details first to delete from storage
      final response = await SupabaseConfig.client
          .from('moment_images')
          .select()
          .eq('id', imageId)
          .maybeSingle();

      if (response != null) {
        final imageUrl = response['image_url'] as String;
        await _deleteImage(imageUrl);
      }

      await SupabaseConfig.client
          .from('moment_images')
          .delete()
          .eq('id', imageId);
    } catch (e) {
      throw Exception('Failed to delete moment image: $e');
    }
  }
}
