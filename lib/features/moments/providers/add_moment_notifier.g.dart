// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_moment_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddMoment)
const addMomentProvider = AddMomentProvider._();

final class AddMomentProvider
    extends $NotifierProvider<AddMoment, AddMomentState> {
  const AddMomentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addMomentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addMomentHash();

  @$internal
  @override
  AddMoment create() => AddMoment();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddMomentState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddMomentState>(value),
    );
  }
}

String _$addMomentHash() => r'd30c270031b80ced40b2492eda43ca9fe2d362fe';

abstract class _$AddMoment extends $Notifier<AddMomentState> {
  AddMomentState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AddMomentState, AddMomentState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AddMomentState, AddMomentState>,
              AddMomentState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
