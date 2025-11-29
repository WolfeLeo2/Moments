// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moments_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Moments repository provider

@ProviderFor(momentRepository)
const momentRepositoryProvider = MomentRepositoryProvider._();

/// Moments repository provider

final class MomentRepositoryProvider
    extends
        $FunctionalProvider<
          MomentRepository,
          MomentRepository,
          MomentRepository
        >
    with $Provider<MomentRepository> {
  /// Moments repository provider
  const MomentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'momentRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$momentRepositoryHash();

  @$internal
  @override
  $ProviderElement<MomentRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MomentRepository create(Ref ref) {
    return momentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MomentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MomentRepository>(value),
    );
  }
}

String _$momentRepositoryHash() => r'24f02e1b7c50623b5eb9734aeea54b8d70efe9bd';

/// Stream of all moments (realtime)

@ProviderFor(momentsStream)
const momentsStreamProvider = MomentsStreamProvider._();

/// Stream of all moments (realtime)

final class MomentsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Moment>>,
          List<Moment>,
          Stream<List<Moment>>
        >
    with $FutureModifier<List<Moment>>, $StreamProvider<List<Moment>> {
  /// Stream of all moments (realtime)
  const MomentsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'momentsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$momentsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Moment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Moment>> create(Ref ref) {
    return momentsStream(ref);
  }
}

String _$momentsStreamHash() => r'ce78e515a2f8ba64aa4a6fba80600f76e8fb5bdb';

/// Stream of shared moments (realtime - moments user is contributor to)

@ProviderFor(sharedMomentsStream)
const sharedMomentsStreamProvider = SharedMomentsStreamProvider._();

/// Stream of shared moments (realtime - moments user is contributor to)

final class SharedMomentsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Moment>>,
          List<Moment>,
          Stream<List<Moment>>
        >
    with $FutureModifier<List<Moment>>, $StreamProvider<List<Moment>> {
  /// Stream of shared moments (realtime - moments user is contributor to)
  const SharedMomentsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedMomentsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedMomentsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Moment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Moment>> create(Ref ref) {
    return sharedMomentsStream(ref);
  }
}

String _$sharedMomentsStreamHash() =>
    r'e7d6a3bbec33565c35bf903caac695a1e2601e80';

/// Single moment details

@ProviderFor(momentDetails)
const momentDetailsProvider = MomentDetailsFamily._();

/// Single moment details

final class MomentDetailsProvider
    extends $FunctionalProvider<AsyncValue<Moment?>, Moment?, FutureOr<Moment?>>
    with $FutureModifier<Moment?>, $FutureProvider<Moment?> {
  /// Single moment details
  const MomentDetailsProvider._({
    required MomentDetailsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'momentDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$momentDetailsHash();

  @override
  String toString() {
    return r'momentDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Moment?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Moment?> create(Ref ref) {
    final argument = this.argument as String;
    return momentDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MomentDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$momentDetailsHash() => r'99b681b43479d72429c3e286547c607a196e1144';

/// Single moment details

final class MomentDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Moment?>, String> {
  const MomentDetailsFamily._()
    : super(
        retry: null,
        name: r'momentDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Single moment details

  MomentDetailsProvider call(String momentId) =>
      MomentDetailsProvider._(argument: momentId, from: this);

  @override
  String toString() => r'momentDetailsProvider';
}
