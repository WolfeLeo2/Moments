import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';

/// Scrapbook-style timeline connector.
/// Draws a hand-drawn-feeling dashed vertical line between memory cards,
/// with small heart/star doodles at the dot position.
class TimelineConnector extends StatelessWidget {
  const TimelineConnector({
    super.key,
    required this.child,
    this.isLast = false,
    this.quietMode = true,
    this.accentColor = AppTheme.coralPink,
  });

  final Widget child;
  final bool isLast;
  final bool quietMode;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (quietMode) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 25),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: AppTheme.borderGray.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: child),
          ],
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column with scrapbook doodle dot
          SizedBox(
            width: 20,
            child: Column(
              children: [
                // Heart-shaped dot instead of plain circle
                Padding(
                  padding: const EdgeInsets.only(top: 26, left: 2),
                  child: Icon(
                    Icons.favorite,
                    size: 12,
                    color: accentColor.withValues(alpha: 0.55),
                  ),
                ),
                // Hand-drawn dashed line (if not last)
                if (!isLast)
                  Expanded(
                    child: CustomPaint(
                      painter: _ScrapbookDashedLinePainter(
                        color: accentColor.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Hand-drawn-style dashed line with slight wobble
class _ScrapbookDashedLinePainter extends CustomPainter {
  _ScrapbookDashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const dashHeight = 5.0;
    const dashSpace = 5.0;
    double startY = 6;
    final centerX = size.width / 2;

    // Slight wobble to feel hand-drawn
    int i = 0;
    while (startY < size.height - 6) {
      final wobble = (i % 3 == 0)
          ? 0.8
          : (i % 3 == 1)
          ? -0.6
          : 0.3;
      canvas.drawLine(
        Offset(centerX + wobble, startY),
        Offset(centerX - wobble, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
