import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'moment_storage_service.dart';

/// Centralized avatar caching service
/// Provides in-memory cache with SQLite persistence for fast avatar loading
class AvatarCacheService {
  static AvatarCacheService? _instance;

  /// In-memory cache: userId -> avatarUrl
  static final Map<String, String> _memoryCache = {};

  /// In-memory cache: avatarUrl -> localFilePath (for downloaded images)
  static final Map<String, String> _localPathCache = {};

  /// Pending fetch operations to avoid duplicate requests
  static final Map<String, Completer<String?>> _pendingFetches = {};

  /// Flag to track if initial load from SQLite is complete
  static bool _initialized = false;
  static final Completer<void> _initCompleter = Completer<void>();

  /// Storage service for SQLite persistence
  final MomentStorageService _storage = MomentStorageService();

  /// Default avatar URL
  static const String defaultAvatarUrl =
      'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y';

  AvatarCacheService._();

  factory AvatarCacheService() {
    _instance ??= AvatarCacheService._();
    return _instance!;
  }

  /// Initialize the cache from SQLite storage
  /// Call this early in app startup
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load all profiles from SQLite and populate memory cache
      final profiles = await _storage.getProfiles();
      for (final profile in profiles) {
        if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
          _memoryCache[profile.id] = profile.avatarUrl!;
        }
      }

      // Also load locally cached avatar files
      await _loadLocalAvatarPaths();

      _initialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      debugPrint(
        'AvatarCacheService: Loaded ${_memoryCache.length} avatars from cache',
      );
    } catch (e) {
      debugPrint('AvatarCacheService: Error initializing cache: $e');
      _initialized = true;
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
            // We'll need to match this with URLs when we fetch
            _localPathCache[urlHash] = file.path;
          }
        }
      }
    } catch (e) {
      debugPrint('AvatarCacheService: Error loading local paths: $e');
    }
  }

  /// Get avatar URL for a single user (sync - returns cached or null)
  String? getAvatarUrlSync(String userId) {
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
        // Persist to SQLite via profile update
        await _persistAvatarUrl(userId, avatarUrl);
      }

      completer.complete(avatarUrl);
      return avatarUrl;
    } catch (e) {
      debugPrint('AvatarCacheService: Error fetching avatar for $userId: $e');
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
    } catch (e) {
      debugPrint('AvatarCacheService: Error fetching avatars: $e');
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
  }

  /// Persist a single avatar URL to SQLite
  Future<void> _persistAvatarUrl(String userId, String avatarUrl) async {
    try {
      final db = await _storage.database;
      await db.rawUpdate('UPDATE profiles SET avatar_url = ? WHERE id = ?', [
        avatarUrl,
        userId,
      ]);
    } catch (e) {
      debugPrint('AvatarCacheService: Error persisting avatar: $e');
    }
  }

  /// Persist multiple avatar URLs to SQLite
  Future<void> _persistAvatarUrls(Map<String, String> avatars) async {
    if (avatars.isEmpty) return;

    try {
      final db = await _storage.database;
      final batch = db.batch();

      for (final entry in avatars.entries) {
        batch.rawUpdate('UPDATE profiles SET avatar_url = ? WHERE id = ?', [
          entry.value,
          entry.key,
        ]);
      }

      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('AvatarCacheService: Error batch persisting avatars: $e');
    }
  }

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
        if (contentType.contains('png'))
          ext = '.png';
        else if (contentType.contains('webp'))
          ext = '.webp';
        else if (contentType.contains('gif'))
          ext = '.gif';
      }

      final localPath = join(avatarDir.path, '$urlHash$ext');
      await File(localPath).writeAsBytes(response.bodyBytes);

      _localPathCache[urlHash] = localPath;
      return localPath;
    } catch (e) {
      debugPrint('AvatarCacheService: Error downloading avatar: $e');
      return null;
    }
  }

  /// Get local path for an avatar URL (if downloaded)
  String? getLocalPath(String url) {
    final urlHash = url.hashCode.toRadixString(16);
    return _localPathCache[urlHash];
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
      debugPrint('AvatarCacheService: Error clearing cache: $e');
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
