import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/friendship.dart';
import 'package:moments/data/models/profile.dart';
import 'package:moments/features/social/presentation/widgets/action_button.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/widgets/avatar_image.dart';

/// Modern request card with smooth interactions and atmospheric design
class RequestCard extends ConsumerStatefulWidget {
  final Friendship request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final WidgetRef ref;

  const RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.ref,
    required Key key,
  }) : super(key: key);

  @override
  ConsumerState<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<RequestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isRejecting = false;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAccept() async {
    setState(() => _isAccepting = true);
    try {
      await _controller.forward();
      widget.onAccept();
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  void _handleReject() async {
    setState(() => _isRejecting = true);
    try {
      await _controller.forward();
      widget.onReject();
    } finally {
      if (mounted) {
        setState(() => _isRejecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch the profile of the person who SENT the request (userId)
    // NOT the friend_id (which is the current user receiving the request)
    final profileAsync = widget.ref.watch(
      friendProfileProvider(widget.request.userId),
    );

    return ScaleTransition(
      scale: Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.5))
              .animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: profileAsync.when(
              data: (profile) {
                if (profile == null) {
                  return const SizedBox.shrink();
                }
                return _buildRequestCard(profile);
              },
              loading: () => const RequestCardSkeleton(),
              error: (error, _) => _buildErrorCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Profile profile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: AppTheme.borderMedium),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile section
                Row(
                  children: [
                    // Avatar with black border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: AvatarImage(
                        avatarUrl: profile.avatarUrl,
                        size: 52,
                        borderWidth: 0,
                        backgroundColor: Colors.grey[200],
                        placeholder: HugeIcon(
                          icon: HugeIcons.strokeRoundedUser,
                          size: 28,
                          color: Colors.grey[400],
                        ),
                        errorWidget: HugeIcon(
                          icon: HugeIcons.strokeRoundedUser,
                          size: 28,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name and username
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${profile.username ?? 'user'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (profile.bio != null &&
                              profile.bio!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              profile.bio!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    // Reject button
                    Expanded(
                      child: ActionButton(
                        icon: HugeIcons.strokeRoundedMultiplicationSign,
                        label: 'Decline',
                        onPressed: _isRejecting ? null : _handleReject,
                        isLoading: _isRejecting,
                        variant: 'secondary',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Accept button
                    Expanded(
                      child: ActionButton(
                        icon: HugeIcons.strokeRoundedTick01,
                        label: 'Accept',
                        onPressed: _isAccepting ? null : _handleAccept,
                        isLoading: _isAccepting,
                        variant: 'primary',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: AppTheme.borderMedium),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlertSquare,
            color: Colors.red[400],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to load request sender',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading card
class RequestCardSkeleton extends StatelessWidget {
  const RequestCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: AppTheme.borderMedium),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
                const SizedBox(width: 16),
                // Text skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 100,
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
            const SizedBox(height: 16),
            // Button skeleton
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
