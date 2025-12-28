import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/features/social/presentation/widgets/friend_card.dart';
import 'package:moments/features/social/presentation/widgets/invite_bottom_sheet.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Page for viewing friends list.
/// Friend requests have been moved to the Notifications page.
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/Left arrow.svg',
            width: 34.w,
            height: 34.h,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Friends',
              style: TextStyle(
                fontSize: 24,
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
          // Invite button
          profileAsync.when(
            data: (profile) => profile != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          _showInviteBottomSheet(context, profile.inviteCode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.brutalShadowSmall,
                          border: Border.all(
                            color: Colors.black,
                            width: AppTheme.borderThin,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedUserAdd02,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Invite',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: _buildFriendsList(context, friendsAsync),
    );
  }

  Widget _buildFriendsList(BuildContext context, AsyncValue friendsAsync) {
    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/svg/friends_empty.svg',
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
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
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FriendCard(key: ValueKey(friend.id), friend: friend),
            );
          },
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: 4,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: FriendCardSkeleton(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedAlertSquare,
                  size: 40,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Failed to load friends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString().replaceAll('Exception: ', ''),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
