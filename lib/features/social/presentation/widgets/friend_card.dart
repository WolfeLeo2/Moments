import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moments/core/services/avatar_cache_service.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/profile.dart';
import 'package:moments/features/social/presentation/friend_profile_page.dart';

/// Modern friend card widget with neubrutalism style
class FriendCard extends StatefulWidget {
  final Profile friend;

  const FriendCard({required this.friend, required Key key}) : super(key: key);

  @override
  State<FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends State<FriendCard>
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey[50] ?? Colors.white],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black,
                  width: AppTheme.borderMedium,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar with multiple rings
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          padding: const EdgeInsets.all(0.5),
                          child: CircleAvatar(
                            radius: 29,
                            backgroundImage: AvatarCacheService()
                                .getAvatarImageProvider(
                                  widget.friend.avatarUrl,
                                ),
                            child: widget.friend.avatarUrl == null
                                ? HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser,
                                    size: 32,
                                    color: Colors.grey[400],
                                  )
                                : null,
                          ),
                        ),
                      ],
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: HugeIcon(
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
