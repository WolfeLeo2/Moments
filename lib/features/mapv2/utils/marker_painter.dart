import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:moments/core/services/app_logger.dart';

final _log = AppLogger('MarkerPainter');

/// Paints teardrop-shaped map pins with circular avatar insets.
///
/// Rasterises a ~80×100 image that can be passed directly to
/// `PointAnnotationOptions.image` for native Mapbox annotations.
/// Results are cached per [cacheKey] so each unique avatar is only
/// painted once.
class MarkerPainter {
  MarkerPainter._();

  static final Map<String, Uint8List> _cache = {};

  /// Total pixel width/height of the output image.
  static const double _width = 80;
  static const double _height = 100;

  /// Returns cached image bytes for [cacheKey], or `null`.
  static Uint8List? getCached(String cacheKey) => _cache[cacheKey];

  /// Clears all cached marker images.
  static void clearCache() => _cache.clear();

  /// Build a teardrop pin image with the given [avatarBytes].
  ///
  /// * [avatarBytes] – raw decoded image bytes (JPEG/PNG).
  /// * [cacheKey]    – typically userId; skips work if already cached.
  /// * [strokeColor] – colour of the outer ring (defaults to white).
  /// * [pinColor]    – fill colour of the teardrop body.
  static Future<Uint8List?> buildTeardropPin({
    required Uint8List avatarBytes,
    required String cacheKey,
    ui.Color strokeColor = const ui.Color(0xFFFFFFFF),
    ui.Color pinColor = const ui.Color(0xFF007AFF),
  }) async {
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      // Decode avatar image
      final codec = await ui.instantiateImageCodec(
        avatarBytes,
        targetWidth: 64,
        targetHeight: 64,
      );
      final frame = await codec.getNextFrame();
      final avatarImage = frame.image;

      final bytes = await _paint(avatarImage, strokeColor, pinColor);
      avatarImage.dispose();

      if (bytes != null) _cache[cacheKey] = bytes;
      return bytes;
    } catch (e) {
      _log.e('Failed to build teardrop pin: $e');
      return null;
    }
  }

  /// Build a simple teardrop pin without an avatar (fallback).
  static Future<Uint8List?> buildDefaultPin({
    ui.Color pinColor = const ui.Color(0xFF007AFF),
    ui.Color dotColor = const ui.Color(0xFFFFFFFF),
  }) async {
    const key = '__default__';
    if (_cache.containsKey(key)) return _cache[key]!;

    try {
      final bytes = await _paint(null, dotColor, pinColor);
      if (bytes != null) _cache[key] = bytes;
      return bytes;
    } catch (e) {
      _log.e('Failed to build default pin: $e');
      return null;
    }
  }

  // ───────── Internal painting ─────────

  static Future<Uint8List?> _paint(
    ui.Image? avatar,
    ui.Color strokeColor,
    ui.Color pinColor,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, _width, _height));

    // ── Teardrop path ──
    // Wide circle at the top tapering to a point at the bottom-center.
    final path = ui.Path()
      ..moveTo(_width / 2, _height) // tip
      ..quadraticBezierTo(0, _height * 0.52, _width * 0.08, _height * 0.32)
      ..cubicTo(_width * 0.08, _height * 0.12, _width * 0.25, 0, _width / 2, 0)
      ..cubicTo(
        _width * 0.75,
        0,
        _width * 0.92,
        _height * 0.12,
        _width * 0.92,
        _height * 0.32,
      )
      ..quadraticBezierTo(_width, _height * 0.52, _width / 2, _height)
      ..close();

    // Fill
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = pinColor
        ..style = ui.PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Stroke
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = strokeColor
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..isAntiAlias = true,
    );

    // ── Avatar circle (or dot fallback) ──
    const avatarRadius = 24.0;
    final center = ui.Offset(_width / 2, _height * 0.34);

    if (avatar != null) {
      // Clip to circle and draw avatar
      canvas.save();
      canvas.clipPath(
        ui.Path()
          ..addOval(ui.Rect.fromCircle(center: center, radius: avatarRadius)),
      );

      final src = ui.Rect.fromLTWH(
        0,
        0,
        avatar.width.toDouble(),
        avatar.height.toDouble(),
      );
      final dst = ui.Rect.fromCircle(center: center, radius: avatarRadius);
      canvas.drawImageRect(avatar, src, dst, ui.Paint()..isAntiAlias = true);
      canvas.restore();

      // White ring around avatar
      canvas.drawCircle(
        center,
        avatarRadius + 1.5,
        ui.Paint()
          ..color = strokeColor
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..isAntiAlias = true,
      );
    } else {
      // Simple white dot
      canvas.drawCircle(
        center,
        8,
        ui.Paint()
          ..color = strokeColor
          ..style = ui.PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }

    // ── Rasterise ──
    final picture = recorder.endRecording();
    final image = await picture.toImage(_width.toInt(), _height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  }
}
