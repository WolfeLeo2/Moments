import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';

/// Chapter header for the Memory Lane timeline
/// Displays temporal groupings like "Today", "Last Summer", etc.
class ChapterHeader extends StatelessWidget {
  const ChapterHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.isFirst = false,
  });

  final String title;
  final String? subtitle;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: isFirst ? 16 : 32,
        bottom: 16,
      ),
      child: Row(
        children: [
          // Timeline dot (larger for chapter headers)
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.backgroundBeige,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.dustyRose,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Chapter title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.textDark,
                        letterSpacing: 0.3,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textGray,
                        ),
                  ),
                ],
              ],
            ),
          ),
          
          // Decorative line extending from text
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.dustyRose.withOpacity(0.3),
                    AppTheme.dustyRose.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
