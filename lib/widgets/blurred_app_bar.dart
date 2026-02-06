import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_m3shapes_extended/flutter_m3shapes_extended.dart';
import '../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

/// Modern glassmorphic app bar with avatar popup menu and notification bell
/// Simplified version: Friends, Title, Notifications, Profile
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
  Widget _buildBadge(int count) {
    if (count <= 0) return const SizedBox.shrink();
    return Positioned(
      right: 6,
      top: 6,
      child: Badge(
        padding: const EdgeInsets.all(4),
        child: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

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
                  // Add Friends Button
                  IconButton(
                    onPressed: widget.onFriendsPressed,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAddTeam,
                      color: Colors.black,
                      size: 28,
                    ),
                    tooltip: 'Add Friends',
                  ),

                  // Title (CENTERED)
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.title.toUpperCase(),
                        style: GoogleFonts.rubikDoodleShadow(
                          textStyle: Theme.of(context).textTheme.headlineLarge,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Notifications Button
                  Stack(
                    children: [
                      IconButton(
                        onPressed: widget.onNotificationsPressed,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedNotification01,
                          color: Colors.black87,
                          size: 26,
                        ),
                      ),
                      _buildBadge(widget.notificationCount),
                    ],
                  ),

                  // Avatar (RIGHT)
                  GestureDetector(
                    onTap: widget.onProfilePressed,
                    child: M3Container.l8LeafClover(
                      width: 40,
                      height: 40,
                      border: BorderSide(color: Colors.black, width: 1),
                      child: widget.profileImageUrl != null
                          ? M3Container.l8LeafClover(
                              child: CachedNetworkImage(
                                imageUrl: widget.profileImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser02,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser02,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          : M3Container.l8LeafClover(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedUser02,
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
