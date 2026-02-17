import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:moments/core/services/app_logger.dart';

final _log = AppLogger('GiphyPickerHelper');

/// Result returned when the user picks a GIF or sticker.
class GiphyPickResult {
  final String url;

  /// "gif" or "sticker"
  final String type;

  const GiphyPickResult({required this.url, required this.type});
}

/// Thin wrapper around `giphy_get` that opens the built-in picker sheet
/// with emojis disabled (OS keyboards already have emojis).
class GiphyPickerHelper {
  GiphyPickerHelper._();

  /// Opens the Giphy picker bottom sheet.
  ///
  /// Returns a [GiphyPickResult] with the selected media URL and type,
  /// or `null` if dismissed.
  static Future<GiphyPickResult?> pickGif(BuildContext context) async {
    final apiKey = dotenv.env['GIPHY_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      _log.w('GIPHY_API_KEY not found in .env — cannot open picker');
      return null;
    }

    try {
      final gif = await GiphyGet.getGif(
        context: context,
        apiKey: apiKey,
        lang: GiphyLanguage.english,
        showEmojis: false,
        showStickers: true,
        showGIFs: true,
        tabColor: Theme.of(context).colorScheme.primary,
      );

      if (gif == null) return null;

      // Determine the best URL to use
      final url =
          gif.images?.original?.url ?? gif.images?.fixedWidth?.url ?? gif.url;

      if (url == null || url.isEmpty) return null;

      // Determine type — giphy_get marks stickers via the `type` field
      final isSticker = gif.type == 'sticker';

      return GiphyPickResult(url: url, type: isSticker ? 'sticker' : 'gif');
    } catch (e) {
      _log.e('Error picking GIF', error: e);
      return null;
    }
  }
}
