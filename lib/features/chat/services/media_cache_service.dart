import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:moments/core/services/app_logger.dart';


final _log = AppLogger('MediaCache');
/// Service to cache downloaded media files (audio, images, videos)
/// and expensive-to-compute data like audio waveforms.
class MediaCacheService {
  // In-memory cache of file paths
  final Map<String, String> _filePathCache = {};

  // In-memory cache of audio waveform data
  final Map<String, List<double>> _waveformCache = {};

  // Lock to prevent concurrent downloads of the same file
  final Map<String, Future<String>> _downloadLocks = {};

  /// Get or download an audio file
  /// Returns the local file path
  Future<String> getAudioFile(String messageId, String url) async {
    // Check memory cache first
    if (_filePathCache.containsKey(messageId)) {
      final cachedPath = _filePathCache[messageId]!;
      if (await File(cachedPath).exists()) {
        return cachedPath;
      } else {
        // File was deleted, remove from cache
        _filePathCache.remove(messageId);
      }
    }

    // Check if already downloading
    if (_downloadLocks.containsKey(messageId)) {
      return await _downloadLocks[messageId]!;
    }

    // Start download
    final downloadFuture = _downloadAudioFile(messageId, url);
    _downloadLocks[messageId] = downloadFuture;

    try {
      final path = await downloadFuture;
      _filePathCache[messageId] = path;
      return path;
    } finally {
      _downloadLocks.remove(messageId);
    }
  }

  /// Get or download an image file
  /// Returns the local file path
  Future<String> getImageFile(String messageId, String url) async {
    // Check memory cache first
    if (_filePathCache.containsKey(messageId)) {
      final cachedPath = _filePathCache[messageId]!;
      if (await File(cachedPath).exists()) {
        return cachedPath;
      } else {
        _filePathCache.remove(messageId);
      }
    }

    // Check if already downloading
    if (_downloadLocks.containsKey(messageId)) {
      return await _downloadLocks[messageId]!;
    }

    // Start download
    final downloadFuture = _downloadImageFile(messageId, url);
    _downloadLocks[messageId] = downloadFuture;

    try {
      final path = await downloadFuture;
      _filePathCache[messageId] = path;
      return path;
    } finally {
      _downloadLocks.remove(messageId);
    }
  }

  /// Get or download a video file
  /// Returns the local file path
  Future<String> getVideoFile(String messageId, String url) async {
    // Check memory cache first
    if (_filePathCache.containsKey(messageId)) {
      final cachedPath = _filePathCache[messageId]!;
      if (await File(cachedPath).exists()) {
        return cachedPath;
      } else {
        _filePathCache.remove(messageId);
      }
    }

    // Check if already downloading
    if (_downloadLocks.containsKey(messageId)) {
      return await _downloadLocks[messageId]!;
    }

    // Start download
    final downloadFuture = _downloadVideoFile(messageId, url);
    _downloadLocks[messageId] = downloadFuture;

    try {
      final path = await downloadFuture;
      _filePathCache[messageId] = path;
      return path;
    } finally {
      _downloadLocks.remove(messageId);
    }
  }

  /// Get or extract audio waveform data
  /// Returns waveform data for visualization
  ///
  /// Waveform extraction is now handled by PlayerService using WaveformExtractionController.
  /// This method is deprecated and will be removed.
  @Deprecated('Use PlayerService.getWaveformData instead')
  Future<List<double>?> getWaveformData(
    String messageId,
    String audioFilePath,
  ) async {
    _log.d(
      'MediaCacheService: getWaveformData is deprecated - use PlayerService.getWaveformData instead',
    );
    return null;
  }

  Future<String> _downloadAudioFile(String messageId, String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/audio_cache/$messageId.m4a');

    // Create directory if it doesn't exist
    await file.parent.create(recursive: true);

    if (await file.exists()) {
      return file.path;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } else {
      throw Exception('Failed to download audio: ${response.statusCode}');
    }
  }

  Future<String> _downloadImageFile(String messageId, String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final extension = _getFileExtension(url);
    final file = File('${dir.path}/image_cache/$messageId$extension');

    // Create directory if it doesn't exist
    await file.parent.create(recursive: true);

    if (await file.exists()) {
      return file.path;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } else {
      throw Exception('Failed to download image: ${response.statusCode}');
    }
  }

  Future<String> _downloadVideoFile(String messageId, String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final extension = _getFileExtension(url);
    final file = File('${dir.path}/video_cache/$messageId$extension');

    // Create directory if it doesn't exist
    await file.parent.create(recursive: true);

    if (await file.exists()) {
      return file.path;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } else {
      throw Exception('Failed to download video: ${response.statusCode}');
    }
  }

  String _getFileExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot != -1) {
      return path.substring(lastDot);
    }
    return '.jpg'; // Default extension
  }

  /// Clear all cached files and data
  Future<void> clearCache() async {
    _filePathCache.clear();
    _waveformCache.clear();

    final dir = await getApplicationDocumentsDirectory();
    final audioCacheDir = Directory('${dir.path}/audio_cache');
    final imageCacheDir = Directory('${dir.path}/image_cache');
    final videoCacheDir = Directory('${dir.path}/video_cache');

    if (await audioCacheDir.exists()) {
      await audioCacheDir.delete(recursive: true);
    }
    if (await imageCacheDir.exists()) {
      await imageCacheDir.delete(recursive: true);
    }
    if (await videoCacheDir.exists()) {
      await videoCacheDir.delete(recursive: true);
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    int totalSize = 0;
    final dir = await getApplicationDocumentsDirectory();

    final cacheDirs = [
      Directory('${dir.path}/audio_cache'),
      Directory('${dir.path}/image_cache'),
      Directory('${dir.path}/video_cache'),
    ];

    for (final cacheDir in cacheDirs) {
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    }

    return totalSize;
  }
}
