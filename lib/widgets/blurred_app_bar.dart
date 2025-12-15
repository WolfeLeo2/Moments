import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern glassmorphic app bar with avatar popup menu and notification bell
class BlurredAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onFriendsPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onGalleryPressed;
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
    this.onGalleryPressed,
    this.profileImageUrl,
    this.notificationCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<BlurredAppBar> createState() => _BlurredAppBarState();
}

class _BlurredAppBarState extends State<BlurredAppBar> {
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
                AppTheme.backgroundBeige.withValues(alpha: 0.85),
                AppTheme.backgroundBeige.withValues(alpha: 0.45),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  //Add Friends Button
                  Stack(
                    children: [
                      IconButton(
                        onPressed: widget.onFriendsPressed,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedAddTeam,
                          color: Colors.black,
                          size: 30,
                        ),
                        tooltip: 'Add Friends',
                      ),
                    ],
                  ),

                  // Title (CENTERED)
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.title.toUpperCase(),
                        style: GoogleFonts.rubikDoodleShadow(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Gallery Button
                  if (widget.onGalleryPressed != null)
                    IconButton(
                      onPressed: widget.onGalleryPressed,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedDashboardSquare02,
                        color: Colors.black87,
                        size: 26,
                      ),
                      tooltip: 'Gallery',
                    ),

                  IconButton(
                    onPressed: widget.onNotificationsPressed,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedNotification01,
                      color: Colors.black87,
                      size: 26,
                    ),
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
                              color: Colors.red.withValues(alpha: 0.4),
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
                  // Avatar (RIGHT)
                  GestureDetector(
                    onTap: widget.onProfilePressed,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: widget.profileImageUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: widget.profileImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedUserMultiple,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedUser,
                                size: 24,
                                color: Colors.grey[600],
                              ),
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
}
