import '../../data/sources/supabase_config.dart';
import 'package:moments/core/services/app_logger.dart';


final _log = AppLogger('SignedUrlCache');
/// Caches signed URLs to avoid regenerating them on every access
/// Signed URLs expire after 24 hours, so we cache them for 23 hours
class SignedUrlCache {
  static final Map<String, (String url, DateTime expiry)> _cache = {};

  // Track paths that have failed to avoid repeated failures
  static final Map<String, DateTime> _failedPaths = {};
  static const Duration _failureCooldown = Duration(minutes: 5);

  /// Get a signed URL for a media path, using cache if available
  static Future<String?> getSignedUrl(String mediaPath) async {
    // Check if this path recently failed
    final failedAt = _failedPaths[mediaPath];
    if (failedAt != null &&
        DateTime.now().difference(failedAt) < _failureCooldown) {
      _log.e('Skipping recently failed path: $mediaPath');
      return null;
    }

    final cached = _cache[mediaPath];

    // Return cached URL if it exists and hasn't expired
    if (cached != null && cached.$2.isAfter(DateTime.now())) {
      return cached.$1;
    }

    try {
      // Generate new signed URL (valid for 24 hours)
      final signedUrl = await SupabaseConfig.momentsBucket.createSignedUrl(
        mediaPath,
        60 * 60 * 24, // 24 hours validity
      );

      // Cache it for 23 hours (expire 1 hour early to be safe)
      _cache[mediaPath] = (
        signedUrl,
        DateTime.now().add(const Duration(hours: 23)),
      );

      // Clear from failed paths if it was there
      _failedPaths.remove(mediaPath);

      return signedUrl;
    } catch (e) {
      _log.e('❌ Error generating signed URL for $mediaPath: $e');
      _failedPaths[mediaPath] = DateTime.now();
      return null;
    }
  }

  /// Batch generate signed URLs for multiple media paths in parallel
  static Future<Map<String, String>> getSignedUrlsBatch(
    List<String> mediaPaths,
  ) async {
    final results = <String, String>{};

    // Filter out paths we already have cached or that recently failed
    final uncachedPaths = mediaPaths.where((path) {
      // Check failed paths
      final failedAt = _failedPaths[path];
      if (failedAt != null &&
          DateTime.now().difference(failedAt) < _failureCooldown) {
        return false;
      }

      // Check cache
      final cached = _cache[path];
      if (cached != null && cached.$2.isAfter(DateTime.now())) {
        results[path] = cached.$1;
        return false;
      }
      return true;
    }).toList();

    if (uncachedPaths.isEmpty) {
      return results;
    }

    _log.d('Generating ${uncachedPaths.length} signed URLs in parallel...');

    // Generate remaining URLs in parallel for speed
    // Use individual error handling to prevent one failure from breaking all
    final futures = uncachedPaths.map((path) => getSignedUrl(path));
    final urls = await Future.wait(futures);

    // Add to results (skip nulls from failed requests)
    for (var i = 0; i < uncachedPaths.length; i++) {
      final url = urls[i];
      if (url != null) {
        results[uncachedPaths[i]] = url;
      }
    }

    _log.d('Batch complete: ${results.length} signed URLs ready');
    return results;
  }

  /// Clear all cached URLs (useful for logout or debugging)
  static void clearCache() {
    _cache.clear();
    _failedPaths.clear();
    _log.d('Signed URL cache cleared');
  }

  /// Clear expired URLs from cache
  static void clearExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) => value.$2.isBefore(now));
    _log.d('Expired URLs cleared from cache');
  }
}
