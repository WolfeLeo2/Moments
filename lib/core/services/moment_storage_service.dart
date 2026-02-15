import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:moments/data/models/moment.dart';
import 'package:moments/data/models/profile.dart';
import 'package:moments/data/models/friendship.dart';
import 'package:moments/core/database/database.dart';
import 'package:moments/core/services/app_logger.dart';


final _log = AppLogger('MomentStorage');
/// Moment storage service for persistent local data storage
/// Uses Drift for database operations (consolidated from sqflite)
/// Stores moments and their media locally for offline access
class MomentStorageService {
  /// Drift database instance
  final AppDatabase _database;

  /// Media directory for cached files
  Directory? _mediaDirectory;

  /// Retry configuration
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 1);

  /// Creates a MomentStorageService with the required database dependency.
  MomentStorageService(this._database);

  /// Get media directory for caching files
  Future<Directory> get mediaDirectory async {
    if (_mediaDirectory != null) return _mediaDirectory!;
    final appDir = await getApplicationDocumentsDirectory();
    _mediaDirectory = Directory(p.join(appDir.path, 'moment_media'));
    if (!await _mediaDirectory!.exists()) {
      await _mediaDirectory!.create(recursive: true);
    }
    return _mediaDirectory!;
  }

  // ============================================
  // MOMENT OPERATIONS
  // ============================================

  /// Get all stored moments
  Future<List<Moment>> getMoments() async {
    final entries = await _database.getMoments();
    return entries.map((e) => _momentFromEntry(e)).toList();
  }

  /// Get moments for a specific user
  Future<List<Moment>> getMomentsByUser(String userId) async {
    final entries = await _database.getMomentsByUser(userId);
    return entries.map((e) => _momentFromEntry(e)).toList();
  }

  /// Get a specific moment by ID
  Future<Moment?> getMomentById(String momentId) async {
    final entry = await _database.getMomentById(momentId);
    if (entry == null) return null;
    return _momentFromEntry(entry);
  }

  /// Update privacy for a moment
  Future<void> updateMomentPrivacy(String momentId, bool isPrivate) async {
    await _database.updateMomentPrivacy(momentId, isPrivate);
  }

  /// Update privacy for all moments in a group
  Future<void> updateGroupPrivacy(String groupId, bool isPrivate) async {
    await _database.updateGroupPrivacy(groupId, isPrivate);
  }

  /// Save/update moments in persistent storage
  Future<void> saveMoments(List<Moment> moments) async {
    final entries = <MomentsCompanion>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final moment in moments) {
      // Check if moment already exists to preserve local paths
      final existing = await _database.getMomentById(moment.id);

      entries.add(
        MomentsCompanion.insert(
          id: moment.id,
          title: moment.title,
          location: moment.location,
          latitude: moment.latitude,
          longitude: moment.longitude,
          imageUrl: Value(moment.imageUrl),
          mediaPath: Value(moment.mediaPath),
          caption: Value(moment.caption),
          mediaType: Value(moment.mediaType),
          duration: Value(moment.duration),
          thumbnailPath: Value(moment.thumbnailPath),
          createdAt: moment.createdAt.millisecondsSinceEpoch,
          timestamp: moment.timestamp.millisecondsSinceEpoch,
          userId: Value(moment.userId),
          description: Value(moment.description),
          momentGroupId: moment.momentGroupId,
          isPrivate: Value(moment.isPrivate),
          localMediaPath: Value(existing?.localMediaPath),
          localThumbnailPath: Value(existing?.localThumbnailPath),
          syncedAt: now,
        ),
      );
    }

    await _database.saveMoments(entries);
    _log.d('💾 Saved ${moments.length} moments to local storage');
  }

  /// Sync moments from server (save new ones, delete removed ones)
  Future<void> syncMoments(List<Moment> serverMoments) async {
    // Get all IDs from server list
    final serverIds = serverMoments.map((m) => m.id).toSet();

    // Get all local moments
    final localMoments = await _database.getMoments();
    final localIds = localMoments.map((m) => m.id).toSet();

    // Find IDs to delete (local but not in server list)
    final idsToDelete = localIds.difference(serverIds);

    if (idsToDelete.isNotEmpty) {
      for (final id in idsToDelete) {
        await _database.deleteMoment(id);
      }
      _log.d(
        '🗑️ Deleted ${idsToDelete.length} stale moments from local storage',
      );
    }

    // Save/Update server moments
    if (serverMoments.isNotEmpty) {
      await saveMoments(serverMoments);
    }
  }

  // ============================================
  // MEDIA CACHING WITH RETRY
  // ============================================

  /// Download and cache media for a moment with exponential backoff retry
  Future<String?> cacheMedia(
    String momentId,
    String remoteUrl, {
    bool isThumbnail = false,
  }) async {
    // Try with retries
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        return await _cacheMediaInternal(
          momentId,
          remoteUrl,
          isThumbnail: isThumbnail,
        );
      } catch (e) {
        if (attempt == _maxRetries - 1) {
          _log.e('❌ Failed to cache media after $_maxRetries attempts: $e');
          return null;
        }
        // Exponential backoff
        final delay = _baseRetryDelay * (1 << attempt);
        _log.w(
          '⚠️ Retry ${attempt + 1}/$_maxRetries for media download in ${delay.inSeconds}s',
        );
        await Future.delayed(delay);
      }
    }
    return null;
  }

  /// Internal implementation of media caching
  Future<String?> _cacheMediaInternal(
    String momentId,
    String remoteUrl, {
    bool isThumbnail = false,
  }) async {
    final dir = await mediaDirectory;

    // Check if already cached
    final cached = await _database.getCachedMedia(remoteUrl);

    if (cached != null) {
      if (await File(cached.localPath).exists()) {
        // Update last accessed
        await _database.updateMediaAccess(remoteUrl);
        return cached.localPath;
      }
    }

    // Download the file
    _log.d(
      '⬇️ Downloading media: ${remoteUrl.substring(0, remoteUrl.length.clamp(0, 50))}...',
    );

    final response = await http
        .get(Uri.parse(remoteUrl))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    // Determine file extension from content type or URL
    String extension = '.jpg';
    final contentType = response.headers['content-type'];
    if (contentType != null) {
      if (contentType.contains('video')) {
        extension = '.mp4';
      } else if (contentType.contains('png')) {
        extension = '.png';
      } else if (contentType.contains('webp')) {
        extension = '.webp';
      }
    }

    // Save to local file
    final fileName = '${momentId}_${isThumbnail ? 'thumb' : 'media'}$extension';
    final localPath = p.join(dir.path, fileName);
    final file = File(localPath);
    await file.writeAsBytes(response.bodyBytes);

    // Update cache record
    await _database.saveMediaCache(
      MediaCacheCompanion.insert(
        remotePath: remoteUrl,
        localPath: localPath,
        fileSize: Value(response.bodyBytes.length),
        cachedAt: DateTime.now().millisecondsSinceEpoch,
        lastAccessed: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    // Update moment's local path
    await _database.saveMoments([
      MomentsCompanion(
        id: Value(momentId),
        localMediaPath: isThumbnail ? const Value.absent() : Value(localPath),
        localThumbnailPath: isThumbnail
            ? Value(localPath)
            : const Value.absent(),
      ),
    ]);

    _log.d(
      '✅ Cached media to: $localPath (${(response.bodyBytes.length / 1024).toStringAsFixed(1)} KB)',
    );
    return localPath;
  }

  /// Get local media path for a moment
  Future<String?> getLocalMediaPath(
    String momentId, {
    bool isThumbnail = false,
  }) async {
    return _database.getLocalMediaPath(momentId, isThumbnail: isThumbnail);
  }

  /// Delete a moment from local storage
  Future<void> deleteMoment(String momentId) async {
    await _database.deleteMoment(momentId);
  }

  /// Clear all stored moments
  Future<void> clearAll() async {
    await _database.clearAllMoments();

    // Clear media cache entries
    final oldEntries = await _database.getOldMediaEntries(
      DateTime.now().millisecondsSinceEpoch + 1, // Get all entries
    );
    for (final entry in oldEntries) {
      try {
        await File(entry.localPath).delete();
      } catch (_) {}
      await _database.deleteMediaCache(entry.remotePath);
    }

    // Clear media directory
    final dir = await mediaDirectory;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
    _log.d('🗑️ Cleared all local moments and media');
  }

  /// Clean up old cached media (older than specified days)
  Future<void> cleanupOldMedia({int daysOld = 10}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: daysOld))
        .millisecondsSinceEpoch;

    final oldEntries = await _database.getOldMediaEntries(cutoff);

    for (final entry in oldEntries) {
      try {
        await File(entry.localPath).delete();
      } catch (_) {}
      await _database.deleteMediaCache(entry.remotePath);
    }

    _log.d('🧹 Cleaned up ${oldEntries.length} old media files');
  }

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    final entries = await _database.getOldMediaEntries(
      DateTime.now().millisecondsSinceEpoch + 1,
    );
    int total = 0;
    for (final entry in entries) {
      total += entry.fileSize ?? 0;
    }
    return total;
  }

  // ============================================
  // FRIENDS & PROFILES STORAGE
  // ============================================

  /// Save profiles to local storage
  Future<void> saveProfiles(List<Profile> profiles) async {
    final entries = profiles
        .map(
          (profile) => ProfilesCompanion.insert(
            id: profile.id,
            username: Value(profile.username),
            displayName: Value(profile.displayName),
            avatarUrl: Value(profile.avatarUrl),
            bio: Value(profile.bio),
            inviteCode: Value(profile.inviteCode),
            createdAt: Value(profile.createdAt.millisecondsSinceEpoch),
            updatedAt: Value(profile.updatedAt.millisecondsSinceEpoch),
          ),
        )
        .toList();

    await _database.saveProfiles(entries);
  }

  /// Get profiles from local storage
  Future<List<Profile>> getProfiles() async {
    final entries = await _database.getProfiles();
    return entries.map((e) => e.toModel()).toList();
  }

  /// Save friendships to local storage
  Future<void> saveFriendships(List<Friendship> friendships) async {
    final entries = friendships
        .map(
          (friendship) => FriendshipsCompanion.insert(
            id: friendship.id,
            userId1: friendship.userId,
            userId2: friendship.friendId,
            status: friendship.status.name,
            createdAt: Value(friendship.requestedAt.millisecondsSinceEpoch),
            updatedAt: Value(friendship.respondedAt?.millisecondsSinceEpoch),
          ),
        )
        .toList();

    await _database.saveFriendships(entries);
  }

  /// Get friendships from local storage
  Future<List<Friendship>> getFriendships() async {
    final entries = await _database.getFriendships();
    return entries
        .map(
          (entry) => Friendship(
            id: entry.id,
            userId: entry.userId1,
            friendId: entry.userId2,
            status: FriendshipStatus.fromString(entry.status),
            requestedAt: DateTime.fromMillisecondsSinceEpoch(
              entry.createdAt ?? 0,
            ),
            respondedAt: entry.updatedAt != null
                ? DateTime.fromMillisecondsSinceEpoch(entry.updatedAt!)
                : null,
          ),
        )
        .toList();
  }

  // ============================================
  // CONVERTERS
  // ============================================

  /// Convert MomentEntry (Drift) to Moment (app model)
  Moment _momentFromEntry(MomentEntry entry) {
    return Moment(
      id: entry.id,
      title: entry.title,
      location: entry.location,
      latitude: entry.latitude,
      longitude: entry.longitude,
      imageUrl: entry.imageUrl,
      mediaPath: entry.mediaPath,
      caption: entry.caption,
      mediaType: entry.mediaType,
      duration: entry.duration,
      thumbnailPath: entry.thumbnailPath,
      createdAt: DateTime.fromMillisecondsSinceEpoch(entry.createdAt),
      timestamp: DateTime.fromMillisecondsSinceEpoch(entry.timestamp),
      userId: entry.userId,
      description: entry.description,
      momentGroupId: entry.momentGroupId,
      isPrivate: entry.isPrivate,
    );
  }
}
