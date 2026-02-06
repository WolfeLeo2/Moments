import 'package:moments/core/services/app_logger.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';

final _log = AppLogger('MediaCompressionService');

class MediaCompressionService {
  /// Compress image to JPG with 70% quality
  static Future<File?> compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastDotIndex = filePath.lastIndexOf('.');

      if (lastDotIndex == -1) {
        return file;
      }

      final splitted = filePath.substring(0, lastDotIndex);

      // Always compress to JPG
      final outPath = '${splitted}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        return file;
      }

      return File(result.path);
    } catch (e) {
      _log.e('Error compressing image: $e');
      return file;
    }
  }

  /// Compress video to MP4 with medium quality, max 50MB
  static Future<File?> compressVideo(File file) async {
    try {
      // Check file size
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      _log.i('Original video size: ${fileSizeMB.toStringAsFixed(2)} MB');

      // Compress video
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality, // ~70% quality equivalent
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info == null || info.file == null) {
        _log.e('Video compression returned null');
        return file;
      }

      final compressedSize = await info.file!.length();
      final compressedSizeMB = compressedSize / (1024 * 1024);

      _log.i(
        'Compressed video size: ${compressedSizeMB.toStringAsFixed(2)} MB',
      );

      // Check if compressed file is under 50MB
      if (compressedSizeMB > 50) {
        throw Exception(
          'Video too large: ${compressedSizeMB.toStringAsFixed(1)}MB. Max is 50MB.',
        );
      }

      return info.file;
    } catch (e) {
      _log.e('Error compressing video: $e');
      rethrow;
    }
  }

  /// Generate thumbnail from video
  static Future<File?> generateVideoThumbnail(File videoFile) async {
    try {
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: 70,
        position: -1, // Get thumbnail from middle of video
      );

      return thumbnailFile;
    } catch (e) {
      _log.e('Error generating video thumbnail: $e');
      return null;
    }
  }

  /// Get video duration in seconds
  static Future<int> getVideoDuration(File videoFile) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoFile.path);
      if (info.duration != null) {
        return (info.duration! / 1000).round(); // Convert ms to seconds
      }
      return 0;
    } catch (e) {
      _log.e('Error getting video duration: $e');
      return 0;
    }
  }

  /// Cancel any ongoing video compression
  static void cancelCompression() {
    VideoCompress.cancelCompression();
  }

  /// Clean up resources
  static void dispose() {
    VideoCompress.deleteAllCache();
  }
}
