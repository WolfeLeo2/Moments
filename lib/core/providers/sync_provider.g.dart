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

String _$syncStateHash() => r'454cbdfc78c181be0a816b54fc435eb2b03ae869';

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

String _$syncStatusHash() => r'f279b4f618b90ccb9413eed356150d950a9adbd7';

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
/// Shows how many actions are waiting to be synced

@ProviderFor(pendingActionsCount)
const pendingActionsCountProvider = PendingActionsCountProvider._();

/// Pending offline actions count provider
/// Shows how many actions are waiting to be synced

final class PendingActionsCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Pending offline actions count provider
  /// Shows how many actions are waiting to be synced
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
    r'6c707d92c250a43cc8cf6434675c9878491199e1';

/// Provider for PendingActionService

@ProviderFor(pendingActionService)
const pendingActionServiceProvider = PendingActionServiceProvider._();

/// Provider for PendingActionService

final class PendingActionServiceProvider
    extends
        $FunctionalProvider<
          PendingActionService,
          PendingActionService,
          PendingActionService
        >
    with $Provider<PendingActionService> {
  /// Provider for PendingActionService
  const PendingActionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingActionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingActionServiceHash();

  @$internal
  @override
  $ProviderElement<PendingActionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PendingActionService create(Ref ref) {
    return pendingActionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingActionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingActionService>(value),
    );
  }
}

String _$pendingActionServiceHash() =>
    r'fe1ee546e2f1774a2c8a1b1768f977d8a6171e7d';
