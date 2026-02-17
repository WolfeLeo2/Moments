// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single source of truth for Supabase client — all repos/services inject from here.

@ProviderFor(supabaseClient)
const supabaseClientProvider = SupabaseClientProvider._();

/// Single source of truth for Supabase client — all repos/services inject from here.

final class SupabaseClientProvider
    extends $FunctionalProvider<SupabaseClient, SupabaseClient, SupabaseClient>
    with $Provider<SupabaseClient> {
  /// Single source of truth for Supabase client — all repos/services inject from here.
  const SupabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient create(Ref ref) {
    return supabaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient>(value),
    );
  }
}

String _$supabaseClientHash() => r'20d844b7f9a4ef39908f2009fe394f4fa679a3d2';

/// Drift database singleton provider
/// Provides type-safe, reactive database access

@ProviderFor(appDatabase)
const appDatabaseProvider = AppDatabaseProvider._();

/// Drift database singleton provider
/// Provides type-safe, reactive database access

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Drift database singleton provider
  /// Provides type-safe, reactive database access
  const AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'448adad5717e7b1c0b3ca3ca7e03d0b2116237af';

/// Database initialization provider
/// Ensures Supabase and local SQLite databases are ready

@ProviderFor(DatabaseInitializer)
const databaseInitializerProvider = DatabaseInitializerProvider._();

/// Database initialization provider
/// Ensures Supabase and local SQLite databases are ready
final class DatabaseInitializerProvider
    extends $AsyncNotifierProvider<DatabaseInitializer, void> {
  /// Database initialization provider
  /// Ensures Supabase and local SQLite databases are ready
  const DatabaseInitializerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseInitializerProvider',
        isAutoDispose: false,
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
    r'315f6909dc726c075e75198770ab4c1277ac9149';

/// Database initialization provider
/// Ensures Supabase and local SQLite databases are ready

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

/// Provider for checking if database is ready

@ProviderFor(isDatabaseReady)
const isDatabaseReadyProvider = IsDatabaseReadyProvider._();

/// Provider for checking if database is ready

final class IsDatabaseReadyProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider for checking if database is ready
  const IsDatabaseReadyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isDatabaseReadyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isDatabaseReadyHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isDatabaseReady(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isDatabaseReadyHash() => r'40a1f28b5e0423d2cac130301d3dc507490e41b8';
