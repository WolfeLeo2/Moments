// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_cache_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the media cache service (singleton with keepAlive)

@ProviderFor(mediaCacheService)
final mediaCacheServiceProvider = MediaCacheServiceProvider._();

/// Provider for the media cache service (singleton with keepAlive)

final class MediaCacheServiceProvider
    extends
        $FunctionalProvider<
          MediaCacheService,
          MediaCacheService,
          MediaCacheService
        >
    with $Provider<MediaCacheService> {
  /// Provider for the media cache service (singleton with keepAlive)
  MediaCacheServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaCacheServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaCacheServiceHash();

  @$internal
  @override
  $ProviderElement<MediaCacheService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MediaCacheService create(Ref ref) {
    return mediaCacheService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaCacheService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaCacheService>(value),
    );
  }
}

String _$mediaCacheServiceHash() => r'4878dd2df684302d68dba0bea9de94040debdf4e';
