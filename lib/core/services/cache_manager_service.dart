import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moments/core/services/app_logger.dart';
import 'package:moments/core/services/map_cache_service.dart';
import 'package:moments/features/chat/services/media_cache_service.dart';
import 'package:video_compress/video_compress.dart';

final _log = AppLogger('CacheManagerService');

/// Centralized cache management service.
///
/// Aggregates all app caches:
/// - CachedNetworkImage (flutter_cache_manager default)
/// - just_audio LockCachingAudioSource asset cache
/// - Chat media cache (audio, image, video downloads)
/// - Map tile + image cache (FMTC + custom)
/// - Avatar cache (profile images)
/// - Moment media cache (offline media)
/// - Video compression temp files
///
/// Provides size reporting and cleanup across all caches.
class CacheManagerService {
  static final CacheManagerService _instance = CacheManagerService._internal();
  factory CacheManagerService() => _instance;
  CacheManagerService._internal();

  /// Get total cache size across all caches in bytes
  Future<CacheSizeReport> getCacheSizes() async {
    final results = await Future.wait([
      _getCachedNetworkImageSize(),
      _getJustAudioCacheSize(),
      _getChatMediaCacheSize(),
      _getMapCacheSize(),
      _getAvatarCacheSize(),
      _getMomentMediaCacheSize(),
      _getVideoCompressCacheSize(),
      _getTempDirectorySize(),
    ]);

    return CacheSizeReport(
      cachedNetworkImage: results[0],
      justAudioCache: results[1],
      chatMediaCache: results[2],
      mapCache: results[3],
      avatarCache: results[4],
      momentMediaCache: results[5],
      videoCompressCache: results[6],
      tempFiles: results[7],
    );
  }

  /// Clear ALL caches
  Future<void> clearAllCaches() async {
    _log.i('Clearing all caches...');

    await Future.wait([
      _clearCachedNetworkImages(),
      _clearJustAudioCache(),
      _clearChatMediaCache(),
      _clearMapCache(),
      _clearAvatarCache(),
      _clearMomentMediaCache(),
      _clearVideoCompressCache(),
      _clearTempFiles(),
    ]);

    _log.i('All caches cleared');
  }

  /// Clear only audio caches (LockCachingAudioSource + chat audio)
  Future<void> clearAudioCaches() async {
    _log.i('Clearing audio caches...');
    await Future.wait([_clearJustAudioCache(), _clearChatAudioCache()]);
    _log.i('Audio caches cleared');
  }

  /// Clear only image caches (CachedNetworkImage + avatar + moment media)
  Future<void> clearImageCaches() async {
    _log.i('Clearing image caches...');
    await Future.wait([
      _clearCachedNetworkImages(),
      _clearAvatarCache(),
      _clearMomentMediaCache(),
    ]);
    _log.i('Image caches cleared');
  }

  // ─── SIZE CALCULATORS ──────────────────────────────────────────────

