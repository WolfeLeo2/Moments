import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/features/chat/services/media_cache_service.dart';

/// Provider for the media cache service (singleton)
final mediaCacheServiceProvider = Provider<MediaCacheService>((ref) {
  return MediaCacheService();
});
