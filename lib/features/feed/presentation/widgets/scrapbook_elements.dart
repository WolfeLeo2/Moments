import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moments/core/theme/app_theme.dart';

/// A collection of scrapbook-style decorative elements
/// Used across the Memory Lane timeline to create a handmade, personal feel

// ============================================
// WASHI TAPE
// ============================================

/// A washi tape strip that overlays onto photos/cards
/// Gives the illusion that a photo is "taped" to the page
class WashiTape extends StatelessWidget {
  const WashiTape({
    super.key,
    this.color,
    this.angle = 0.0,
    this.width = 60,
    this.height = 18,
  });

  final Color? color;
  final double angle;
  final double width;
  final double height;

  static const List<Color> _tapeColors = [
    Color(0xFFFF6B6B), // coral
    Color(0xFF51D88A), // mint
    Color(0xFFA78BFA), // lavender
    Color(0xFFFFAA5C), // sunset
    Color(0xFF54B7F5), // sky
    Color(0xFFFFD740), // yellow
    Color(0xFFFF4081), // pink
  ];

  /// Get a deterministic color based on a seed
  static Color colorFromSeed(int seed) {
    return _tapeColors[seed.abs() % _tapeColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final tapeColor = color ?? _tapeColors[0];
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: tapeColor.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(2),
        ),
        // Subtle pattern: thin lines
        child: CustomPaint(painter: _WashiPatternPainter(tapeColor)),
      ),
    );
  }
}

class _WashiPatternPainter extends CustomPainter {
  _WashiPatternPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // Diagonal stripes
    for (double i = -size.height; i < size.width + size.height; i += 6) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================
// PAPER CLIP
// ============================================

/// A paper clip decoration placed at the edge of a card
class PaperClip extends StatelessWidget {
  const PaperClip({super.key, this.color, this.size = 32, this.angle = -0.15});

  final Color? color;
  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size(size * 0.4, size),
        painter: _PaperClipPainter(
          color ?? AppTheme.textGray.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _PaperClipPainter extends CustomPainter {
  _PaperClipPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = w * 0.35;

    final path = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.5, h * 0.15)
      ..arcToPoint(
        Offset(w * 0.5 - r, h * 0.15 + r),
        radius: Radius.circular(r),
      )
      ..lineTo(w * 0.5 - r, h * 0.75)
      ..arcToPoint(Offset(w * 0.5 + r, h * 0.75), radius: Radius.circular(r))
      ..lineTo(w * 0.5 + r, h * 0.3)
      ..arcToPoint(
        Offset(w * 0.5, h * 0.3 - r * 0.6),
        radius: Radius.circular(r * 0.6),
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================
// LOCATION STAMP
// ============================================

/// A vintage-style circular stamp showing location + year
class LocationStamp extends StatelessWidget {
  const LocationStamp({
    super.key,
    required this.location,
    required this.year,
    this.color,
    this.size = 64,
  });

  final String location;
  final int year;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final stampColor = color ?? AppTheme.coralPink.withValues(alpha: 0.7);
    // Truncate location for stamp
    final shortLocation = location.length > 12
        ? '${location.substring(0, 10)}...'
        : location;

    return Transform.rotate(
      angle: -0.12,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: stampColor, width: 2.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              shortLocation.toUpperCase(),
              style: GoogleFonts.rubik(
                fontSize: size * 0.13,
                fontWeight: FontWeight.w900,
                color: stampColor,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
            ),
            Container(
              width: size * 0.5,
              height: 1,
              color: stampColor,
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),
            Text(
              '$year',
              style: GoogleFonts.bebasNeue(
                fontSize: size * 0.2,
                fontWeight: FontWeight.w700,
                color: stampColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// STICKER
// ============================================

/// Small emoji/icon stickers scattered as decorations
class ScrapbookSticker extends StatelessWidget {
  const ScrapbookSticker({
    super.key,
    required this.emoji,
    this.size = 24,
    this.angle = 0.0,
  });

  final String emoji;
  final double size;
  final double angle;

  /// Get a themed sticker based on location keywords
  static String stickerForLocation(String location) {
    final lower = location.toLowerCase();
    if (lower.contains('beach') ||
        lower.contains('coast') ||
        lower.contains('sea'))
      return '🏖️';
    if (lower.contains('mountain') ||
        lower.contains('hill') ||
        lower.contains('peak'))
      return '⛰️';
    if (lower.contains('lake') || lower.contains('river')) return '🌊';
    if (lower.contains('city') || lower.contains('town')) return '🏙️';
    if (lower.contains('park') ||
        lower.contains('garden') ||
        lower.contains('forest'))
      return '🌿';
    if (lower.contains('cafe') ||
        lower.contains('coffee') ||
        lower.contains('restaurant'))
      return '☕';
    if (lower.contains('airport') || lower.contains('flight')) return '✈️';
    if (lower.contains('hotel') || lower.contains('resort')) return '🏨';
    if (lower.contains('museum') || lower.contains('gallery')) return '🎨';
    if (lower.contains('temple') ||
        lower.contains('church') ||
        lower.contains('mosque'))
      return '⛪';
    // Seasonal defaults
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return '🌸';
    if (month >= 6 && month <= 8) return '☀️';
    if (month >= 9 && month <= 11) return '🍂';
    return '❄️';
  }

  /// Get a random travel sticker
  static String randomTravelSticker(int seed) {
    const stickers = [
      '📸',
      '✨',
      '🌍',
      '🎒',
      '🗺️',
      '💫',
      '🌅',
      '🎵',
      '📌',
      '💭',
    ];
    return stickers[seed.abs() % stickers.length];
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Text(emoji, style: TextStyle(fontSize: size)),
    );
  }
}

// ============================================
// TORN EDGE DIVIDER
// ============================================

/// A torn paper edge effect used as a divider between sections
class TornEdgeDivider extends StatelessWidget {
  const TornEdgeDivider({super.key, this.color, this.height = 12});

  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _TornEdgePainter(color ?? AppTheme.backgroundBeige),
    );
  }
}

class _TornEdgePainter extends CustomPainter {
  _TornEdgePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    final random = Random(42); // Fixed seed for consistent tear
    double x = 0;
    while (x < size.width) {
      final peakHeight = random.nextDouble() * size.height * 0.8;
      final segmentWidth = 8.0 + random.nextDouble() * 12.0;
      path.lineTo(x + segmentWidth / 2, peakHeight);
      x += segmentWidth;
      path.lineTo(
        x,
        size.height * 0.6 + random.nextDouble() * size.height * 0.4,
      );
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================
// RULED LINES BACKGROUND (journal paper)
// ============================================

/// Subtle horizontal ruled lines like a notebook page
class RuledLinesBackground extends StatelessWidget {
  const RuledLinesBackground({
    super.key,
    required this.child,
    this.lineSpacing = 28,
    this.lineColor,
  });

  final Widget child;
  final double lineSpacing;
  final Color? lineColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RuledLinesPainter(
        spacing: lineSpacing,
        color: lineColor ?? AppTheme.skyBlue.withValues(alpha: 0.08),
      ),
      child: child,
    );
  }
}

class _RuledLinesPainter extends CustomPainter {
  _RuledLinesPainter({required this.spacing, required this.color});

  final double spacing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
