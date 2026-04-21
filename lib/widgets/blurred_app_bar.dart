import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_m3shapes_extended/flutter_m3shapes_extended.dart';

import '../core/theme/app_theme.dart';

/// Unified transparent app bar used across all main tabs (Map, Memory Lane,
/// Discover, Chat).
///
/// Uses [AppBar.forceMaterialTransparency] so the body renders behind it —
/// pair with `Scaffold(extendBodyBehindAppBar: true)` on map pages.
///
/// The glassmorphic blur lives in [flexibleSpace]; set [transparent] = true
/// to skip the blur on pages with a solid background colour.
class BlurredAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onFriendsPressed;
  final VoidCallback? onNotificationsPressed;
  final String? profileImageUrl;
  final int notificationCount;

  /// When true the app bar is fully transparent with no blur — useful for
  /// pages where the background is a solid colour.
  final bool transparent;

  const BlurredAppBar({
    super.key,
    required this.title,
    this.onMenuPressed,
    this.onSearchPressed,
    this.onProfilePressed,
    this.onFriendsPressed,
    this.onNotificationsPressed,
    this.profileImageUrl,
    this.notificationCount = 0,
    this.transparent = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // ── helpers ──────────────────────────────────────────────────────────

  Widget _notificationIcon(int count) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: AppTheme.coralPink,
      child: IconButton(
        onPressed: onNotificationsPressed,
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedNotification01,
          color: Colors.black87,
          size: 24,
        ),
      ),
    );
  }

  Widget _avatar() {
    final placeholder = Container(
      color: Colors.grey[300],
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedUser02,
        size: 18,
        color: Colors.grey[600],
      ),
    );

    return GestureDetector(
      onTap: onProfilePressed,
      child: M3EContainer.l8LeafClover(
        width: 38,
        height: 38,
        border: BorderSide(
          color: Colors.black.withValues(alpha: 0.8),
          width: 1,
        ),
        child: profileImageUrl != null
            ? M3EContainer.l8LeafClover(
                child: CachedNetworkImage(
                  imageUrl: profileImageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => placeholder,
                  errorWidget: (_, __, ___) => placeholder,
                ),
              )
            : M3EContainer.l8LeafClover(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedUser02,
                  size: 22,
                  color: Colors.grey[600],
                ),
              ),
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppBar(
      forceMaterialTransparency: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,

      // ── blur layer ──
      flexibleSpace: transparent
          ? null
          : ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundBeige.withValues(alpha: 0.72),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black.withValues(alpha: 0.04),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

      // ── leading: Add Friends ──
      leading: IconButton(
        onPressed: onFriendsPressed,
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedAddTeam,
          color: Colors.black87,
          size: 26,
        ),
        tooltip: 'Add Friends',
      ),

      // ── title ──
      centerTitle: true,
      title: Text(
        title.toUpperCase(),
        style: GoogleFonts.rubikDoodleShadow(
          textStyle: Theme.of(context).textTheme.headlineLarge,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      ),

      // ── actions: Notifications + Avatar ──
      actions: [
        _notificationIcon(notificationCount),
        Padding(padding: const EdgeInsets.only(right: 12), child: _avatar()),
      ],
    );
  }
}
