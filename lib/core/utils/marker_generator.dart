import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

class MarkerGenerator {
  /// Draw a marker directly with Canvas to avoid layout pipeline issues.
  /// This approach is stable for background generation (no RenderView hacking).
  static Future<BitmapDescriptor> _drawMarker({
    required int count,
    required ui.Image? image,
    double scale = 3.0,
    double logicalSize = 160.0, // default larger size
  }) async {
    // Logical size of marker content (proportional metrics)
    final double baseSize = logicalSize; // main square
    final double padding = logicalSize * 0.06; // ~10 at 160
    final double badgeHeight = logicalSize * 0.18; // ~29 at 160
    final double totalWidth = baseSize + padding * 2;
    final double totalHeight = baseSize + padding * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, totalWidth, totalHeight));

    // Background (white card with border + shadow offset style)
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(padding, padding, baseSize, baseSize),
      Radius.circular(logicalSize * 0.08),
    );

    // Shadow (simple offset rectangle for brutalist style toned down)
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.12);
    canvas.drawRRect(
      cardRect.shift(Offset(logicalSize * 0.02, logicalSize * 0.02)),
      shadowPaint,
    );

    // Card background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(cardRect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = logicalSize * 0.015; // ~2.4 at 160
    canvas.drawRRect(cardRect, borderPaint);

    // Image (cover)
  final inset = logicalSize * 0.02; // ~3.2 at 160
  final imageRect = Rect.fromLTWH(padding + inset, padding + inset, baseSize - inset * 2, baseSize - inset * 2);
    if (image != null) {
      paintImage(
        canvas: canvas,
        rect: imageRect,
        image: image,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      );
    } else {
      final placeholderPaint = Paint()..color = const Color(0xFFE0E0E0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(imageRect, Radius.circular(logicalSize * 0.06)),
        placeholderPaint,
      );
      final iconPainter = TextPainter(
        text: const TextSpan(
          text: '🖼️',
          style: TextStyle(fontSize: 28),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        Offset(
          imageRect.center.dx - iconPainter.width / 2,
          imageRect.center.dy - iconPainter.height / 2,
        ),
      );
    }

    // Badge
    if (count > 1) {
      final badgeWidth = logicalSize * 0.22; // ~35 at 160
      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          totalWidth - (padding + badgeWidth),
          padding * 0.3,
          badgeWidth,
          badgeHeight,
        ),
        Radius.circular(logicalSize * 0.09),
      );
      final badgePaint = Paint()..color = const Color(0xFF2563EB);
      canvas.drawRRect(badgeRect, badgePaint);
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = logicalSize * 0.015,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '$count',
          style: TextStyle(
            color: Colors.white,
            fontSize: logicalSize * 0.09, // ~14 at 160
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        maxLines: 1,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          badgeRect.center.dx - tp.width / 2,
            badgeRect.center.dy - tp.height / 2,
        ),
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (totalWidth * scale).toInt(),
      (totalHeight * scale).toInt(),
    );
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  static Future<ui.Image?> _loadNetworkImage(String url) async {
    if (url.isEmpty) return null;
    try {
      final networkImage = NetworkImage(url);
      final completer = Completer<ImageInfo>();
      final stream = networkImage.resolve(const ImageConfiguration());
      ImageStreamListener? listener;
      listener = ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info);
        stream.removeListener(listener!);
      }, onError: (error, stack) {
        if (!completer.isCompleted) completer.completeError(error, stack);
        stream.removeListener(listener!);
      });
      stream.addListener(listener);
      final imageInfo = await completer.future.timeout(const Duration(seconds: 5));
      return imageInfo.image;
    } catch (_) {
      return null; // Fallback to placeholder
    }
  }

  /// Public API: create marker (network image + count badge)
  static Future<BitmapDescriptor> createMomentMarker({
    required String imageUrl,
    int count = 1,
    double logicalSize = 160.0,
    double scale = 3.0,
  }) async {
    final img = await _loadNetworkImage(imageUrl);
    try {
      return await _drawMarker(count: count, image: img, logicalSize: logicalSize, scale: scale);
    } catch (e, st) {
      debugPrint('Marker drawing failed, falling back. Error: $e\n$st');
      // Fallback: simple circle marker
      final fallbackSize = logicalSize * scale;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, fallbackSize, fallbackSize));
      final paint = Paint()..color = const Color(0xFF222222);
      canvas.drawCircle(Offset(fallbackSize / 2, fallbackSize / 2), fallbackSize / 2 - 4, paint);
      final picture = recorder.endRecording();
      final img2 = await picture.toImage(fallbackSize.toInt(), fallbackSize.toInt());
      final bytes = await img2.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    }
  }

  /// Recommend an anchor Y value so the map position aligns with the bottom of the card,
  /// not the bottom of the bitmap (which includes padding and shadow).
  /// Keep this in sync with the proportional metrics above (padding = size * 0.06).
  static double recommendedAnchorY({double logicalSize = 160.0}) {
    final double padding = logicalSize * 0.06;
    final double totalHeight = logicalSize + 2 * padding;
    final double bottomOfCard = padding + logicalSize;
    return bottomOfCard / totalHeight;
  }
}
