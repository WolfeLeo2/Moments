import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static late SupabaseClient _client;

  static SupabaseClient get client => _client;

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    // New-style publishable key (sb_publishable_…); passed as `anonKey` since the
    // SDK param name is legacy. It resolves to the `anon`/`authenticated` role.
    final supabasePublishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];

    if (supabaseUrl == null || supabasePublishableKey == null) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY must be provided in .env file',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      // supabase_flutter 2.15+ exposes `publishableKey` (replaces the deprecated
      // `anonKey`). Same value either way — the publishable key from .env.
      publishableKey: supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
      debug: false,
    );

    _client = Supabase.instance.client;
  }

  static String get momentsTableName => 'moments';
  static String get momentsBucketName => 'moments';

  // Helper methods
  static SupabaseQueryBuilder get momentsTable =>
      _client.from(momentsTableName);
  static SupabaseStorageClient get storage => _client.storage;
  static StorageFileApi get momentsBucket => storage.from(momentsBucketName);
}
