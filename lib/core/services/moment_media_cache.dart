import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:moments/core/services/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Offline media file cache for moments (replaces the old Drift MediaCache).
///
/// ponytail: no index table — the filesystem IS the index. A moment's local
/// file path is `mediaDir/sha256(momentId[+_thumb])`, so a presence check is the
/// whole lookup. Drop a file and it's a cache miss; no row to keep in sync.
///
/// Source of truth for moment *content* is PowerSync; this only tracks which
/// heavy media bytes have been pulled local (D8 opt-in moment media).
class MomentMediaCache {
  MomentMediaCache._();

  static final _log = AppLogger('MomentMediaCache');

  static Future<Directory> _mediaDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'moment_media'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> _pathFor(String momentId, bool isThumbnail) async {
    final dir = await _mediaDir();
    final key = isThumbnail ? '${momentId}_thumb' : momentId;
    final name = sha256.convert(utf8.encode(key)).toString();
    return p.join(dir.path, name);
  }

  /// Returns the local file path for a moment's media if it has been cached
  /// and the file still exists; otherwise null.
  static Future<String?> getLocalMediaPath(
    String momentId, {
    bool isThumbnail = false,
  }) async {
    final path = await _pathFor(momentId, isThumbnail);
    return await File(path).exists() ? path : null;
  }

  /// Downloads [remoteUrl] to the deterministic local path and returns it.
  /// If already present, returns the cached path without re-downloading.
  static Future<String?> cacheMedia(
    String momentId,
    String remoteUrl, {
    bool isThumbnail = false,
  }) async {
    final path = await _pathFor(momentId, isThumbnail);
    final file = File(path);
    if (await file.exists()) return path;

    try {
      final response = await http.get(Uri.parse(remoteUrl));
      if (response.statusCode != 200) {
        _log.e('Download failed (${response.statusCode}) for $momentId');
        return null;
      }
      await file.writeAsBytes(response.bodyBytes);
      return path;
    } catch (e) {
      _log.e('Error caching media for $momentId', error: e);
      return null;
    }
  }

  /// Delete cached media + thumbnail for a moment.
  static Future<void> evict(String momentId) async {
    for (final isThumb in [false, true]) {
      final path = await _pathFor(momentId, isThumb);
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }
}
