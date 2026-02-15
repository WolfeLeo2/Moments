// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MapUiStateNotifier)
const mapUiStateProvider = MapUiStateNotifierProvider._();

final class MapUiStateNotifierProvider
    extends $NotifierProvider<MapUiStateNotifier, MapUiState> {
  const MapUiStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapUiStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapUiStateNotifierHash();

  @$internal
  @override
  MapUiStateNotifier create() => MapUiStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapUiState>(value),
    );
  }
}

String _$mapUiStateNotifierHash() =>
    r'a052d009999bcc6b93eb66226726d6775ef5e8a6';

abstract class _$MapUiStateNotifier extends $Notifier<MapUiState> {
  MapUiState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MapUiState, MapUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MapUiState, MapUiState>,
              MapUiState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
