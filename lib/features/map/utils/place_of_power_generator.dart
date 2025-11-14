import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../data/models/moment.dart';

class PlaceOfPowerGenerator {
  static Future<Uint8List> generatePlaceOfPowerMarker({
    required List<Moment> moments,
    required String placeName,
    required List<String> contributorAvatars,
    bool showPlaceSticker = true,
  }) async {
    const containerWidth = 180.0;
    const containerHeight = 200.0;
    const cardWidth = 90.0;
    const cardHeight = 120.0;
    const maxCardsToShow = 5; // Show 5 cards max

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw card stack (5 cards with unique rotations)
    final cardsToShow = moments.take(maxCardsToShow).toList();

    // Batch fetch signed URLs for all media paths
    final mediaPaths = cardsToShow
        .where((m) => m.mediaPath?.isNotEmpty == true)
        .map((m) => m.mediaPath!)
        .toList();
    final signedUrls = await SignedUrlCache.getSignedUrlsBatch(mediaPaths);

    // Resolve URLs for each moment
    final resolvedUrls = <String, String?>{};
    for (final moment in cardsToShow) {
      String? url;

      // Use media_path with signed URL (new approach)
      if (moment.mediaPath?.isNotEmpty == true) {
        url = signedUrls[moment.mediaPath];
      }

      // Fallback to image_url for old data
      if (url == null && moment.imageUrl?.isNotEmpty == true) {
        url = moment.imageUrl;
      }

      resolvedUrls[moment.id] = url;
    }

    // Draw cards from back to front with unique rotations
    for (int i = cardsToShow.length - 1; i >= 0; i--) {
      final moment = cardsToShow[i];
      final stackIndex = cardsToShow.length - 1 - i; // 0=back, 4=front
      final rotation = _getRotation(stackIndex, moment.id);
      final offset = _getOffset(stackIndex, moment.id);

      await _drawPhotoCard(
        canvas,
        moment,
        resolvedUrls[moment.id],
        containerWidth / 2 + offset.dx,
        containerHeight / 2 + offset.dy - 20,
        cardWidth,
        cardHeight,
        rotation,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      containerWidth.toInt(),
      containerHeight.toInt(),
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // Generate unique rotation based on moment ID and stack position
  static double _getRotation(int stackIndex, String momentId) {
    final seed = momentId.hashCode;
    final random = math.Random(seed + stackIndex);

    switch (stackIndex) {
      case 0: // Back card
        return (-12 + random.nextDouble() * 8) * math.pi / 180; // -12 to -4°
      case 1: // Middle-back
        return (-2 + random.nextDouble() * 10) * math.pi / 180; // -2 to 8°
      case 2: // Middle
        return (-4 + random.nextDouble() * 7) * math.pi / 180; // -4 to 3°
      case 3: // Middle-front
        return (-3 + random.nextDouble() * 6) * math.pi / 180; // -3 to 3°
      case 4: // Front
        return (-2 + random.nextDouble() * 4) * math.pi / 180; // -2 to 2°
      default:
        return 0;
    }
  }

  static Offset _getOffset(int stackIndex, String momentId) {
    final seed = momentId.hashCode;
    final random = math.Random(seed + stackIndex);

    switch (stackIndex) {
      case 0: // Back card
        return Offset(
          -8 + random.nextDouble() * 6, // x: -8 to -2
          10 + random.nextDouble() * 5, // y: 10 to 15
        );
      case 1: // Middle-back
        return Offset(
          -1 + random.nextDouble() * 7, // x: -1 to 6
          6 + random.nextDouble() * 4, // y: 6 to 10
        );
      case 2: // Middle
        return Offset(
          -2 + random.nextDouble() * 4, // x: -2 to 2
          3 + random.nextDouble() * 3, // y: 3 to 6
        );
      case 3: // Middle-front
        return Offset(
          -1 + random.nextDouble() * 2, // x: -1 to 1
          1 + random.nextDouble() * 2, // y: 1 to 3
        );
      case 4: // Front
        return const Offset(0, 0);
      default:
        return Offset.zero;
    }
  }

  static void _drawDateBadge(
    Canvas canvas,
    List<Moment> moments,
    double x,
    double y,
  ) {
    final dates = moments.map((m) => m.timestamp).toList()..sort();
    final firstDate = dates.first;
    final lastDate = dates.last;
    final dateLabel = _formatDateRange(firstDate, lastDate);

    // Draw badge background
    final badgePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: 60, height: 24),
      const Radius.circular(12),
    );
    canvas.drawRRect(badgeRect, badgePaint);

    // Draw shadow
    canvas.drawRRect(
      badgeRect.shift(const Offset(0, 2)),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: dateLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  static String _formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${start.day}/${start.month}';
    } else if (start.year == end.year && start.month == end.month) {
      return '${start.day}-${end.day}/${start.month}';
    } else {
      return '${start.day}/${start.month}-${end.day}/${end.month}';
    }
  }

  static Future<void> _drawPhotoCard(
    Canvas canvas,
    Moment moment,
    String? imageUrl,
    double x,
    double y,
    double width,
    double height,
    double rotation,
  ) async {
    canvas.save();

    // Apply rotation
    canvas.translate(x + width / 2, y + height / 2);
    canvas.rotate(rotation);
    canvas.translate(-width / 2, -height / 2);

    // Card shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, width, height),
        const Radius.circular(4),
      ),
      shadowPaint,
    );

