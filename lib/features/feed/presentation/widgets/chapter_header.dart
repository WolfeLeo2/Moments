import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/features/feed/presentation/widgets/scrapbook_elements.dart';

/// Scrapbook-style chapter header for Memory Lane.
/// Uses handwritten fonts, decorative tape/stickers, and torn-edge dividers
/// to create a personal, scrapbook-like section break.
class ChapterHeader extends StatelessWidget {
  ChapterHeader({
    super.key,
    required this.title,
    required this.memoryCount,
    this.subtitle,
    this.isFirst = false,
    this.quietMode = true,
    this.accentColor = AppTheme.coralPink,
  }) : _random = Random(title.hashCode);

  final String title;
  final int memoryCount;
  final String? subtitle;
  final bool isFirst;
  final bool quietMode;
  final Color accentColor;
  final Random _random;

  @override
  Widget build(BuildContext context) {
    if (quietMode) {
      return Padding(
        padding: EdgeInsets.only(top: isFirst ? 8 : 18, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isFirst)
              Divider(
                height: 1,
                thickness: 0.8,
                color: AppTheme.borderGray.withValues(alpha: 0.5),
              ),
            if (!isFirst) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$memoryCount',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textGray,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 2,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      );
    }

    final stickerEmoji = ScrapbookSticker.randomTravelSticker(title.hashCode);
    final washiColor = accentColor.withValues(alpha: 0.7);
    final showSticker = _random.nextDouble() > 0.3; // 70% chance
    final showWashi = _random.nextDouble() > 0.4; // 60% chance
    final rotation = (_random.nextDouble() - 0.5) * 0.05;

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 8 : 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Torn edge divider above (except first)
          if (!isFirst)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TornEdgeDivider(
                color: AppTheme.textGray.withValues(alpha: 0.08),
                height: 14,
              ),
            ),

          // Chapter title area
          Transform.rotate(
            angle: rotation,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main title content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title in bold handwritten style
                      Text(
                        title,
                        style: GoogleFonts.caveat(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                          height: 1.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.caveat(
                            fontSize: 16,
                            color: AppTheme.textGray,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],

                      const SizedBox(height: 6),

                      // Underline doodle
                      Container(
                        width: 60 + _random.nextDouble() * 40,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$memoryCount memories',
                        style: GoogleFonts.rubik(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ),

                // Decorative washi tape
                if (showWashi)
                  Positioned(
                    top: -4,
                    right: 30 + _random.nextDouble() * 50,
                    child: WashiTape(
                      color: washiColor,
                      width: 40,
                      angle: -0.1 + _random.nextDouble() * 0.2,
                    ),
                  ),

                // Sticker (positioned away from title text)
                if (showSticker)
                  Positioned(
                    top: -10,
                    right: -12,
                    child: ScrapbookSticker(
                      emoji: stickerEmoji,
                      size: 22,
                      angle: (_random.nextDouble() - 0.5) * 0.4,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
