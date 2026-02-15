import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/features/chat/presentation/chat_page.dart';
import 'package:moments/features/chat/providers/chat_providers.dart';
import 'package:moments/data/models/profile.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Full page for starting a new conversation
/// Features: Search, Recent Chats, Online Friends, All Friends sections
class NewConversationPage extends ConsumerStatefulWidget {
  const NewConversationPage({super.key});

  @override
  ConsumerState<NewConversationPage> createState() =>
      _NewConversationPageState();
}

class _NewConversationPageState extends ConsumerState<NewConversationPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Profile> _filterFriends(List<Profile> friends) {
    if (_searchQuery.isEmpty) return friends;

    final query = _searchQuery.toLowerCase();
    return friends.where((friend) {
      final name = (friend.displayName ?? friend.username ?? '').toLowerCase();
      final username = (friend.username ?? '').toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);
    final recentChatsAsync = ref.watch(chatListProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/Left arrow.svg',
            width: 34.w,
            height: 34.h,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Message',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.textDark, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.textDark,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search friends...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      CupertinoIcons.search,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: friendsAsync.when(
              data: (friends) {
                final filteredFriends = _filterFriends(friends);

                if (friends.isEmpty) {
                  return _buildEmptyState();
                }

                if (filteredFriends.isEmpty && _searchQuery.isNotEmpty) {
                  return _buildNoResultsState();
                }

                return CustomScrollView(
                  slivers: [
                    // Recent Conversations Section
                    if (_searchQuery.isEmpty)
                      recentChatsAsync.when(
                        data: (chats) {
                          if (chats.isEmpty) return const SliverToBoxAdapter();

                          // Get unique user IDs from recent chats (max 5)
                          final recentUserIds = chats
                              .take(5)
                              .map((c) => c['otherUserId'] as String)
                              .toList();

                          final recentFriends = friends
                              .where((f) => recentUserIds.contains(f.id))
                              .toList();

                          if (recentFriends.isEmpty) {
                            return const SliverToBoxAdapter();
                          }

                          return SliverToBoxAdapter(
                            child: _buildSection(
                              title: 'Recent',
                              icon: CupertinoIcons.rotate_left,
                              child: _buildHorizontalFriendsList(recentFriends),
                            ),
                          );
                        },
                        loading: () => const SliverToBoxAdapter(),
                        error: (_, __) => const SliverToBoxAdapter(),
                      ),

                    // All Friends Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                CupertinoIcons.person_3,
                                size: 14,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _searchQuery.isEmpty ? 'All Friends' : 'Results',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${filteredFriends.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Friends List
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final friend = filteredFriends[index];
                        return _FriendListTile(
                          friend: friend,
                          onTap: () => _startConversation(friend),
                        );
                      }, childCount: filteredFriends.length),
                    ),

                    // Bottom padding for dock
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brightYellow.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 14, color: AppTheme.textDark),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildHorizontalFriendsList(List<Profile> friends) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return _RecentFriendChip(
            friend: friend,
            onTap: () => _startConversation(friend),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.person_3,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No friends yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some friends to start messaging',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.search,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No results found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _startConversation(Profile friend) {
    Navigator.pop(context); // Close this page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          friendId: friend.id,
          friendName: friend.displayName ?? friend.username ?? 'Friend',
          friendAvatarUrl: friend.avatarUrl,
        ),
      ),
    );
  }
}

/// Horizontal chip for recent friends
class _RecentFriendChip extends ConsumerWidget {
  final Profile friend;
  final VoidCallback onTap;

  const _RecentFriendChip({required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.textDark, width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.cardWhite,
                  backgroundImage: ref
                      .watch(avatarCacheServiceProvider)
                      .getAvatarImageProvider(friend.avatarUrl),
                  child: friend.avatarUrl == null
                      ? const Icon(Icons.person, color: Colors.grey, size: 28)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                friend.displayName ?? friend.username ?? 'Friend',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List tile for friend in the all friends section
class _FriendListTile extends ConsumerWidget {
  final Profile friend;
  final VoidCallback onTap;

  const _FriendListTile({required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.textDark.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.textDark, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.cardWhite,
                    backgroundImage: ref
                        .watch(avatarCacheServiceProvider)
                        .getAvatarImageProvider(friend.avatarUrl),
                    child: friend.avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.grey, size: 24)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName ?? friend.username ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${friend.username ?? 'unknown'}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.paperplane,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
