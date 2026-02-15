import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moments/core/services/app_logger.dart';

final _log = AppLogger('GarbageCollectionService');

/// Automatic local garbage collection service.
///
/// Runs on app startup (non-blocking) to evict stale caches
/// and prevent unbounded storage growth.
///
/// Configurable limits per cache category.
class GarbageCollectionService {
  static final GarbageCollectionService _instance =
      GarbageCollectionService._internal();
  factory GarbageCollectionService() => _instance;
  GarbageCollectionService._internal();

  // ─── SIZE LIMITS ──────────────────────────────────────────────────

  /// Max size for CachedNetworkImage cache (200 MB)
  static const int _maxImageCacheBytes = 200 * 1024 * 1024;

  /// Max size for just_audio LockCachingAudioSource cache (100 MB)
  static const int _maxAudioCacheBytes = 100 * 1024 * 1024;

  /// Max size for chat media cache (300 MB)
  static const int _maxChatMediaCacheBytes = 300 * 1024 * 1024;

  /// Max size for moment media cache (300 MB)
  static const int _maxMomentMediaCacheBytes = 300 * 1024 * 1024;

  /// Max age for cached files (30 days)
  static const int _maxCacheAgeDays = 30;

  /// Run garbage collection (non-blocking, fire-and-forget)
  Future<void> runGC() async {
    try {
      _log.i('Starting garbage collection...');
      final stopwatch = Stopwatch()..start();

      await Future.wait([
        _gcCachedNetworkImages(),
        _gcJustAudioCache(),
        _gcChatMediaCache(),
        _gcMomentMediaCache(),
        _gcVideoCompressCache(),
      ]);

      stopwatch.stop();
      _log.i(
        'Garbage collection completed in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      _log.e('Garbage collection failed: $e');
    }
  }

  // ─── CACHED NETWORK IMAGES ────────────────────────────────────────

  Future<void> _gcCachedNetworkImages() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final imageCacheDir = Directory('${cacheDir.path}/libCachedImageData');
      if (!await imageCacheDir.exists()) return;

      final size = await _directorySize(imageCacheDir);
      if (size > _maxImageCacheBytes) {
        _log.i('Image cache ${_formatBytes(size)} exceeds limit, cleaning...');
        // flutter_cache_manager handles its own eviction, but we can
        // force a cleanup of stale entries
        await DefaultCacheManager().emptyCache();
        _log.i('Image cache cleared');
      } else {
        // Just remove old files
        await _evictOldFiles(imageCacheDir, _maxCacheAgeDays);
      }
    } catch (e) {
      _log.e('Error in image cache GC: $e');
    }
  }

  // ─── JUST AUDIO CACHE ─────────────────────────────────────────────

  Future<void> _gcJustAudioCache() async {
    try {
      // Check both possible locations for just_audio cache
      final dirs = <Directory>[];

      final appSupport = await getApplicationSupportDirectory();
      dirs.add(Directory('${appSupport.path}/just_audio_cache'));

      final tempDir = await getTemporaryDirectory();
      dirs.add(Directory('${tempDir.path}/just_audio_cache'));

      int totalSize = 0;
      for (final dir in dirs) {
        if (await dir.exists()) {
          totalSize += await _directorySize(dir);
        }
      }

      if (totalSize > _maxAudioCacheBytes) {
        _log.i(
          'Audio cache ${_formatBytes(totalSize)} exceeds limit, clearing...',
        );
        await AudioPlayer.clearAssetCache();
        _log.i('just_audio cache cleared');
      } else {
        // Evict only old files
        for (final dir in dirs) {
          if (await dir.exists()) {
            await _evictOldFiles(dir, _maxCacheAgeDays);
          }
        }
      }
    } catch (e) {
      _log.e('Error in audio cache GC: $e');
    }
  }

  // ─── CHAT MEDIA CACHE ─────────────────────────────────────────────

  Future<void> _gcChatMediaCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDirs = [
        Directory('${dir.path}/audio_cache'),
        Directory('${dir.path}/image_cache'),
        Directory('${dir.path}/video_cache'),
      ];

      int totalSize = 0;
      for (final cacheDir in cacheDirs) {
        if (await cacheDir.exists()) {
          totalSize += await _directorySize(cacheDir);
        }
      }

      if (totalSize > _maxChatMediaCacheBytes) {
        _log.i(
          'Chat media cache ${_formatBytes(totalSize)} exceeds limit, evicting old files...',
        );
        for (final cacheDir in cacheDirs) {
          if (await cacheDir.exists()) {
            await _evictOldFilesUntilUnder(
              cacheDir,
              _maxChatMediaCacheBytes ~/ 3,
            );
          }
        }
      } else {
        for (final cacheDir in cacheDirs) {
          if (await cacheDir.exists()) {
            await _evictOldFiles(cacheDir, _maxCacheAgeDays);
          }
        }
      }
    } catch (e) {
      _log.e('Error in chat media cache GC: $e');
    }
  }

  // ─── MOMENT MEDIA CACHE ───────────────────────────────────────────

  Future<void> _gcMomentMediaCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/moment_media');
      if (!await mediaDir.exists()) return;

      final size = await _directorySize(mediaDir);
      if (size > _maxMomentMediaCacheBytes) {
        _log.i(
          'Moment media cache ${_formatBytes(size)} exceeds limit, evicting...',
        );
        await _evictOldFilesUntilUnder(mediaDir, _maxMomentMediaCacheBytes);
      } else {
        await _evictOldFiles(mediaDir, _maxCacheAgeDays);
      }
    } catch (e) {
      _log.e('Error in moment media cache GC: $e');
    }
  }

  // ─── VIDEO COMPRESS CACHE ─────────────────────────────────────────

  Future<void> _gcVideoCompressCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final compressDir = Directory('${tempDir.path}/video_compress');
      if (!await compressDir.exists()) return;

      // Always clean temp compression files older than 1 day
      await _evictOldFiles(compressDir, 1);
    } catch (e) {
      _log.e('Error in video compress cache GC: $e');
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────

  /// Delete files older than [maxAgeDays]
  Future<int> _evictOldFiles(Directory dir, int maxAgeDays) async {
    int deleted = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = DateTime.now().difference(stat.modified).inDays;
          if (age > maxAgeDays) {
            await entity.delete();
            deleted++;
          }
        }
      }
      if (deleted > 0) {
        _log.d(
          'Evicted $deleted files older than $maxAgeDays days from ${dir.path}',
        );
      }
    } catch (e) {
      _log.e('Error evicting old files: $e');
    }
    return deleted;
  }

  /// Delete oldest files until directory is under [maxBytes]
  Future<void> _evictOldFilesUntilUnder(Directory dir, int maxBytes) async {
    try {
      final files = <File>[];
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) files.add(entity);
      }

      // Sort by modification time (oldest first)
      files.sort((a, b) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      });

      int currentSize = await _directorySize(dir);
      int deleted = 0;

      for (final file in files) {
        if (currentSize <= maxBytes * 0.8) break; // 20% buffer
        final fileSize = await file.length();
        await file.delete();
        currentSize -= fileSize;
        deleted++;
      }

      if (deleted > 0) {
        _log.i(
          'Evicted $deleted files to bring cache under ${_formatBytes(maxBytes)}',
        );
      }
    } catch (e) {
      _log.e('Error evicting files: $e');
    }
  }

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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
