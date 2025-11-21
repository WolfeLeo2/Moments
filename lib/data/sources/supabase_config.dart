import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static late SupabaseClient _client;

  static SupabaseClient get client => _client;

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        'Supabase URL and Anon Key must be provided in .env file',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
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
