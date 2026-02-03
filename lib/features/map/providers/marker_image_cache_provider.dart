import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/providers/database_provider.dart';
import 'package:moments/core/services/signed_url_cache.dart';
import 'package:moments/data/models/moment.dart';

/// Cached image data for a moment marker
class MarkerImageData {
  final String? localPath;
  final String? networkUrl;

  const MarkerImageData({this.localPath, this.networkUrl});

  bool get hasImage => localPath != null || networkUrl != null;
}

/// Provider that caches image paths/URLs for moment markers
/// This persists across widget rebuilds during zoom changes
final markerImageCacheProvider =
    NotifierProvider<MarkerImageCacheNotifier, Map<String, MarkerImageData>>(
      MarkerImageCacheNotifier.new,
    );

class MarkerImageCacheNotifier extends Notifier<Map<String, MarkerImageData>> {
  final Set<String> _loadingIds = {};

  @override
  Map<String, MarkerImageData> build() => {};

  /// Get cached image data for a moment (returns null if not loaded yet)
  MarkerImageData? getImageData(String momentId) => state[momentId];

  /// Check if image data exists for a moment
  bool hasImageData(String momentId) => state.containsKey(momentId);

  /// Load image data for multiple moments (batched for efficiency)
  Future<void> loadImagesForMoments(List<Moment> moments) async {
    // Filter to moments we haven't loaded or aren't currently loading
    final momentsToLoad = moments.where((m) {
      return !state.containsKey(m.id) && !_loadingIds.contains(m.id);
    }).toList();

    if (momentsToLoad.isEmpty) return;

    // Mark as loading to prevent duplicate requests
    for (final m in momentsToLoad) {
      _loadingIds.add(m.id);
    }

    try {
      final db = ref.read(appDatabaseProvider);
      final newData = <String, MarkerImageData>{};

      // First, check for locally cached images
      for (final moment in momentsToLoad) {
        final isThumbnail = moment.mediaType == 'video';
        final localPath = await db.getLocalMediaPath(
          moment.id,
          isThumbnail: isThumbnail,
        );

        if (localPath != null) {
          newData[moment.id] = MarkerImageData(localPath: localPath);
          debugPrint(
            '✅ [MarkerCache] Found local path for ${moment.id.substring(0, 8)}',
          );
        }
      }

      // For moments without local paths, fetch network URLs
      final momentsNeedingUrls = momentsToLoad.where(
        (m) => !newData.containsKey(m.id),
      ).toList();

      if (momentsNeedingUrls.isNotEmpty) {
        final pathsToLoad = <String>[];
        final momentPathMap = <String, String>{};

        for (final moment in momentsNeedingUrls) {
          final path = moment.mediaType == 'video'
              ? moment.thumbnailPath
              : moment.mediaPath;
          if (path != null && path.isNotEmpty) {
            pathsToLoad.add(path);
            momentPathMap[moment.id] = path;
          }
        }

        if (pathsToLoad.isNotEmpty) {
          final urls = await SignedUrlCache.getSignedUrlsBatch(pathsToLoad);

          for (final moment in momentsNeedingUrls) {
            final path = momentPathMap[moment.id];
            if (path != null) {
              final url = urls[path];
              if (url != null) {
                newData[moment.id] = MarkerImageData(networkUrl: url);
                debugPrint(
                  '✅ [MarkerCache] Got URL for ${moment.id.substring(0, 8)}',
                );

                // Cache to local storage in background
                _cacheInBackground(moment, url);
              }
            }
          }
        }
      }

      // Update state with new data
      if (newData.isNotEmpty) {
        state = {...state, ...newData};
      }
    } finally {
      // Remove from loading set
      for (final m in momentsToLoad) {
        _loadingIds.remove(m.id);
      }
    }
  }

  /// Cache image to local storage in background and update state
  Future<void> _cacheInBackground(Moment moment, String url) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final isThumbnail = moment.mediaType == 'video';
      final localPath = await db.cacheMedia(
        moment.id,
        url,
        isThumbnail: isThumbnail,
      );

      if (localPath != null) {
        // Update state to prefer local path
        state = {
          ...state,
          moment.id: MarkerImageData(localPath: localPath, networkUrl: url),
        };
      }
    } catch (e) {
      debugPrint('⚠️ [MarkerCache] Error caching ${moment.id}: $e');
    }
  }

  /// Update local path for a moment (called when media is cached)
  void updateLocalPath(String momentId, String localPath) {
    final existing = state[momentId];
    state = {
      ...state,
      momentId: MarkerImageData(
        localPath: localPath,
        networkUrl: existing?.networkUrl,
      ),
    };
  }

  /// Clear cache (useful when user logs out or clears app data)
  void clear() {
    state = {};
    _loadingIds.clear();
  }
}
