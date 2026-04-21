// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moments_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Moments repository provider - singleton

@ProviderFor(momentRepository)
const momentRepositoryProvider = MomentRepositoryProvider._();

/// Moments repository provider - singleton

final class MomentRepositoryProvider
    extends
        $FunctionalProvider<
          MomentRepository,
          MomentRepository,
          MomentRepository
        >
    with $Provider<MomentRepository> {
  /// Moments repository provider - singleton
  const MomentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'momentRepositoryProvider',
        isAutoDispose: false,
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

String _$momentRepositoryHash() => r'e3a4e7611614ce44fd3dfadea702a6d9febc256b';

/// Stream of all moments from PowerSync local SQLite.

@ProviderFor(momentsStream)
const momentsStreamProvider = MomentsStreamProvider._();

/// Stream of all moments from PowerSync local SQLite.

final class MomentsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Moment>>,
          List<Moment>,
          Stream<List<Moment>>
        >
    with $FutureModifier<List<Moment>>, $StreamProvider<List<Moment>> {
  /// Stream of all moments from PowerSync local SQLite.
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

String _$momentsStreamHash() => r'de0aee042823ce4be71a4b3314eeaecda312ba0b';

/// Stream of shared moments from PowerSync local SQLite.

@ProviderFor(sharedMomentsStream)
const sharedMomentsStreamProvider = SharedMomentsStreamProvider._();

/// Stream of shared moments from PowerSync local SQLite.

final class SharedMomentsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Moment>>,
          List<Moment>,
          Stream<List<Moment>>
        >
    with $FutureModifier<List<Moment>>, $StreamProvider<List<Moment>> {
  /// Stream of shared moments from PowerSync local SQLite.
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
    r'bd993b53dc9075ec0a33ae75114421d3b8cb058c';

/// Stream of pending moment invitations from PowerSync local SQLite.

@ProviderFor(pendingMomentInvitationsStream)
const pendingMomentInvitationsStreamProvider =
    PendingMomentInvitationsStreamProvider._();

/// Stream of pending moment invitations from PowerSync local SQLite.

final class PendingMomentInvitationsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MomentContributor>>,
          List<MomentContributor>,
          Stream<List<MomentContributor>>
        >
    with
        $FutureModifier<List<MomentContributor>>,
        $StreamProvider<List<MomentContributor>> {
  /// Stream of pending moment invitations from PowerSync local SQLite.
  const PendingMomentInvitationsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingMomentInvitationsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingMomentInvitationsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<MomentContributor>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MomentContributor>> create(Ref ref) {
    return pendingMomentInvitationsStream(ref);
  }
}

String _$pendingMomentInvitationsStreamHash() =>
    r'aee8adcb66020ad6b86deebd36f224f75be19fc0';

/// Stream moments by group ID from PowerSync local SQLite.

@ProviderFor(momentsByGroupStream)
const momentsByGroupStreamProvider = MomentsByGroupStreamFamily._();

/// Stream moments by group ID from PowerSync local SQLite.

final class MomentsByGroupStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Moment>>,
          List<Moment>,
          Stream<List<Moment>>
        >
    with $FutureModifier<List<Moment>>, $StreamProvider<List<Moment>> {
  /// Stream moments by group ID from PowerSync local SQLite.
  const MomentsByGroupStreamProvider._({
    required MomentsByGroupStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'momentsByGroupStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$momentsByGroupStreamHash();

  @override
  String toString() {
    return r'momentsByGroupStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Moment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Moment>> create(Ref ref) {
    final argument = this.argument as String;
    return momentsByGroupStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MomentsByGroupStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$momentsByGroupStreamHash() =>
    r'0b1add544561ce14616d456c5c686a5206714910';

/// Stream moments by group ID from PowerSync local SQLite.

final class MomentsByGroupStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Moment>>, String> {
  const MomentsByGroupStreamFamily._()
    : super(
        retry: null,
        name: r'momentsByGroupStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream moments by group ID from PowerSync local SQLite.

  MomentsByGroupStreamProvider call(String groupId) =>
      MomentsByGroupStreamProvider._(argument: groupId, from: this);

  @override
  String toString() => r'momentsByGroupStreamProvider';
}

/// Single moment details from PowerSync local SQLite.

@ProviderFor(momentDetails)
const momentDetailsProvider = MomentDetailsFamily._();

/// Single moment details from PowerSync local SQLite.

final class MomentDetailsProvider
    extends $FunctionalProvider<AsyncValue<Moment?>, Moment?, FutureOr<Moment?>>
    with $FutureModifier<Moment?>, $FutureProvider<Moment?> {
  /// Single moment details from PowerSync local SQLite.
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

String _$momentDetailsHash() => r'325c24f32d3b4b8fd954c14bec12a4caf61b4e19';

/// Single moment details from PowerSync local SQLite.

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

  /// Single moment details from PowerSync local SQLite.

  MomentDetailsProvider call(String momentId) =>
      MomentDetailsProvider._(argument: momentId, from: this);

  @override
  String toString() => r'momentDetailsProvider';
}

/// Realtime stream of reactions for a specific moment from PowerSync local SQLite.

@ProviderFor(reactionsForMoment)
const reactionsForMomentProvider = ReactionsForMomentFamily._();

/// Realtime stream of reactions for a specific moment from PowerSync local SQLite.

final class ReactionsForMomentProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MomentReaction>>,
          List<MomentReaction>,
          Stream<List<MomentReaction>>
        >
    with
        $FutureModifier<List<MomentReaction>>,
        $StreamProvider<List<MomentReaction>> {
  /// Realtime stream of reactions for a specific moment from PowerSync local SQLite.
  const ReactionsForMomentProvider._({
    required ReactionsForMomentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'reactionsForMomentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reactionsForMomentHash();

  @override
  String toString() {
    return r'reactionsForMomentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MomentReaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MomentReaction>> create(Ref ref) {
    final argument = this.argument as String;
    return reactionsForMoment(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReactionsForMomentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reactionsForMomentHash() =>
    r'5aacf074fcbce50b793af5b089fba1e930c4f04d';

/// Realtime stream of reactions for a specific moment from PowerSync local SQLite.

final class ReactionsForMomentFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MomentReaction>>, String> {
  const ReactionsForMomentFamily._()
    : super(
        retry: null,
        name: r'reactionsForMomentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Realtime stream of reactions for a specific moment from PowerSync local SQLite.

  ReactionsForMomentProvider call(String momentId) =>
      ReactionsForMomentProvider._(argument: momentId, from: this);

  @override
  String toString() => r'reactionsForMomentProvider';
}
