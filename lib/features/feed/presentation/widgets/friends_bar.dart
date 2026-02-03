import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/data/models/profile.dart';

/// Horizontal bar showing friends with quick access to their moments
/// Includes a search functionality
class FriendsBar extends ConsumerStatefulWidget {
  const FriendsBar({
    super.key,
    this.onFriendTap,
    this.onSearchTap,
  });

  final void Function(Profile friend)? onFriendTap;
  final VoidCallback? onSearchTap;

  @override
  ConsumerState<FriendsBar> createState() => _FriendsBarState();
}

class _FriendsBarState extends ConsumerState<FriendsBar> {
  final TextEditingController _searchController = TextEditingController();
  List<Profile> _filteredFriends = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFriends(String query, List<Profile> friends) {
    if (query.isEmpty) {
      setState(() => _filteredFriends = friends);
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredFriends = friends.where((friend) {
        final name = (friend.displayName ?? friend.username ?? '').toLowerCase();
        return name.contains(lowercaseQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);

    return Container(
      color: AppTheme.backgroundBeige,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: TextStyle(color: AppTheme.textGray),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textGray),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          friendsAsync.whenData((friends) {
                            _filterFriends('', friends);
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
              onChanged: (query) {
                friendsAsync.whenData((friends) {
                  _filterFriends(query, friends);
                });
              },
              onTap: () {
                friendsAsync.whenData((friends) {
                  _filterFriends(_searchController.text, friends);
                });
              },
            ),
          ),

          // Friends list
          SizedBox(
            height: 90,
            child: friendsAsync.when(
              data: (friends) {
                final displayFriends = _searchController.text.isNotEmpty
                    ? _filteredFriends
                    : friends;

                if (displayFriends.isEmpty) {
                  return Center(
                    child: Text(
                      _searchController.text.isNotEmpty
                          ? 'No friends found'
                          : 'No friends yet',
                      style: TextStyle(color: AppTheme.textGray),
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: displayFriends.length,
                  itemBuilder: (context, index) {
                    final friend = displayFriends[index];
                    return _FriendChip(
                      friend: friend,
                      onTap: () => widget.onFriendTap?.call(friend),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: 5,
                itemBuilder: (context, index) => const _FriendChipShimmer(),
              ),
              error: (e, s) => Center(
                child: Text(
                  'Error loading friends',
                  style: TextStyle(color: AppTheme.textGray),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendChip extends StatelessWidget {
  const _FriendChip({
    required this.friend,
    required this.onTap,
  });

  final Profile friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: friend.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: friend.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 28,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          color: Colors.grey,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            // Name
            Text(
              friend.displayName ?? friend.username ?? 'Friend',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendChipShimmer extends StatelessWidget {
  const _FriendChipShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 48,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