    // Card background (white photo background)
    final cardPaint = Paint()..color = Colors.white;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(4),
    );
    canvas.drawRRect(cardRect, cardPaint);

    // Card border (simple white border like a photo)
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    canvas.drawRRect(cardRect, borderPaint);

    // Image area (fills most of the card with small white border)
    final imageRect = Rect.fromLTWH(3, 3, width - 6, height - 6);

    try {
      if (imageUrl?.isNotEmpty == true) {
        final imageBytes = await _loadCachedNetworkImage(imageUrl!);
        if (imageBytes != null) {
          final codec = await ui.instantiateImageCodec(imageBytes);
          final frame = await codec.getNextFrame();
          canvas.drawImageRect(
            frame.image,
            Rect.fromLTWH(
              0,
              0,
              frame.image.width.toDouble(),
              frame.image.height.toDouble(),
            ),
            imageRect,
            Paint(),
          );
        } else {
          _drawImagePlaceholder(canvas, imageRect);
        }
      } else {
        _drawImagePlaceholder(canvas, imageRect);
      }
    } catch (e) {
      _drawImagePlaceholder(canvas, imageRect);
    }

    canvas.restore();
  }

  static Future<void> _drawPlaceSticker(
    Canvas canvas,
    String placeName,
    double x,
    double y,
  ) async {
    // Sticker background (bright yellow like in reference)
    final stickerPaint = Paint()..color = AppTheme.brightYellow;
    final stickerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, 75, 25),
      const Radius.circular(12),
    );
    canvas.drawRRect(stickerRect, stickerPaint);

    // Sticker border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 2;
    canvas.drawRRect(stickerRect, borderPaint);

    // Sticker text
    final textPainter = TextPainter(
      text: TextSpan(
        text: placeName.toUpperCase(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    textPainter.layout(maxWidth: 70);
    textPainter.paint(
      canvas,
      Offset(
        x + (75 - textPainter.width) / 2,
        y + (25 - textPainter.height) / 2,
      ),
    );
  }

  static Future<void> _drawContributorAvatars(
    Canvas canvas,
    List<String> avatarUrls,
    double x,
    double y,
  ) async {
    const avatarSize = 20.0;
    const overlap = 8.0;
    final maxAvatars = 3;

    final avatarsToShow = avatarUrls.take(maxAvatars).toList();

    for (int i = 0; i < avatarsToShow.length; i++) {
      final avatarX = x - i * overlap;

      // Avatar background circle
      final avatarPaint = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(avatarX, y + avatarSize / 2),
        avatarSize / 2 + 1,
        avatarPaint,
      );

      // Avatar border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black
        ..strokeWidth = 1.5;
      canvas.drawCircle(
        Offset(avatarX, y + avatarSize / 2),
        avatarSize / 2,
        borderPaint,
      );

      // Try to load avatar image
      try {
        final avatarBytes = await _loadCachedNetworkImage(avatarsToShow[i]);
        if (avatarBytes != null) {
          final codec = await ui.instantiateImageCodec(avatarBytes);
          final frame = await codec.getNextFrame();

          canvas.save();
          canvas.clipRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(avatarX, y + avatarSize / 2),
                width: avatarSize,
                height: avatarSize,
              ),
              Radius.circular(avatarSize / 2),
            ),
          );

          canvas.drawImageRect(
            frame.image,
            Rect.fromLTWH(
              0,
              0,
              frame.image.width.toDouble(),
              frame.image.height.toDouble(),
            ),
            Rect.fromCenter(
              center: Offset(avatarX, y + avatarSize / 2),
              width: avatarSize,
              height: avatarSize,
            ),
            Paint(),
          );

          canvas.restore();
        }
      } catch (e) {
        // Draw placeholder avatar
        final placeholderPaint = Paint()
          ..color = AppTheme.primaryBlue.withOpacity(0.3);
        canvas.drawCircle(
          Offset(avatarX, y + avatarSize / 2),
          avatarSize / 2,
          placeholderPaint,
        );
      }
    }

    // Show count if more avatars exist
    if (avatarUrls.length > maxAvatars) {
      final countX = x - maxAvatars * overlap;
      final countPaint = Paint()..color = AppTheme.neonPink;
      canvas.drawCircle(
        Offset(countX, y + avatarSize / 2),
        avatarSize / 2,
        countPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '+${avatarUrls.length - maxAvatars}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          countX - textPainter.width / 2,
          y + avatarSize / 2 - textPainter.height / 2,
        ),
      );
    }
  }

  static void _drawImagePlaceholder(Canvas canvas, Rect imageRect) {
    final placeholderPaint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(0.1);
    canvas.drawRect(imageRect, placeholderPaint);

    // Draw camera icon placeholder
    final iconPainter = TextPainter(
      text: const TextSpan(text: '📷', style: TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        imageRect.center.dx - iconPainter.width / 2,
        imageRect.center.dy - iconPainter.height / 2,
      ),
    );
  }

  static Future<Uint8List?> _loadCachedNetworkImage(String url) async {
    try {
      // This would ideally use cached_network_image's cache
      // For now, we'll use basic network loading
      final response = await NetworkAssetBundle(Uri.parse(url)).load(url);
      return response.buffer.asUint8List();
    } catch (e) {
      debugPrint('Failed to load cached image: $e');
      return null;
    }
  }
}
