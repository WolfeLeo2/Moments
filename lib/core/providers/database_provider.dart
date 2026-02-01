import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:moments/core/services/app_logger.dart';
import 'package:moments/core/database/database.dart';
import '../../data/sources/supabase_config.dart';

part 'database_provider.g.dart';

final _log = AppLogger('DatabaseProvider');

/// Drift database singleton provider
/// Provides type-safe, reactive database access
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

/// Database initialization provider
/// Ensures Supabase and local SQLite databases are ready
@Riverpod(keepAlive: true)
class DatabaseInitializer extends _$DatabaseInitializer {
  @override
  Future<void> build() async {
    _log.d('Initializing database connections');

    // Verify Supabase is connected
    try {
      final client = SupabaseConfig.client;
      final isConnected = client.auth.currentSession != null;
      _log.i(
        'Supabase connection status: ${isConnected ? 'authenticated' : 'anonymous'}',
      );
    } catch (e) {
      _log.w('Supabase connection check failed', error: e);
    }

    state = const AsyncValue.data(null);
  }

  /// Force re-initialization of database connections
  Future<void> reinitialize() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _log.i('Re-initializing database connections');
      // Add any re-initialization logic here
    });
  }
}

/// Provider for checking if database is ready
@riverpod
bool isDatabaseReady(Ref ref) {
  final dbState = ref.watch(databaseInitializerProvider);
  return dbState.hasValue;
}
