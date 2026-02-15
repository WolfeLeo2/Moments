import 'package:flutter/material.dart';

/// Segmented progress bar for stories — shows one segment per story
/// from the current user. The active segment animates from 0→1.
class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.progress,
  });

  /// Total number of story segments.
  final int count;

  /// Index of the currently active segment.
  final int currentIndex;

  /// Animation progress of the active segment (0.0 → 1.0).
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        return Expanded(
          child: Container(
            height: 2.5,
            margin: EdgeInsets.only(right: index < count - 1 ? 4 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: index < currentIndex
                  ? 1.0 // completed
                  : index == currentIndex
                      ? progress.clamp(0.0, 1.0) // active
                      : 0.0, // upcoming
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
