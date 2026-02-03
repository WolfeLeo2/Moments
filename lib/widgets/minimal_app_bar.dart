import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Minimal app bar with just title and avatar
/// Other actions moved to bottom navigation or FAB
class MinimalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onProfilePressed;
  final String? profileImageUrl;
  final Widget? leading;
  final List<Widget>? actions;

  const MinimalAppBar({
    super.key,
    required this.title,
    this.onProfilePressed,
    this.profileImageUrl,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundBeige.withValues(alpha: 0.9),
                AppTheme.backgroundBeige.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Leading widget (optional - for back button on sub-pages)
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 8),
                  ],
                  
                  // Title
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: GoogleFonts.bangers(
                        fontSize: 28,
                        color: AppTheme.textDark,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  
                  // Additional actions (optional)
                  if (actions != null) ...actions!,
                  
                  // Avatar (always present)
                  GestureDetector(
                    onTap: onProfilePressed,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.textDark,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: profileImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: profileImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _buildPlaceholder(),
                                errorWidget: (_, __, ___) => _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.backgroundBeige,
      child: const Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          size: 20,
          color: AppTheme.textGray,
        ),
      ),
    );
  }
}
