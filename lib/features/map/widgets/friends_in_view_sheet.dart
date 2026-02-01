import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/features/moments/presentation/moment_details_page.dart';
import 'package:moments/widgets/offline_image.dart';
import 'package:moments/core/services/signed_url_cache.dart';
import 'friend_moments_stack.dart';

/// Bottom sheet showing friends' moments within the visible map area.
/// Tapping a moment group navigates to MomentDetailsPage.
class FriendsInViewSheet extends ConsumerStatefulWidget {
  final List<FriendMomentGroup> friendGroups;
  final String locationName;

  const FriendsInViewSheet({
    super.key,
    required this.friendGroups,
    required this.locationName,
  });

  @override
  ConsumerState<FriendsInViewSheet> createState() => _FriendsInViewSheetState();
}

class _FriendsInViewSheetState extends ConsumerState<FriendsInViewSheet> {
  final Map<String, String?> _thumbnailUrls = {};

  @override
  void initState() {
    super.initState();
    _loadThumbnails();
  }

  Future<void> _loadThumbnails() async {
    // Load first moment thumbnail for each friend group
    final paths = <String>[];
    for (final group in widget.friendGroups) {
      if (group.moments.isNotEmpty) {
        final moment = group.moments.first;
        final path = moment.mediaType == 'video'
            ? moment.thumbnailPath
            : moment.mediaPath;
        if (path != null && path.isNotEmpty) {
          paths.add(path);
        }
      }
    }

    if (paths.isEmpty) return;

    try {
      final urls = await SignedUrlCache.getSignedUrlsBatch(paths);
      if (mounted) {
        setState(() {
          for (final group in widget.friendGroups) {
            if (group.moments.isNotEmpty) {
              final moment = group.moments.first;
              final path = moment.mediaType == 'video'
                  ? moment.thumbnailPath
                  : moment.mediaPath;
              if (path != null) {
                _thumbnailUrls[group.odId] = urls[path];
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading thumbnails: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarCacheService = ref.watch(avatarCacheServiceProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedUserMultiple02,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Friends in ${widget.locationName}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.friendGroups.length} ${widget.friendGroups.length == 1 ? 'friend' : 'friends'} with moments',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Separator skipped for cleaner look

          // Friend list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: widget.friendGroups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final group = widget.friendGroups[index];
                return _buildFriendRow(context, group, avatarCacheService);
              },
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildFriendRow(
    BuildContext context,
    FriendMomentGroup group,
    dynamic avatarCacheService,
  ) {
    final thumbnailUrl = _thumbnailUrls[group.odId];
    final momentCount = group.moments.length;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MomentDetailsPage(
              moments: group.moments,
              locationName: group.displayName,
              initialPage: 0,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundBeige.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Friend avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
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
                            const AssetImage(
                              'assets/images/default_avatar.png',
                            ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildAvatarPlaceholder(group),
                      )
                    : _buildAvatarPlaceholder(group),
              ),
            ),

            const SizedBox(width: 16),

            // Friend name and moment count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$momentCount ${momentCount == 1 ? 'moment' : 'moments'}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Thumbnail preview (if available)
            if (thumbnailUrl != null)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: OfflineImage(
                    networkUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(FriendMomentGroup group) {
    return Container(
      color: AppTheme.electricPurple.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          group.displayName.isNotEmpty
              ? group.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: AppTheme.electricPurple,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

/// Show the friends in view bottom sheet
void showFriendsInViewSheet(
  BuildContext context, {
  required List<FriendMomentGroup> friendGroups,
  required String locationName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.6,
    ),
    builder: (context) => FriendsInViewSheet(
      friendGroups: friendGroups,
      locationName: locationName,
    ),
  );
}
