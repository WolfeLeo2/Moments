import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moments/core/services/app_logger.dart';

final _log = AppLogger('AvatarCache');

/// Centralized avatar caching service
/// Provides in-memory cache with Drift persistence for fast avatar loading
///
/// This service is designed to be used as a Riverpod provider with the
/// database injected via constructor. Use [avatarCacheServiceProvider] to
/// access instances.
class AvatarCacheService {
  /// Database for persistence

  /// In-memory cache: userId -> avatarUrl
  final Map<String, String> _memoryCache = {};

  /// In-memory cache: avatarUrl -> localFilePath (for downloaded images)
  final Map<String, String> _localPathCache = {};

  /// Pending fetch operations to avoid duplicate requests
  final Map<String, Completer<String?>> _pendingFetches = {};

  /// Flag to track if initial load is complete
  bool _initialized = false;
  final Completer<void> _initCompleter = Completer<void>();
  bool _initializing = false;

  /// Default avatar URL
  static const String defaultAvatarUrl =
      'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y';

  AvatarCacheService();

  /// Exposed for explicit lifecycle checks in app startup and tests.
  bool get isInitialized => _initialized;

  /// Initialize the cache from Drift storage
  /// Call this early in app startup
  Future<void> initialize() async {
    if (_initialized || _initializing) return;
    _initializing = true;

    try {
      // Memory cache populates lazily as avatars are requested; profile avatar
      // URLs come from Supabase/PowerSync now (no Drift seed). Just load any
      // locally cached avatar files.
      await _loadLocalAvatarPaths();

      _initialized = true;
      _initializing = false;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      _log.d(
        'AvatarCacheService: Loaded ${_memoryCache.length} avatars from cache',
      );
    } catch (e) {
      _log.e('AvatarCacheService: Error initializing cache: $e');
      _initialized = true;
      _initializing = false;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  /// Wait for initialization to complete
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _initCompleter.future;
  }

  /// Load local avatar file paths from disk
  Future<void> _loadLocalAvatarPaths() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory(join(appDir.path, 'avatars'));

      if (await avatarDir.exists()) {
        await for (final file in avatarDir.list()) {
          if (file is File) {
            // The filename is the URL hash
            final urlHash = basenameWithoutExtension(file.path);
            _localPathCache[urlHash] = file.path;
          }
        }
      }
    } catch (e) {
      _log.e('AvatarCacheService: Error loading local paths: $e');
    }
  }

  /// Get avatar URL for a single user (sync - returns cached or null)
  String? getAvatarUrlSync(String userId) {
    if (!_initialized) return null;
    return _memoryCache[userId];
  }

  /// Get avatar URLs for multiple users (sync - returns what's in cache)
  Map<String, String> getAvatarUrlsSync(List<String> userIds) {
    final result = <String, String>{};
    for (final userId in userIds) {
      final url = _memoryCache[userId];
      if (url != null) {
        result[userId] = url;
      }
    }
    return result;
  }

  /// Get avatar URL for a single user (async - fetches if not cached)
  Future<String?> getAvatarUrl(String userId) async {
    await ensureInitialized();

    // Check memory cache first
    if (_memoryCache.containsKey(userId)) {
      return _memoryCache[userId];
    }

    // Check if fetch is already in progress
    if (_pendingFetches.containsKey(userId)) {
      return _pendingFetches[userId]!.future;
    }

    // Start new fetch
    final completer = Completer<String?>();
    _pendingFetches[userId] = completer;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();

      final avatarUrl = response?['avatar_url'] as String?;

      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        _memoryCache[userId] = avatarUrl;
        // Persist to database
        await _persistAvatarUrl(userId, avatarUrl);
        // Download image file for offline use (fire and forget)
        _downloadAvatarInBackground(avatarUrl);
      }

      completer.complete(avatarUrl);
      return avatarUrl;
    } catch (e) {
      _log.e('AvatarCacheService: Error fetching avatar for $userId: $e');
      completer.complete(null);
      return null;
    } finally {
      _pendingFetches.remove(userId);
    }
  }

  /// Get avatar URLs for multiple users (async - fetches missing ones)
  Future<Map<String, String>> getAvatarUrls(List<String> userIds) async {
    await ensureInitialized();

    final result = <String, String>{};
    final missingIds = <String>[];

    // First, get what we have in cache
    for (final userId in userIds) {
      final cached = _memoryCache[userId];
      if (cached != null) {
        result[userId] = cached;
      } else {
        missingIds.add(userId);
      }
    }

    // If nothing is missing, return immediately
    if (missingIds.isEmpty) {
      return result;
    }

    // Fetch missing avatars from Supabase
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, avatar_url')
          .inFilter('id', missingIds);

      for (final record in response) {
        final userId = record['id'] as String;
        final avatarUrl = record['avatar_url'] as String?;

        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          _memoryCache[userId] = avatarUrl;
          result[userId] = avatarUrl;
        }
      }

      // Persist all new avatars
      await _persistAvatarUrls(result);

      // Download all avatar images for offline use (fire and forget)
      for (final avatarUrl in result.values) {
        _downloadAvatarInBackground(avatarUrl);
      }
    } catch (e) {
      _log.e('AvatarCacheService: Error fetching avatars: $e');
    }

    return result;
  }

  /// Preload avatars for a list of user IDs
  /// This is useful to call early so avatars are ready when needed
  Future<void> preloadAvatars(List<String> userIds) async {
    await getAvatarUrls(userIds);
  }

  /// Update the cache with new avatar URL
  void updateCache(String userId, String avatarUrl) {
    _memoryCache[userId] = avatarUrl;
    _persistAvatarUrl(userId, avatarUrl);
  }

  /// Batch update the cache
  void updateCacheBatch(Map<String, String> avatars) {
    _memoryCache.addAll(avatars);
    _persistAvatarUrls(avatars);
    // Download all avatar images for offline use
    for (final avatarUrl in avatars.values) {
      _downloadAvatarInBackground(avatarUrl);
    }
  }

  /// Download avatar in background (fire and forget)
  void _downloadAvatarInBackground(String url) {
    // Don't await - let it run in background
    downloadAvatar(url).then((_) {}).catchError((e) {
      _log.e('AvatarCacheService: Background download failed: $e');
    });
  }

  // ponytail: avatar URLs live in the in-memory cache + Supabase profiles
  // (synced via PowerSync). No separate local persistence layer needed, so
  // these are no-ops kept to avoid churning their four call sites.
  Future<void> _persistAvatarUrl(String userId, String avatarUrl) async {}

  Future<void> _persistAvatarUrls(Map<String, String> avatars) async {}

  /// Download and cache avatar image locally for offline use
  Future<String?> downloadAvatar(String url) async {
    if (url.isEmpty) return null;

    try {
      // Create hash of URL for filename
      final urlHash = url.hashCode.toRadixString(16);

      // Check if already downloaded
      if (_localPathCache.containsKey(urlHash)) {
        final path = _localPathCache[urlHash]!;
        if (await File(path).exists()) {
          return path;
        }
      }

      // Download the image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      // Save to local storage
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory(join(appDir.path, 'avatars'));
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      // Determine file extension from content type or URL
      String ext = '.jpg';
      final contentType = response.headers['content-type'];
      if (contentType != null) {
        if (contentType.contains('png')) {
          ext = '.png';
        } else if (contentType.contains('webp')) {
          ext = '.webp';
        } else if (contentType.contains('gif')) {
          ext = '.gif';
        }
      }

      final localPath = join(avatarDir.path, '$urlHash$ext');
      await File(localPath).writeAsBytes(response.bodyBytes);

      _localPathCache[urlHash] = localPath;
      return localPath;
    } catch (e) {
      _log.e('AvatarCacheService: Error downloading avatar: $e');
      return null;
    }
  }

  /// Get local path for an avatar URL (if downloaded)
  String? getLocalPath(String url) {
    final urlHash = url.hashCode.toRadixString(16);
    final cached = _localPathCache[urlHash];
    if (cached == null) {
      _downloadAvatarInBackground(url);
    }
    return cached;
  }

  /// Get the best available ImageProvider for an avatar
  /// Returns FileImage if local file exists, otherwise CachedNetworkImageProvider
  ImageProvider? getAvatarImageProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;

    // Check for local cached file first
    final localPath = getLocalPath(avatarUrl);
    if (localPath != null) {
      final file = File(localPath);
      if (file.existsSync()) {
        _log.d('AvatarCacheService: Using local avatar for $avatarUrl');
        return FileImage(file);
      }
    }

    // Fall back to network with caching
    _log.d('AvatarCacheService: Using network avatar for $avatarUrl');
    return CachedNetworkImageProvider(avatarUrl);
  }

  /// Get ImageProvider for a user ID (fetches from cache or downloads)
  ImageProvider? getAvatarImageProviderForUser(String userId) {
    final url = getAvatarUrlSync(userId);
    return getAvatarImageProvider(url);
  }

  /// Explicitly fetch and cache one user avatar.
  Future<String?> preloadAvatarForUser(String userId) async {
    return getAvatarUrl(userId);
  }

  /// Clean up old avatar files that haven't been accessed recently
  /// Call this periodically (e.g., weekly) to prevent cache bloat
  Future<void> cleanupOldAvatars({int daysOld = 30}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory(join(appDir.path, 'avatars'));

      if (!await avatarDir.exists()) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      int deletedCount = 0;

      await for (final file in avatarDir.list()) {
        if (file is File) {
          final stat = await file.stat();
          // Use last modified time as proxy for last access
          if (stat.modified.isBefore(cutoffDate)) {
            final urlHash = basenameWithoutExtension(file.path);
            await file.delete();
            _localPathCache.remove(urlHash);
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        _log.d('🧹 AvatarCacheService: Cleaned up $deletedCount old avatars');
      }
    } catch (e) {
      _log.e('AvatarCacheService: Error cleaning up old avatars: $e');
    }
  }

  /// Clear all caches
  Future<void> clearCache() async {
    _memoryCache.clear();
    _localPathCache.clear();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory(join(appDir.path, 'avatars'));
      if (await avatarDir.exists()) {
        await avatarDir.delete(recursive: true);
      }
    } catch (e) {
      _log.e('AvatarCacheService: Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'memoryCache': _memoryCache.length,
      'localCache': _localPathCache.length,
      'pendingFetches': _pendingFetches.length,
    };
  }
}
