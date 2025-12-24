import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/haptic_service.dart';
import '../../data/repositories/social_repository.dart';
import '../../data/models/profile.dart';

/// Bottom sheet for selecting friends to invite as contributors
class InviteContributorsSheet extends StatefulWidget {
  final String momentId;
  final List<String> existingContributorIds; // Already invited user IDs
  final Function(List<Profile>) onInvite;

  const InviteContributorsSheet({
    super.key,
    required this.momentId,
    required this.existingContributorIds,
    required this.onInvite,
  });

  @override
  State<InviteContributorsSheet> createState() => _InviteContributorsSheetState();
}

class _InviteContributorsSheetState extends State<InviteContributorsSheet> {
  final SocialRepository _socialRepo = SocialRepository();
  List<Profile> _friends = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _socialRepo.getFriendsProfiles();
      if (mounted) {
        setState(() {
          // Filter out already invited contributors
          _friends = friends
              .where((f) => !widget.existingContributorIds.contains(f.id))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSelection(Profile friend) {
    HapticService.selectionClick();
    setState(() {
      if (_selectedIds.contains(friend.id)) {
        _selectedIds.remove(friend.id);
      } else {
        _selectedIds.add(friend.id);
      }
    });
  }

  void _handleInvite() {
    if (_selectedIds.isEmpty) return;
    
    HapticService.mediumTap();
    final selectedFriends = _friends
        .where((f) => _selectedIds.contains(f.id))
        .toList();
    widget.onInvite(selectedFriends);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: AppTheme.borderBlack,
          width: AppTheme.borderMedium,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedUserAdd01,
                  size: 24,
                  color: AppTheme.textDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Invite Contributors',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (_selectedIds.isNotEmpty)
                  TextButton(
                    onPressed: _handleInvite,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: AppTheme.borderBlack,
                          width: AppTheme.borderThin,
                        ),
                      ),
                    ),
                    child: Text(
                      'Invite (${_selectedIds.length})',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Friend list
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _friends.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedUserGroup,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No friends to invite',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All your friends are already contributors',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          final isSelected = _selectedIds.contains(friend.id);
                          
                          return ListTile(
                            onTap: () => _toggleSelection(friend),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: friend.avatarUrl != null
                                      ? CachedNetworkImageProvider(friend.avatarUrl!)
                                      : null,
                                  child: friend.avatarUrl == null
                                      ? Text(
                                          (friend.displayName ?? friend.username ?? '?')
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[600],
                                          ),
                                        )
                                      : null,
                                ),
                                if (isSelected)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              friend.displayName ?? friend.username ?? 'Unknown',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            subtitle: friend.username != null
                                ? Text(
                                    '@${friend.username}',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey[600],
                                    ),
                                  )
                                : null,
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(friend),
                              activeColor: AppTheme.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

/// Shows the invite contributors bottom sheet
Future<void> showInviteContributorsSheet({
  required BuildContext context,
  required String momentId,
  List<String> existingContributorIds = const [],
  required Function(List<Profile>) onInvite,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => InviteContributorsSheet(
        momentId: momentId,
        existingContributorIds: existingContributorIds,
        onInvite: onInvite,
      ),
    ),
  );
}
