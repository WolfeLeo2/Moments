import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:moments/data/models/moment.dart';

/// Moment storage service for persistent local data storage
/// Stores moments and their media locally for offline access
class MomentStorageService {
  static MomentStorageService? _instance;
  static Database? _database;
  static Directory? _mediaDirectory;

  MomentStorageService._();

  factory MomentStorageService() {
    _instance ??= MomentStorageService._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Directory> get mediaDirectory async {
    if (_mediaDirectory != null) return _mediaDirectory!;
    final appDir = await getApplicationDocumentsDirectory();
    _mediaDirectory = Directory(join(appDir.path, 'moments_media'));
    if (!await _mediaDirectory!.exists()) {
      await _mediaDirectory!.create(recursive: true);
    }
    return _mediaDirectory!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'moments_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table for moments metadata
        await db.execute('''
          CREATE TABLE moments (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            location TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            image_url TEXT,
            media_path TEXT,
            caption TEXT,
            media_type TEXT NOT NULL DEFAULT 'image',
            duration INTEGER,
            thumbnail_path TEXT,
            created_at INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            user_id TEXT,
            description TEXT,
            moment_group_id TEXT,
            is_locked INTEGER NOT NULL DEFAULT 0,
            is_private INTEGER NOT NULL DEFAULT 0,
            local_media_path TEXT,
            local_thumbnail_path TEXT,
            synced_at INTEGER NOT NULL
          )
        ''');

        // Index for faster queries
        await db.execute('''
          CREATE INDEX idx_moments_user ON moments(user_id)
        ''');

        await db.execute('''
          CREATE INDEX idx_moments_group ON moments(moment_group_id)
        ''');

        await db.execute('''
          CREATE INDEX idx_moments_created ON moments(created_at DESC)
        ''');

        // Table for tracking media download status
        await db.execute('''
          CREATE TABLE media_cache (
            remote_path TEXT PRIMARY KEY,
            local_path TEXT NOT NULL,
            file_size INTEGER,
            cached_at INTEGER NOT NULL,
            last_accessed INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Get all stored moments
  Future<List<Moment>> getMoments() async {
    final db = await database;
    final results = await db.query('moments', orderBy: 'created_at DESC');

    return results.map((row) => _momentFromRow(row)).toList();
  }

  /// Get moments for a specific user
  Future<List<Moment>> getMomentsByUser(String userId) async {
    final db = await database;
    final results = await db.query(
      'moments',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return results.map((row) => _momentFromRow(row)).toList();
  }

  /// Get a specific moment by ID
  Future<Moment?> getMomentById(String momentId) async {
    final db = await database;
    final results = await db.query(
      'moments',
      where: 'id = ?',
      whereArgs: [momentId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _momentFromRow(results.first);
  }

  /// Save/update moments in persistent storage
  Future<void> saveMoments(List<Moment> moments) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final moment in moments) {
      // Check if moment already exists to preserve local paths
      final existing = await db.query(
        'moments',
        columns: ['local_media_path', 'local_thumbnail_path'],
        where: 'id = ?',
        whereArgs: [moment.id],
        limit: 1,
      );

      String? localMediaPath;
      String? localThumbnailPath;

      if (existing.isNotEmpty) {
        localMediaPath = existing.first['local_media_path'] as String?;
        localThumbnailPath = existing.first['local_thumbnail_path'] as String?;
      }

      batch.insert('moments', {
        'id': moment.id,
        'title': moment.title,
        'location': moment.location,
        'latitude': moment.latitude,
        'longitude': moment.longitude,
        'image_url': moment.imageUrl,
        'media_path': moment.mediaPath,
        'caption': moment.caption,
        'media_type': moment.mediaType,
        'duration': moment.duration,
        'thumbnail_path': moment.thumbnailPath,
        'created_at': moment.createdAt.millisecondsSinceEpoch,
        'timestamp': moment.timestamp.millisecondsSinceEpoch,
        'user_id': moment.userId,
        'description': moment.description,
        'moment_group_id': moment.momentGroupId,
        'is_locked': moment.isLocked ? 1 : 0,
        'is_private': moment.isPrivate ? 1 : 0,
        'local_media_path': localMediaPath,
        'local_thumbnail_path': localThumbnailPath,
        'synced_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
    debugPrint('💾 Saved ${moments.length} moments to local storage');
  }

  /// Download and cache media for a moment
  Future<String?> cacheMedia(
    String momentId,
    String remoteUrl, {
    bool isThumbnail = false,
  }) async {
    try {
      final db = await database;
      final dir = await mediaDirectory;

      // Check if already cached
      final cached = await db.query(
        'media_cache',
        where: 'remote_path = ?',
        whereArgs: [remoteUrl],
        limit: 1,
      );

      if (cached.isNotEmpty) {
        final localPath = cached.first['local_path'] as String;
        if (await File(localPath).exists()) {
          // Update last accessed
          await db.update(
            'media_cache',
            {'last_accessed': DateTime.now().millisecondsSinceEpoch},
            where: 'remote_path = ?',
            whereArgs: [remoteUrl],
          );
          return localPath;
        }
      }

      // Download the file
      debugPrint('⬇️ Downloading media: ${remoteUrl.substring(0, 50)}...');
      final response = await http.get(Uri.parse(remoteUrl));

      if (response.statusCode != 200) {
        debugPrint('❌ Failed to download media: ${response.statusCode}');
        return null;
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
      final fileName =
          '${momentId}_${isThumbnail ? 'thumb' : 'media'}$extension';
      final localPath = join(dir.path, fileName);
      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);

      // Update cache record
      await db.insert('media_cache', {
        'remote_path': remoteUrl,
        'local_path': localPath,
        'file_size': response.bodyBytes.length,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'last_accessed': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Update moment's local path
      await db.update(
        'moments',
        {isThumbnail ? 'local_thumbnail_path' : 'local_media_path': localPath},
        where: 'id = ?',
        whereArgs: [momentId],
      );

      debugPrint(
        '✅ Cached media to: $localPath (${(response.bodyBytes.length / 1024).toStringAsFixed(1)} KB)',
      );
      return localPath;
    } catch (e) {
      debugPrint('❌ Error caching media: $e');
      return null;
    }
  }

  /// Get local media path for a moment
  Future<String?> getLocalMediaPath(
    String momentId, {
    bool isThumbnail = false,
  }) async {
    final db = await database;
    final results = await db.query(
      'moments',
      columns: [isThumbnail ? 'local_thumbnail_path' : 'local_media_path'],
      where: 'id = ?',
      whereArgs: [momentId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    final path =
        results.first[isThumbnail ? 'local_thumbnail_path' : 'local_media_path']
            as String?;

    // Verify file exists
    if (path != null && await File(path).exists()) {
      return path;
    }
    return null;
  }

  /// Delete a moment from local storage
  Future<void> deleteMoment(String momentId) async {
    final db = await database;

    // Get local paths first
    final moment = await getMomentById(momentId);

    // Delete from database
    await db.delete('moments', where: 'id = ?', whereArgs: [momentId]);

    // Delete local media files
    if (moment != null) {
      final localMedia = await getLocalMediaPath(momentId);
      final localThumb = await getLocalMediaPath(momentId, isThumbnail: true);

      if (localMedia != null) {
        try {
          await File(localMedia).delete();
        } catch (_) {}
      }
      if (localThumb != null) {
        try {
          await File(localThumb).delete();
        } catch (_) {}
      }
    }
  }

  /// Clear all stored moments
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('moments');
    await db.delete('media_cache');

    // Clear media directory
    final dir = await mediaDirectory;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
    debugPrint('🗑️ Cleared all local moments and media');
  }

  /// Clean up old cached media (older than specified days)
  Future<void> cleanupOldMedia({int daysOld = 30}) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: daysOld))
        .millisecondsSinceEpoch;

    final oldEntries = await db.query(
      'media_cache',
      where: 'last_accessed < ?',
      whereArgs: [cutoff],
    );

    for (final entry in oldEntries) {
      final localPath = entry['local_path'] as String;
      try {
        await File(localPath).delete();
      } catch (_) {}
    }

    await db.delete(
      'media_cache',
      where: 'last_accessed < ?',
      whereArgs: [cutoff],
    );

    debugPrint('🧹 Cleaned up ${oldEntries.length} old media files');
  }

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(file_size) as total FROM media_cache',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Convert database row to Moment object
  Moment _momentFromRow(Map<String, dynamic> row) {
    return Moment(
      id: row['id'] as String,
      title: row['title'] as String,
      location: row['location'] as String,
      latitude: row['latitude'] as double,
      longitude: row['longitude'] as double,
      imageUrl: row['image_url'] as String?,
      mediaPath: row['media_path'] as String?,
      caption: row['caption'] as String?,
      mediaType: row['media_type'] as String? ?? 'image',
      duration: row['duration'] as int?,
      thumbnailPath: row['thumbnail_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      userId: row['user_id'] as String?,
      description: row['description'] as String?,
      momentGroupId: row['moment_group_id'] as String?,
      isLocked: (row['is_locked'] as int) == 1,
      isPrivate: (row['is_private'] as int) == 1,
    );
  }
}
