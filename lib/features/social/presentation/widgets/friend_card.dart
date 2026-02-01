import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/profile.dart';
import 'package:moments/features/social/presentation/friend_profile_page.dart';

/// Modern friend card widget with neubrutalism style
class FriendCard extends ConsumerStatefulWidget {
  final Profile friend;

  const FriendCard({required this.friend, required Key key}) : super(key: key);

  @override
  ConsumerState<FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends ConsumerState<FriendCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to Friend Profile instead of Chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendProfilePage(
              friendId: widget.friend.id,
              friendName:
                  widget.friend.displayName ??
                  widget.friend.username ??
                  'Friend',
              friendAvatarUrl: widget.friend.avatarUrl,
            ),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_controller.value * 0.02),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  24,
                ), // Softer, rounder corners
                boxShadow:
                    AppTheme.brutalShadowSmall, // Now mapped to soft shadow
                border: Border.all(color: AppTheme.borderGray, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar with multiple rings
                    // Avatar - Clean
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: ref
                          .watch(avatarCacheServiceProvider)
                          .getAvatarImageProvider(widget.friend.avatarUrl),
                      child: widget.friend.avatarUrl == null
                          ? HugeIcon(
                              icon: HugeIcons.strokeRoundedUser,
                              size: 28,
                              color: Colors.grey[400],
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Friend info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.friend.displayName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Bio
                          Text(
                            widget.friend.bio ?? 'No bio yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Action button
                    // Action button - Minimal
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight02,
                        size: 20,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton loader for friend card
class FriendCardSkeleton extends StatelessWidget {
  const FriendCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200] ?? Colors.grey, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar skeleton
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 14),
          // Text skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
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
