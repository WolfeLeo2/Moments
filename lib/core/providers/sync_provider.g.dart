// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global sync state provider
/// Tracks sync errors from various sources and provides overall status

@ProviderFor(SyncState)
const syncStateProvider = SyncStateProvider._();

/// Global sync state provider
/// Tracks sync errors from various sources and provides overall status
final class SyncStateProvider
    extends $NotifierProvider<SyncState, List<SyncError>> {
  /// Global sync state provider
  /// Tracks sync errors from various sources and provides overall status
  const SyncStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncStateHash();

  @$internal
  @override
  SyncState create() => SyncState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SyncError> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SyncError>>(value),
    );
  }
}

String _$syncStateHash() => r'6c243d57c8312afdc14bfd2f2c62a41ba32a118f';

/// Global sync state provider
/// Tracks sync errors from various sources and provides overall status

abstract class _$SyncState extends $Notifier<List<SyncError>> {
  List<SyncError> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<SyncError>, List<SyncError>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<SyncError>, List<SyncError>>,
              List<SyncError>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Convenience provider for just the status

@ProviderFor(syncStatus)
const syncStatusProvider = SyncStatusProvider._();

/// Convenience provider for just the status

final class SyncStatusProvider
    extends $FunctionalProvider<SyncStatus, SyncStatus, SyncStatus>
    with $Provider<SyncStatus> {
  /// Convenience provider for just the status
  const SyncStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncStatusHash();

  @$internal
  @override
  $ProviderElement<SyncStatus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncStatus create(Ref ref) {
    return syncStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncStatus>(value),
    );
  }
}

String _$syncStatusHash() => r'6ffb83b486d0395edb3ff476b1fec3efe89ce5ce';

/// Error count provider

@ProviderFor(syncErrorCount)
const syncErrorCountProvider = SyncErrorCountProvider._();

/// Error count provider

final class SyncErrorCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Error count provider
  const SyncErrorCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncErrorCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncErrorCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return syncErrorCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$syncErrorCountHash() => r'10cc591a30ffaa15b4cfbb65e26fa6e0580e6c74';

/// Pending offline actions count provider
/// Shows how many actions are waiting to be synced (uses Drift)

@ProviderFor(pendingActionsCount)
const pendingActionsCountProvider = PendingActionsCountProvider._();

/// Pending offline actions count provider
/// Shows how many actions are waiting to be synced (uses Drift)

final class PendingActionsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Pending offline actions count provider
  /// Shows how many actions are waiting to be synced (uses Drift)
  const PendingActionsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingActionsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingActionsCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return pendingActionsCount(ref);
  }
}

String _$pendingActionsCountHash() =>
    r'1e73e9db49d79273bb84305602196f824479b885';
