// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_media_policy_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(offlineMediaPolicyService)
final offlineMediaPolicyServiceProvider = OfflineMediaPolicyServiceProvider._();

final class OfflineMediaPolicyServiceProvider
    extends
        $FunctionalProvider<
          OfflineMediaPolicyService,
          OfflineMediaPolicyService,
          OfflineMediaPolicyService
        >
    with $Provider<OfflineMediaPolicyService> {
  OfflineMediaPolicyServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineMediaPolicyServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineMediaPolicyServiceHash();

  @$internal
  @override
  $ProviderElement<OfflineMediaPolicyService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OfflineMediaPolicyService create(Ref ref) {
    return offlineMediaPolicyService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfflineMediaPolicyService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfflineMediaPolicyService>(value),
    );
  }
}

String _$offlineMediaPolicyServiceHash() =>
    r'7371d6d20cc33b25a52ddefa88a5584cb8283aa0';
