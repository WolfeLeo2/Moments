import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/avatar_image.dart';

/// Individual avatar circle with a gradient or grey ring to indicate
/// unseen / seen story status.
class StoryAvatarRing extends StatelessWidget {
  const StoryAvatarRing({
    super.key,
    required this.userId,
    this.size = 64,
    this.hasUnseen = false,
    this.isOwn = false,
    this.hasStory = true,
  });

  final String userId;
  final double size;
  final bool hasUnseen;
  final bool isOwn;
  final bool hasStory;

  @override
  Widget build(BuildContext context) {
    // Own story with no content — show dashed "add" ring
    if (isOwn && !hasStory) {
      return _AddStoryRing(size: size, userId: userId);
    }

    final ringColor = hasUnseen
        ? null // will use gradient
        : Colors.grey.shade300;

    return Container(
      width: size + 6,
      height: size + 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasUnseen
            ? const LinearGradient(
                colors: [
                  Color(0xFF6366F1), // indigo
                  Color(0xFF8B5CF6), // violet
                  Color(0xFFEC4899), // pink
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: ringColor != null
            ? Border.all(color: ringColor, width: 2.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.backgroundBeige,
              width: 2,
            ),
          ),
          child: AvatarImage(
            userId: userId,
            size: size - 6,
            borderWidth: 0,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}

/// "Add Story" ring — dashed border with camera icon overlay.
class _AddStoryRing extends StatelessWidget {
  const _AddStoryRing({required this.size, required this.userId});

  final double size;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        children: [
          // Dashed ring
          CustomPaint(
            size: Size(size + 6, size + 6),
            painter: _DashedCirclePainter(
              color: AppTheme.primaryBlue.withValues(alpha: 0.4),
              strokeWidth: 2,
              dashCount: 20,
            ),
          ),
          // Avatar
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: AvatarImage(
                userId: userId,
                size: size - 4,
                borderWidth: 0,
                backgroundColor:
                    AppTheme.primaryBlue.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Blue plus badge
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.backgroundBeige,
                  width: 2,
                ),
              ),
              child: const Icon(
                CupertinoIcons.add,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  final Color color;
  final double strokeWidth;
  final int dashCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final dashAngle = (2 * math.pi) / dashCount;
    final gapFraction = 0.35;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashCount != dashCount;
}
