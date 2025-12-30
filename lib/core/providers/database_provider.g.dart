// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DatabaseInitializer)
const databaseInitializerProvider = DatabaseInitializerProvider._();

final class DatabaseInitializerProvider
    extends $AsyncNotifierProvider<DatabaseInitializer, void> {
  const DatabaseInitializerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseInitializerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseInitializerHash();

  @$internal
  @override
  DatabaseInitializer create() => DatabaseInitializer();
}

String _$databaseInitializerHash() =>
    r'656eae07e92c39be30b2d733e08c38dc19471021';

abstract class _$DatabaseInitializer extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
