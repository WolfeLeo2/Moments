// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moments_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Moment storage service provider

@ProviderFor(momentStorage)
const momentStorageProvider = MomentStorageProvider._();

/// Moment storage service provider

final class MomentStorageProvider
    extends
        $FunctionalProvider<
          MomentStorageService,
          MomentStorageService,
          MomentStorageService
        >
    with $Provider<MomentStorageService> {
  /// Moment storage service provider
  const MomentStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'momentStorageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$momentStorageHash();

  @$internal
  @override
  $ProviderElement<MomentStorageService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MomentStorageService create(Ref ref) {
    return momentStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MomentStorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MomentStorageService>(value),
    );
  }
}

String _$momentStorageHash() => r'889ab6d9528dd7af2002c80267ff3c133ed47e2f';

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

/// Stream of all moments with offline-first approach
/// 1. Immediately yields cached moments from SQLite
/// 2. Then syncs with Supabase and yields updated moments

@ProviderFor(momentsStream)
const momentsStreamProvider = MomentsStreamProvider._();

/// Stream of all moments with offline-first approach
/// 1. Immediately yields cached moments from SQLite
/// 2. Then syncs with Supabase and yields updated moments

final class MomentsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Moment>>,
          List<Moment>,
          Stream<List<Moment>>
        >
    with $FutureModifier<List<Moment>>, $StreamProvider<List<Moment>> {
  /// Stream of all moments with offline-first approach
  /// 1. Immediately yields cached moments from SQLite
  /// 2. Then syncs with Supabase and yields updated moments
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

String _$momentsStreamHash() => r'97f0faa1f792bd8d95e935ee55dd7c56a6d7ce1c';

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

/// Stream of pending moment invitations (realtime)

@ProviderFor(pendingMomentInvitationsStream)
const pendingMomentInvitationsStreamProvider =
    PendingMomentInvitationsStreamProvider._();

/// Stream of pending moment invitations (realtime)

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
  /// Stream of pending moment invitations (realtime)
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
    r'ea94e663106843875fc7d166901bbb67105d17c2';

/// Stream moments by group ID (realtime for moment details page)

@ProviderFor(momentsByGroupStream)
const momentsByGroupStreamProvider = MomentsByGroupStreamFamily._();

/// Stream moments by group ID (realtime for moment details page)

final class MomentsByGroupStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Moment>>,
          List<Moment>,
          Stream<List<Moment>>
        >
    with $FutureModifier<List<Moment>>, $StreamProvider<List<Moment>> {
  /// Stream moments by group ID (realtime for moment details page)
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
    r'f81251f0c23557e405824d49c75fdbea95a8f8d1';

/// Stream moments by group ID (realtime for moment details page)

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

  /// Stream moments by group ID (realtime for moment details page)

  MomentsByGroupStreamProvider call(String groupId) =>
      MomentsByGroupStreamProvider._(argument: groupId, from: this);

  @override
  String toString() => r'momentsByGroupStreamProvider';
}

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

String _$momentDetailsHash() => r'71d51b61e904bbefa256d97c6a2cecbf4d1a080b';

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
