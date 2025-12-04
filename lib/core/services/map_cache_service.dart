import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import '../../data/sources/supabase_config.dart';

class MapCacheService {
  static const String _tileCacheDir = 'mapbox_tiles';
  static const String _imageCacheDir = 'moment_images';
  static const String _fmtcStoreName = 'momentsMapTiles';
  static const int _maxCacheAge = 7; // days
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Singleton pattern
  static final MapCacheService _instance = MapCacheService._internal();
  factory MapCacheService() => _instance;
  MapCacheService._internal();

  late Directory _cacheDir;
  late Directory _tileDir;
  late Directory _imageDir;
  bool _isInitialized = false;
  bool _fmtcInitialized = false;
  FMTCTileProvider? _tileProvider;

  /// Gets the FMTC tile provider for flutter_map TileLayer.
  /// Returns null if FMTC hasn't been initialized yet.
  FMTCTileProvider? get tileProvider => _tileProvider;

  /// Whether the tile caching system is ready.
  bool get isTileCachingReady => _fmtcInitialized && _tileProvider != null;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final tempDir = await getTemporaryDirectory();
      _cacheDir = Directory('${tempDir.path}/mapbox_cache');
      _tileDir = Directory('${_cacheDir.path}/$_tileCacheDir');
      _imageDir = Directory('${_cacheDir.path}/$_imageCacheDir');

      // Create directories if they don't exist
      await _cacheDir.create(recursive: true);
      await _tileDir.create(recursive: true);
      await _imageDir.create(recursive: true);

      _isInitialized = true;

      // Initialize FMTC for tile caching
      await _initializeFMTC();

