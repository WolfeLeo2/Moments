import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';

/// Timeline connector widget that draws a vertical dashed line
/// connecting memory cards in the Memory Lane view
class TimelineConnector extends StatelessWidget {
  const TimelineConnector({
    super.key,
    required this.child,
    this.isLast = false,
  });

  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 16,
            child: Column(
              children: [
                // Small dot
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 24, left: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.dustyRose.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                // Dashed line (if not last)
                if (!isLast)
                  Expanded(
                    child: CustomPaint(
                      painter: _DashedLinePainter(
                        color: AppTheme.dustyRose.withOpacity(0.3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Custom painter for drawing a dashed vertical line
class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashHeight = 6.0;
    const dashSpace = 4.0;
    double startY = 8;
    final centerX = size.width / 2;

    while (startY < size.height - 8) {
      canvas.drawLine(
        Offset(centerX, startY),
        Offset(centerX, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
