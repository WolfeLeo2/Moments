import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/moment.dart';

class MomentStackGenerator {
  static Future<Uint8List> generateStackedMomentMarker({
    required List<Moment> moments,
    required double size,
  }) async {
    const cardWidth = 120.0; // Much larger!
    const cardHeight = 140.0; // Much larger!
    const stackOffset = 6.0; // More visible stacking
    const maxCardsToShow = 3;

    final cardsToShow = moments.length > maxCardsToShow
        ? maxCardsToShow
        : moments.length;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw shadow for the entire stack first
    _drawStackShadow(canvas, cardsToShow, cardWidth, cardHeight, stackOffset);

    // Draw each moment card in the stack (back to front)
    for (int i = cardsToShow - 1; i >= 0; i--) {
      final moment = moments[i];
      final offset = Offset(i * stackOffset, -i * stackOffset);
      final rotation = (i * 0.05) - 0.025; // Slight rotation for realism

      await _drawPolaroidCard(
        canvas,
        moment,
        offset,
        cardWidth,
        cardHeight,
        rotation,
        i == 0, // Only show full detail for top card
      );
    }

    // Draw count badge if more than one moment
    if (moments.length > 1) {
      _drawCountBadge(
        canvas,
        moments.length,
        cardWidth,
        cardHeight,
        stackOffset,
      );
    }

    final picture = recorder.endRecording();
    final totalWidth = (cardWidth + (cardsToShow - 1) * stackOffset + 20)
        .toInt();
    final totalHeight = (cardHeight + (cardsToShow - 1) * stackOffset + 20)
        .toInt();

    final image = await picture.toImage(totalWidth, totalHeight);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawStackShadow(
    Canvas canvas,
    int cardCount,
    double width,
    double height,
    double offset,
  ) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = cardCount - 1; i >= 0; i--) {
      final shadowOffset = Offset((i * offset) + 6, (-i * offset) + 6);
      final shadowRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(shadowOffset.dx, shadowOffset.dy, width, height),
        const Radius.circular(12),
      );
      canvas.drawRRect(shadowRect, paint);
    }
  }

  static Future<void> _drawPolaroidCard(
    Canvas canvas,
    Moment moment,
    Offset offset,
    double width,
    double height,
    double rotation,
    bool isTopCard,
  ) async {
    canvas.save();

    // Apply rotation around card center
    final center = Offset(offset.dx + width / 2, offset.dy + height / 2);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-width / 2, -height / 2);

    final paint = Paint();

    // Draw white polaroid background
    paint.color = Colors.white;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(12),
    );
    canvas.drawRRect(cardRect, paint);

    // Draw thick black border (polaroid style)
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.black;
    paint.strokeWidth = 3;
    canvas.drawRRect(cardRect, paint);
    paint.style = PaintingStyle.fill;

    if (isTopCard) {
      // Image area (main photo area of polaroid)
      const imageMargin = 12.0;
      final imageRect = Rect.fromLTWH(
        imageMargin,
        imageMargin,
        width - (imageMargin * 2),
        height - 50, // Leave space for text at bottom
      );

      // Draw image background
      paint.color = Colors.grey[100]!;
      canvas.drawRect(imageRect, paint);

      try {
        if (moment.imageUrl?.isNotEmpty == true) {
          final image = await _loadNetworkImage(moment.imageUrl!);
          if (image != null) {
            // Draw the actual moment image
            final srcRect = Rect.fromLTWH(
              0,
              0,
              image.width.toDouble(),
              image.height.toDouble(),
            );
            canvas.drawImageRect(image, srcRect, imageRect, Paint());
          } else {
            _drawPlaceholderImage(canvas, imageRect);
          }
        } else {
          _drawPlaceholderImage(canvas, imageRect);
        }
      } catch (e) {
        _drawPlaceholderImage(canvas, imageRect);
      }

      // Draw image border
      paint.style = PaintingStyle.stroke;
      paint.color = Colors.grey[300]!;
      paint.strokeWidth = 1;
      canvas.drawRect(imageRect, paint);
      paint.style = PaintingStyle.fill;

      // Text area at bottom (like real polaroid)
      final textPainter = TextPainter(
        text: TextSpan(
          text: moment.title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Courier', // Typewriter style like old polaroids
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        textAlign: TextAlign.center,
      );

      textPainter.layout(maxWidth: width - 24);

      // Center the text in the bottom white space
      final textY = height - 35;
      final textX = (width - textPainter.width) / 2;

      textPainter.paint(canvas, Offset(textX, textY));
    }

    canvas.restore();
  }

  static void _drawPlaceholderImage(Canvas canvas, Rect imageRect) {
    // Gradient background
    final paint = Paint()
      ..shader = ui.Gradient.linear(imageRect.topLeft, imageRect.bottomRight, [
        AppTheme.primaryBlue.withOpacity(0.3),
        AppTheme.neonPink.withOpacity(0.1),
      ]);
    canvas.drawRect(imageRect, paint);

    // Draw camera icon
    final iconSize = imageRect.width * 0.3;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: '�',
        style: TextStyle(fontSize: iconSize),
      ),
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

  static void _drawCountBadge(
    Canvas canvas,
    int count,
    double cardWidth,
    double cardHeight,
    double stackOffset,
  ) {
    const badgeSize = 36.0; // Larger badge
    final badgeX = cardWidth - badgeSize / 2;
    final badgeY = -badgeSize / 2;

    // Badge shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(
      Offset(badgeX + 2, badgeY + 2),
      badgeSize / 2,
      shadowPaint,
    );

    // Badge background
    final paint = Paint()..color = AppTheme.neonPink;
    canvas.drawCircle(Offset(badgeX, badgeY), badgeSize / 2, paint);

    // Badge border
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.white;
    paint.strokeWidth = 3;
    canvas.drawCircle(Offset(badgeX, badgeY), badgeSize / 2, paint);

    // Inner border
    paint.color = Colors.black;
    paint.strokeWidth = 1;
    canvas.drawCircle(Offset(badgeX, badgeY), badgeSize / 2 - 2, paint);

    // Badge text
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(badgeX - textPainter.width / 2, badgeY - textPainter.height / 2),
    );
  }

  static Future<ui.Image?> _loadNetworkImage(String url) async {
    try {
      print('Loading image: $url');

      // Use HTTP client to load image
      final response = await NetworkAssetBundle(Uri.parse(url)).load(url);
      final bytes = response.buffer.asUint8List();

      if (bytes.isEmpty) {
        print('Image bytes are empty');
        return null;
      }

      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 200, // Resize for performance
        targetHeight: 200,
      );
      final frame = await codec.getNextFrame();
      print(
        'Image loaded successfully: ${frame.image.width}x${frame.image.height}',
      );
      return frame.image;
    } catch (e) {
      print('Failed to load image from $url: $e');
      return null;
    }
  }
}
