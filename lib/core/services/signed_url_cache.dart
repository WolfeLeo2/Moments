import 'package:flutter/foundation.dart';
import '../../data/sources/supabase_config.dart';

/// Caches signed URLs to avoid regenerating them on every access
/// Signed URLs expire after 24 hours, so we cache them for 23 hours
class SignedUrlCache {
  static final Map<String, (String url, DateTime expiry)> _cache = {};

  /// Get a signed URL for a media path, using cache if available
  static Future<String> getSignedUrl(String mediaPath) async {
    final cached = _cache[mediaPath];

    // Return cached URL if it exists and hasn't expired
    if (cached != null && cached.$2.isAfter(DateTime.now())) {
      debugPrint('Using cached signed URL for: $mediaPath');
      return cached.$1;
    }

    // Generate new signed URL (valid for 24 hours)
    debugPrint('Generating new signed URL for: $mediaPath');
    final signedUrl = await SupabaseConfig.momentsBucket.createSignedUrl(
      mediaPath,
      60 * 60 * 24, // 24 hours validity
    );

    // Cache it for 23 hours (expire 1 hour early to be safe)
    _cache[mediaPath] = (
      signedUrl,
      DateTime.now().add(const Duration(hours: 23)),
    );

    return signedUrl;
  }

  /// Batch generate signed URLs for multiple media paths in parallel
  static Future<Map<String, String>> getSignedUrlsBatch(
    List<String> mediaPaths,
  ) async {
    final results = <String, String>{};

    // Filter out paths we already have cached
    final uncachedPaths = mediaPaths.where((path) {
      final cached = _cache[path];
      if (cached != null && cached.$2.isAfter(DateTime.now())) {
        results[path] = cached.$1;
        return false;
      }
      return true;
    }).toList();

    if (uncachedPaths.isEmpty) {
      debugPrint('All URLs already cached (${mediaPaths.length} paths)');
      return results;
    }

    debugPrint('Generating ${uncachedPaths.length} signed URLs in parallel...');

    // Generate remaining URLs in parallel for speed
    final futures = uncachedPaths.map((path) => getSignedUrl(path));
    final urls = await Future.wait(futures);

    // Add to results
    for (var i = 0; i < uncachedPaths.length; i++) {
      results[uncachedPaths[i]] = urls[i];
    }

    debugPrint('Batch complete: ${results.length} signed URLs ready');
    return results;
  }

  /// Clear all cached URLs (useful for logout or debugging)
  static void clearCache() {
    _cache.clear();
    debugPrint('Signed URL cache cleared');
  }

  /// Clear expired URLs from cache
  static void clearExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) => value.$2.isBefore(now));
    debugPrint('Expired URLs cleared from cache');
  }
}
