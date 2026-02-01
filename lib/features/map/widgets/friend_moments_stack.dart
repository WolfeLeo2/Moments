import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/moment.dart';

/// Vertical overlapping avatar stack showing friends with moments in visible map area.
/// Displays up to 4 avatars stacked on top of each other with the 4th slightly blurred.
class FriendMomentsStack extends ConsumerWidget {
  final List<FriendMomentGroup> friendGroups;
  final VoidCallback onTap;

  const FriendMomentsStack({
    super.key,
    required this.friendGroups,
    required this.onTap,
  });

  static const double _avatarSize = 40.0;
  static const double _overlap = 12.0; // How much avatars overlap

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (friendGroups.isEmpty) return const SizedBox.shrink();

    final avatarCacheService = ref.watch(avatarCacheServiceProvider);
    final displayGroups = friendGroups.take(4).toList();
    final hasMore = friendGroups.length > 4;

    // Calculate total height: first avatar full + overlapping portions
    final stackHeight = _avatarSize + (_overlap * (displayGroups.length - 1));

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _avatarSize + 8, // Avatar + small padding for badge overflow
        height: stackHeight + (hasMore ? 16 : 0), // Extra for +N indicator
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Build avatars from bottom to top (last avatar at bottom)
            for (var i = displayGroups.length - 1; i >= 0; i--)
              Positioned(
                top: i * _overlap,
                left: 0,
                child: _buildAvatarItem(
                  context,
                  displayGroups[i],
                  avatarCacheService,
                  isLast: i == displayGroups.length - 1,
                  zIndex: displayGroups.length - i,
                ),
              ),
            // Show count indicator if more than 4 friends
            if (hasMore)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.electricPurple,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '+${friendGroups.length - 4}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarItem(
    BuildContext context,
    FriendMomentGroup group,
    dynamic avatarCacheService, {
    required bool isLast,
    required int zIndex,
  }) {
    Widget avatarWidget = Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: group.avatarUrl != null
            ? Image(
                image:
                    avatarCacheService.getAvatarImageProvider(
                      group.avatarUrl,
                    ) ??
                    const AssetImage('assets/images/default_avatar.png'),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(group),
              )
            : _buildPlaceholder(group),
      ),
    );

    // Apply blur effect to the last (4th) avatar for depth
    if (isLast && friendGroups.length > 3) {
      avatarWidget = ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
          child: Opacity(opacity: 0.7, child: avatarWidget),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarWidget,
        // Moment count badge (only on top avatar)
        if (zIndex == friendGroups.length)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.emergencyRed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                _getTotalMomentCount().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  int _getTotalMomentCount() {
    return friendGroups.fold(0, (sum, group) => sum + group.moments.length);
  }

  Widget _buildPlaceholder(FriendMomentGroup group) {
    return Container(
      color: AppTheme.electricPurple.withValues(alpha: 0.3),
      child: Center(
        child: Text(
          group.displayName.isNotEmpty
              ? group.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: AppTheme.electricPurple,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// Data class representing a friend with their moments in the visible area
class FriendMomentGroup {
  final String odId;
  final String displayName;
  final String? avatarUrl;
  final List<Moment> moments;

  const FriendMomentGroup({
    required this.odId,
    required this.displayName,
    this.avatarUrl,
    required this.moments,
  });
}
