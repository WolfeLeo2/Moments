import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/data/models/friendship.dart';
import 'package:moments/features/social/presentation/widgets/friend_card.dart';
import 'package:moments/features/social/presentation/widgets/invite_bottom_sheet.dart';
import 'package:moments/features/social/presentation/find_friends_page.dart';
import 'package:moments/widgets/avatar_image.dart';

/// Friends page with accepted friends list and pending sections.
class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  void _showInviteBottomSheet(BuildContext context, String inviteCode) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InviteBottomSheet(inviteCode: inviteCode),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final friendsAsync = ref.watch(friendsListProvider);
    final pendingAsync = ref.watch(pendingRequestsProvider);
    final sentAsync = ref.watch(sentRequestsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Friends',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            friendsAsync.when(
              data: (friends) => Text(
                '${friends.length} ${friends.length == 1 ? 'friend' : 'friends'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              loading: () => Text(
                'Loading...',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.search, color: Colors.black87),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FindFriendsPage()),
            ),
          ),
          profileAsync.when(
            data: (profile) => profile != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(
                        CupertinoIcons.person_add,
                        color: Colors.black87,
                      ),
                      onPressed: () =>
                          _showInviteBottomSheet(context, profile.inviteCode),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(friendsListProvider);
          ref.invalidate(pendingRequestsProvider);
          ref.invalidate(sentRequestsProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        color: AppTheme.dustyRose,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // ── Pending received requests ──
            _buildPendingSection(context, ref, pendingAsync),

            // ── Sent requests (awaiting response) ──
            _buildSentSection(context, ref, sentAsync),

            // ── Friends list ──
            _buildFriendsSection(context, friendsAsync),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ── Pending received requests ────────────────────────────────────────

  Widget _buildPendingSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Friendship>> pendingAsync,
  ) {
    return pendingAsync.when(
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Friend Requests',
              count: requests.length,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 8),
            ...requests.map(
              (r) => _PendingRequestTile(key: ValueKey(r.id), request: r),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ── Sent requests ────────────────────────────────────────────────────

  Widget _buildSentSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Friendship>> sentAsync,
  ) {
    return sentAsync.when(
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Sent Requests',
              count: requests.length,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 8),
            ...requests.map(
              (r) => _SentRequestTile(key: ValueKey(r.id), request: r),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ── Friends list ─────────────────────────────────────────────────────

  Widget _buildFriendsSection(
    BuildContext context,
    AsyncValue friendsAsync,
  ) {
    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.person_2,
                    size: 56,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No friends yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invite friends to start sharing\nmoments together',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Your Friends', count: friends.length),
            const SizedBox(height: 8),
            ...friends.map(
              (friend) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FriendCard(key: ValueKey(friend.id), friend: friend),
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: FriendCardSkeleton(),
          ),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 44,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load friends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _sectionHeader(String label, {int? count, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (color ?? Colors.grey).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color ?? Colors.grey[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Pending request tile — shows incoming request with accept/decline
// ═══════════════════════════════════════════════════════════════════════

class _PendingRequestTile extends ConsumerWidget {
  final Friendship request;
  const _PendingRequestTile({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(friendProfileProvider(request.userId));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.25)),
      ),
      child: profileAsync.when(
        data: (profile) => Row(
          children: [
            // Avatar
            ClipOval(
              child: SizedBox(
                width: 48,
                height: 48,
                child: profile?.avatarUrl != null
                    ? AvatarImage(avatarUrl: profile!.avatarUrl!, size: 48)
                    : Container(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        child: const Center(
                          child: const Icon(
                            CupertinoIcons.person_fill,
                            size: 24,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.displayName ?? 'Someone',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sent you a friend request',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Accept + Decline
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _miniButton(
                  label: 'Accept',
                  color: AppTheme.primaryBlue,
                  onTap: () async {
                    await ref
                        .read(friendRequestProvider.notifier)
                        .acceptRequest(request.id);
                    ref.invalidate(friendsListProvider);
                    ref.invalidate(pendingRequestsProvider);
                  },
                ),
                const SizedBox(width: 6),
                _miniButton(
                  label: 'Decline',
                  color: Colors.grey,
                  outlined: true,
                  onTap: () async {
                    await ref
                        .read(friendRequestProvider.notifier)
                        .rejectRequest(request.id);
                    ref.invalidate(pendingRequestsProvider);
                  },
                ),
              ],
            ),
          ],
        ),
        loading: () => const SizedBox(height: 48),
        error: (_, __) => const SizedBox(height: 48),
      ),
    );
  }

  Widget _miniButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return Material(
      color: outlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: outlined ? Colors.grey[700] : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Sent request tile — shows outgoing request, awaiting response
// ═══════════════════════════════════════════════════════════════════════

class _SentRequestTile extends ConsumerWidget {
  final Friendship request;
  const _SentRequestTile({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(friendProfileProvider(request.friendId));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: profileAsync.when(
        data: (profile) => Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 44,
                height: 44,
                child: profile?.avatarUrl != null
                    ? AvatarImage(avatarUrl: profile!.avatarUrl!, size: 44)
                    : Container(
                        color: Colors.orange.withValues(alpha: 0.1),
                        child: const Center(
                          child: const Icon(
                            CupertinoIcons.person_fill,
                            size: 22,
                            color: Colors.orange,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
            // Pending indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 14,
                    color: Colors.orange[700]!,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Awaiting',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const SizedBox(height: 44),
        error: (_, __) => const SizedBox(height: 44),
      ),
    );
  }
}
