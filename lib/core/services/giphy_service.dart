import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:moments/core/services/app_logger.dart';

final _log = AppLogger('GiphyService');

/// Giphy configuration helper.
///
/// With `giphy_get`, no upfront SDK initialization is needed.
/// The API key is passed per-call. This class is kept for
/// backward-compatible key access and logging.
class GiphyService {
  /// Get the API key from .env
  static String? get apiKey => dotenv.env['GIPHY_API_KEY'];

  /// Check if a Giphy API key is available
  static bool get isAvailable {
    final key = apiKey;
    return key != null && key.isNotEmpty;
  }

  /// Log Giphy availability (call during app startup for diagnostics)
  static void logAvailability() {
    if (isAvailable) {
      _log.i('Giphy API key found — GIF picker available');
    } else {
      _log.w('GIPHY_API_KEY not found in .env — GIF picker disabled');
    }
  }
}
