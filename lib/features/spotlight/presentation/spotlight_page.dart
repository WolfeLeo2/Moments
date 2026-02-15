import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import 'stories_ring.dart';

/// Dedicated Spotlight page — stories ring + future feed content.
class SpotlightPage extends ConsumerWidget {
  const SpotlightPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // ── Header ──
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              'Spotlight',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            backgroundColor: AppTheme.backgroundBeige.withValues(alpha: 0.92),
            border: null,
          ),

          // ── Stories Ring ──
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 8, bottom: 16),
              child: StoriesRing(),
            ),
          ),

          // ── Placeholder for future spotlight feed ──
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Spotlight feed coming soon',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
