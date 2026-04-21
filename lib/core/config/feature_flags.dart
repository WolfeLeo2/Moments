import 'package:flutter_dotenv/flutter_dotenv.dart';

class FeatureFlags {
  static String? get powerSyncUrl => _stringFromEnv('POWERSYNC_URL');

  static String? _stringFromEnv(String key) {
    final raw = dotenv.env[key]?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }
}