      // Clean up old cache entries
      await _cleanupOldCache();
    } catch (e) {
      print('Error initializing map cache: $e');
    }
  }

  /// Initialize Flutter Map Tile Caching (FMTC) for efficient tile storage.
  Future<void> _initializeFMTC() async {
    if (_fmtcInitialized) return;

    try {
      // Initialize the ObjectBox backend for FMTC
      await FMTCObjectBoxBackend().initialise();

      // Create the map tile store if it doesn't exist
      final store = FMTCStore(_fmtcStoreName);
      await store.manage.create();

      // Create the tile provider with browse caching strategy:
      // - readUpdateCreate: reads from cache, updates existing tiles, creates new cached tiles
      _tileProvider = FMTCTileProvider(
        stores: const {_fmtcStoreName: BrowseStoreStrategy.readUpdateCreate},
      );

      _fmtcInitialized = true;
      print('FMTC tile caching initialized successfully');
    } catch (e) {
      print('FMTC initialization failed (map will work without caching): $e');
      _fmtcInitialized = false;
    }
  }

  /// Get statistics about the tile cache.
  Future<Map<String, dynamic>> getTileCacheStats() async {
    if (!_fmtcInitialized) {
      return {'initialized': false};
    }

    try {
      final store = FMTCStore(_fmtcStoreName);
      final stats = await store.stats.all;

      return {
        'initialized': true,
        'storeName': _fmtcStoreName,
        'tileCount': stats.length,
        'sizeKB': stats.size / 1024,
        'sizeMB': stats.size / (1024 * 1024),
        'hits': stats.hits,
        'misses': stats.misses,
      };
    } catch (e) {
      return {'initialized': true, 'error': e.toString()};
    }
  }

  /// Clear only the tile cache (not moment images).
  Future<void> clearTileCache() async {
    if (!_fmtcInitialized) return;

    try {
      final store = FMTCStore(_fmtcStoreName);
      await store.manage.reset();
      print('Tile cache cleared');
    } catch (e) {
      print('Failed to clear tile cache: $e');
    }
  }

  /// Cache moment image for offline viewing
  Future<String?> cacheImage(String imageUrl) async {
    await initialize();

    try {
      final imageHash = _generateHash(imageUrl);
      final cachedFile = File('${_imageDir.path}/$imageHash.jpg');

      // Return cached file if it exists and is not too old
      if (await cachedFile.exists()) {
        final stat = await cachedFile.stat();
        final age = DateTime.now().difference(stat.modified).inDays;

        if (age < _maxCacheAge) {
          return cachedFile.path;
        } else {
          await cachedFile.delete();
        }
      }

      // Download and cache the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await cachedFile.writeAsBytes(response.bodyBytes);
        return cachedFile.path;
      }
    } catch (e) {
      print('Error caching image: $e');
    }

    return null;
  }

  /// Get cached image path if available
  Future<String?> getCachedImagePath(String imageUrl) async {
    await initialize();

    try {
      final imageHash = _generateHash(imageUrl);
      final cachedFile = File('${_imageDir.path}/$imageHash.jpg');

      if (await cachedFile.exists()) {
        final stat = await cachedFile.stat();
        final age = DateTime.now().difference(stat.modified).inDays;

        if (age < _maxCacheAge) {
          return cachedFile.path;
        } else {
          await cachedFile.delete();
        }
      }
    } catch (e) {
      print('Error getting cached image: $e');
    }

    return null;
  }

  /// Cache multiple images in batch
  Future<Map<String, String>> cacheImagesBatch(List<String> imageUrls) async {
    await initialize();

    final results = <String, String>{};
    final futures = imageUrls.map((url) async {
      final cachedPath = await cacheImage(url);
      if (cachedPath != null) {
        results[url] = cachedPath;
      }
    });

    await Future.wait(futures);
    return results;
  }

  /// Preload images for a list of moments
  Future<void> preloadMomentImages(List<dynamic> moments) async {
    final imageUrls = <String>[];

    for (var moment in moments) {
      if (moment is Map<String, dynamic>) {
        final mediaPath = moment['media_path'] as String?;
        final directUrl = moment['image_url'] as String?;

        if (mediaPath != null && mediaPath.isNotEmpty) {
          try {
            final signedUrl = await SupabaseConfig.momentsBucket
                .createSignedUrl(mediaPath, 60 * 60);
            imageUrls.add(signedUrl);
            continue;
          } catch (e) {
            print('Failed to create signed URL for cache: $e');
          }
        }

        if (directUrl != null && directUrl.isNotEmpty) {
          imageUrls.add(directUrl);
        }
      }
    }

    if (imageUrls.isNotEmpty) {
      print('Preloading ${imageUrls.length} moment images...');
      await cacheImagesBatch(imageUrls);
      print('Preloading complete');
    }
  }

  /// Get cache size information
  Future<Map<String, dynamic>> getCacheInfo() async {
    await initialize();

    try {
      int tileSize = 0;
      int imageSize = 0;
      int tileCount = 0;
      int imageCount = 0;

      // Calculate tile cache size
      if (await _tileDir.exists()) {
        await for (var entity in _tileDir.list(recursive: true)) {
          if (entity is File) {
            tileSize += await entity.length();
            tileCount++;
          }
        }
      }

      // Calculate image cache size
      if (await _imageDir.exists()) {
        await for (var entity in _imageDir.list(recursive: true)) {
          if (entity is File) {
            imageSize += await entity.length();
            imageCount++;
          }
        }
      }

      return {
        'totalSize': tileSize + imageSize,
        'tileSize': tileSize,
        'imageSize': imageSize,
        'tileCount': tileCount,
        'imageCount': imageCount,
        'tileSizeMB': (tileSize / (1024 * 1024)).toStringAsFixed(2),
        'imageSizeMB': (imageSize / (1024 * 1024)).toStringAsFixed(2),
        'totalSizeMB': ((tileSize + imageSize) / (1024 * 1024)).toStringAsFixed(
          2,
        ),
      };
    } catch (e) {
      print('Error getting cache info: $e');
      return {};
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await initialize();

    try {
      // Clear cached files
      if (await _cacheDir.exists()) {
        await _cacheDir.delete(recursive: true);
        await _cacheDir.create(recursive: true);
        await _tileDir.create(recursive: true);
        await _imageDir.create(recursive: true);
      }

      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
      throw Exception('Failed to clear cache: $e');
    }
  }

  /// Clean up old cache entries
  Future<void> _cleanupOldCache() async {
    try {
      // Clean up old image files
      if (await _imageDir.exists()) {
        await for (var entity in _imageDir.list()) {
          if (entity is File) {
            final stat = await entity.stat();
            final age = DateTime.now().difference(stat.modified).inDays;

            if (age > _maxCacheAge) {
              await entity.delete();
            }
          }
        }
      }

      // Check total cache size and clean up if needed
      final cacheInfo = await getCacheInfo();
      final totalSize = cacheInfo['totalSize'] as int? ?? 0;

      if (totalSize > _maxCacheSize) {
        await _cleanupLargestFiles();
      }
    } catch (e) {
      print('Error during cache cleanup: $e');
    }
  }

  /// Clean up largest files when cache exceeds limit
  Future<void> _cleanupLargestFiles() async {
    try {
      final files = <File>[];

      // Collect all cached files
      if (await _imageDir.exists()) {
        await for (var entity in _imageDir.list()) {
          if (entity is File) {
            files.add(entity);
          }
        }
      }

      // Sort by modification time (oldest first)
      files.sort((a, b) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      });

      // Delete oldest files until we're under the limit
      int currentSize = (await getCacheInfo())['totalSize'] as int? ?? 0;

      for (var file in files) {
        if (currentSize <= _maxCacheSize * 0.8) break; // Keep 20% buffer

        final fileSize = await file.length();
        await file.delete();
        currentSize -= fileSize;
      }
    } catch (e) {
      print('Error during large file cleanup: $e');
    }
  }

  /// Generate hash for cache keys
  String _generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
}
