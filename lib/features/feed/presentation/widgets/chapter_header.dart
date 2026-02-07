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
    this.subtitle,
    this.isFirst = false,
  }) : _random = Random(title.hashCode);

  final String title;
  final String? subtitle;
  final bool isFirst;
  final Random _random;

  @override
  Widget build(BuildContext context) {
    final stickerEmoji = ScrapbookSticker.randomTravelSticker(title.hashCode);
    final washiColor = WashiTape.colorFromSeed(title.hashCode + 5);
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
                          color: AppTheme.coralPink.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
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