  Future<int> _getCachedNetworkImageSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/libCachedImageData');
      if (await imageCacheDir.exists()) {
        return await _directorySize(imageCacheDir);
      }
    } catch (e) {
      _log.e('Error getting CachedNetworkImage size: $e');
    }
    return 0;
  }

  Future<int> _getJustAudioCacheSize() async {
    try {
      // just_audio stores cached audio in app support directory
      final appSupport = await getApplicationSupportDirectory();
      final audioCacheDir = Directory('${appSupport.path}/just_audio_cache');
      if (await audioCacheDir.exists()) {
        return await _directorySize(audioCacheDir);
      }
      // Also check the default asset cache path
      final tempDir = await getTemporaryDirectory();
      final tempAudioCache = Directory('${tempDir.path}/just_audio_cache');
      if (await tempAudioCache.exists()) {
        return await _directorySize(tempAudioCache);
      }
    } catch (e) {
      _log.e('Error getting just_audio cache size: $e');
    }
    return 0;
  }

  Future<int> _getChatMediaCacheSize() async {
    try {
      final service = MediaCacheService();
      return await service.getCacheSize();
    } catch (e) {
      _log.e('Error getting chat media cache size: $e');
    }
    return 0;
  }

  Future<int> _getMapCacheSize() async {
    try {
      final service = MapCacheService();
      final info = await service.getCacheInfo();
      return info['totalSize'] as int? ?? 0;
    } catch (e) {
      _log.e('Error getting map cache size: $e');
    }
    return 0;
  }

  Future<int> _getAvatarCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');
      if (await avatarDir.exists()) {
        return await _directorySize(avatarDir);
      }
    } catch (e) {
      _log.e('Error getting avatar cache size: $e');
    }
    return 0;
  }

  Future<int> _getMomentMediaCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/moment_media');
      if (await mediaDir.exists()) {
        return await _directorySize(mediaDir);
      }
    } catch (e) {
      _log.e('Error getting moment media cache size: $e');
    }
    return 0;
  }

  Future<int> _getVideoCompressCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final compressDir = Directory('${tempDir.path}/video_compress');
      if (await compressDir.exists()) {
        return await _directorySize(compressDir);
      }
    } catch (e) {
      _log.e('Error getting video compress cache size: $e');
    }
    return 0;
  }

  Future<int> _getTempDirectorySize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      return await _directorySize(tempDir);
    } catch (e) {
      _log.e('Error getting temp directory size: $e');
    }
    return 0;
  }

  // ─── CLEAR FUNCTIONS ──────────────────────────────────────────────

  Future<void> _clearCachedNetworkImages() async {
    try {
      await DefaultCacheManager().emptyCache();
      _log.i('CachedNetworkImage cache cleared');
    } catch (e) {
      _log.e('Error clearing CachedNetworkImage cache: $e');
    }
  }

  Future<void> _clearJustAudioCache() async {
    try {
      await AudioPlayer.clearAssetCache();
      _log.i('just_audio asset cache cleared');
    } catch (e) {
      _log.e('Error clearing just_audio cache: $e');
    }
  }

  Future<void> _clearChatMediaCache() async {
    try {
      final service = MediaCacheService();
      await service.clearCache();
      _log.i('Chat media cache cleared');
    } catch (e) {
      _log.e('Error clearing chat media cache: $e');
    }
  }

  Future<void> _clearChatAudioCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final audioCacheDir = Directory('${dir.path}/audio_cache');
      if (await audioCacheDir.exists()) {
        await audioCacheDir.delete(recursive: true);
      }
      _log.i('Chat audio cache cleared');
    } catch (e) {
      _log.e('Error clearing chat audio cache: $e');
    }
  }

  Future<void> _clearMapCache() async {
    try {
      final service = MapCacheService();
      await service.clearCache();
      _log.i('Map cache cleared');
    } catch (e) {
      _log.e('Error clearing map cache: $e');
    }
  }

  Future<void> _clearAvatarCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');
      if (await avatarDir.exists()) {
        await avatarDir.delete(recursive: true);
      }
      _log.i('Avatar cache cleared');
    } catch (e) {
      _log.e('Error clearing avatar cache: $e');
    }
  }

  Future<void> _clearMomentMediaCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/moment_media');
      if (await mediaDir.exists()) {
        await mediaDir.delete(recursive: true);
        await mediaDir.create(recursive: true);
      }
      _log.i('Moment media cache cleared');
    } catch (e) {
      _log.e('Error clearing moment media cache: $e');
    }
  }

  Future<void> _clearVideoCompressCache() async {
    try {
      await VideoCompress.deleteAllCache();
      _log.i('Video compress cache cleared');
    } catch (e) {
      _log.e('Error clearing video compress cache: $e');
    }
  }

  Future<void> _clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (_) {
            // Some temp files may be locked, skip them
          }
        }
      }
      _log.i('Temp files cleared');
    } catch (e) {
      _log.e('Error clearing temp files: $e');
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────

  Future<int> _directorySize(Directory dir) async {
    int size = 0;
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      _log.e('Error calculating directory size: $e');
    }
    return size;
  }
}

/// Report of cache sizes across all app caches
class CacheSizeReport {
  final int cachedNetworkImage;
  final int justAudioCache;
  final int chatMediaCache;
  final int mapCache;
  final int avatarCache;
  final int momentMediaCache;
  final int videoCompressCache;
  final int tempFiles;

  const CacheSizeReport({
    required this.cachedNetworkImage,
    required this.justAudioCache,
    required this.chatMediaCache,
    required this.mapCache,
    required this.avatarCache,
    required this.momentMediaCache,
    required this.videoCompressCache,
    required this.tempFiles,
  });

  int get totalBytes =>
      cachedNetworkImage +
      justAudioCache +
      chatMediaCache +
      mapCache +
      avatarCache +
      momentMediaCache +
      videoCompressCache;
  // Note: tempFiles overlap with some caches, excluded from total

  String get formattedTotal => formatBytes(totalBytes);

  Map<String, String> get breakdown => {
    'Images (CachedNetworkImage)': formatBytes(cachedNetworkImage),
    'Audio (just_audio)': formatBytes(justAudioCache),
    'Chat media': formatBytes(chatMediaCache),
    'Map tiles & images': formatBytes(mapCache),
    'Avatars': formatBytes(avatarCache),
    'Moment media': formatBytes(momentMediaCache),
    'Video compression': formatBytes(videoCompressCache),
  };

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
