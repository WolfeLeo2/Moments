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
    r'18bd88a0a78a55e455a54a337daf914903ba6cdd';

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
