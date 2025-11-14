import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modern glassmorphic app bar with avatar popup menu and notification bell
class BlurredAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onFriendsPressed;
  final VoidCallback? onNotificationsPressed;
  final String? profileImageUrl;
  final int notificationCount;

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
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<BlurredAppBar> createState() => _BlurredAppBarState();
}

class _BlurredAppBarState extends State<BlurredAppBar> {
  final GlobalKey<PopupMenuButtonState<String>> _avatarMenuKey =
      GlobalKey<PopupMenuButtonState<String>>();

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
                Colors.white.withOpacity(0.85),
                Colors.white.withOpacity(0.45),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Notification Bell (LEFT - replacing menu icon)
                  Stack(
                    children: [
                      IconButton(
                        onPressed: widget.onNotificationsPressed,
                        icon: const Icon(
                          LucideIcons.bell500,
                          color: Colors.black87,
                          size: 26,
                        ),
                        tooltip: 'Notifications',
                      ),
                      if (widget.notificationCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              widget.notificationCount > 9
                                  ? '9+'
                                  : '${widget.notificationCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Title (CENTERED)
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Avatar with BLURRED Popup Menu (RIGHT)
                  PopupMenuButton<String>(
                    key: _avatarMenuKey,
                    offset: const Offset(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    color: Colors.transparent,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.15),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: widget.profileImageUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: widget.profileImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    LucideIcons.user500,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    LucideIcons.user500,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(
                                LucideIcons.user500,
                                size: 24,
                                color: Colors.grey[600],
                              ),
                            ),
                    ),
                    onSelected: (value) {
                      if (value == 'profile' &&
                          widget.onProfilePressed != null) {
                        widget.onProfilePressed!();
                      } else if (value == 'friends' &&
                          widget.onFriendsPressed != null) {
                        widget.onFriendsPressed!();
                      } else if (value == 'settings' &&
                          widget.onMenuPressed != null) {
                        widget.onMenuPressed!();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          // Profile option
                          PopupMenuItem<String>(
                            value: 'profile',
                            height: 56,
                            child: _BlurredPopupMenuItem(
                              icon: LucideIcons.userCog500,
                              label: 'Profile',
                            ),
                          ),
                          // Friends option
                          PopupMenuItem<String>(
                            value: 'friends',
                            height: 56,
                            child: _BlurredPopupMenuItem(
                              icon: LucideIcons.heartHandshake500,
                              label: 'Friends',
                            ),
                          ),
                          const PopupMenuDivider(height: 1),
                          // Settings option
                          PopupMenuItem<String>(
                            value: 'settings',
                            height: 56,
                            child: _BlurredPopupMenuItem(
                              icon: LucideIcons.settings500,
                              label: 'Settings',
                              isLast: true,
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Blurred glassmorphic popup menu item
class _BlurredPopupMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLast;

  const _BlurredPopupMenuItem({
    required this.icon,
    required this.label,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: Colors.black87),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper widget for old unused class - kept for compatibility
class _PopupMenuItemContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLast;

  const _PopupMenuItemContent({
    required this.icon,
    required this.label,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
