import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:moments/features/chat/services/media_cache_service.dart';

part 'media_cache_provider.g.dart';

/// Provider for the media cache service (singleton with keepAlive)
@Riverpod(keepAlive: true)
MediaCacheService mediaCacheService(Ref ref) {
  return MediaCacheService();
}
