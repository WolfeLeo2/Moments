import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/moment.dart';
import '../../../widgets/offline_image.dart';
import '../../moments/presentation/moment_details_page.dart';

/// Full-screen page showing moments grouped by friends.
/// Navigated from the "By Friends" chevron on the discovery page.
class AllFriendsPage extends ConsumerStatefulWidget {
  const AllFriendsPage({super.key, required this.moments});

  final List<Moment> moments;

  @override
  ConsumerState<AllFriendsPage> createState() => _AllFriendsPageState();
}

class _AllFriendsPageState extends ConsumerState<AllFriendsPage> {
  AuthService get _authService => ref.read(authServiceProvider);
  final Map<String, String> _signedUrls = {};

  @override
  void initState() {
    super.initState();
    _resolveSignedUrls();
  }

  Future<void> _resolveSignedUrls() async {
    final pathsToResolve = <String>{};
    for (final m in widget.moments) {
      if (m.imageUrl != null && m.imageUrl!.isNotEmpty) continue;
      if (m.localMediaPath != null && m.localMediaPath!.isNotEmpty) continue;
      final path = m.mediaType == 'video' ? m.thumbnailPath : m.mediaPath;
      if (path != null && path.isNotEmpty && !_signedUrls.containsKey(path)) {
        pathsToResolve.add(path);
      }
    }
    if (pathsToResolve.isEmpty) return;
    final urls = await SignedUrlCache.getSignedUrlsBatch(
      pathsToResolve.toList(),
    );
    if (mounted && urls.isNotEmpty) {
      setState(() => _signedUrls.addAll(urls));
    }
  }

  String? _getImageUrl(Moment moment) {
    if (moment.imageUrl != null && moment.imageUrl!.isNotEmpty) {
      return moment.imageUrl;
    }
    final path = moment.mediaType == 'video'
        ? moment.thumbnailPath
        : moment.mediaPath;
    if (path != null && _signedUrls.containsKey(path)) {
      return _signedUrls[path];
    }
    return null;
  }

  void _openFriendMoments(List<Moment> moments) {
    HapticService.mediumTap();
    final placeName = moments.first.location.split(',').first.trim();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MomentDetailsPage(
          locationName: placeName,
          moments: moments,
          heroTag: null,
          initialPage: 0,
        ),
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group moments by userId
    final userMap = <String, List<Moment>>{};
    for (final m in widget.moments) {
      final uid = m.userId ?? 'unknown';
      userMap.putIfAbsent(uid, () => []).add(m);
    }
    final sortedUsers = userMap.entries.toList()
      ..sort((a, b) {
        final aDate = a.value.first.createdAt;
        final bDate = b.value.first.createdAt;
        return bDate.compareTo(aDate);
      });

    final friends = ref.watch(friendsListProvider).value ?? [];
    final avatarService = ref.watch(avatarCacheServiceProvider);
    final currentUserId = _authService.currentUser?.id;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'By Friends',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: sortedUsers.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              itemCount: sortedUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final entry = sortedUsers[index];
                final userId = entry.key;
                final userMoments = entry.value;

                String displayName;
                if (userId == currentUserId) {
                  displayName = 'You';
                } else {
                  final friend = friends
                      .where((f) => f.id == userId)
                      .firstOrNull;
                  displayName =
                      friend?.displayName ?? friend?.username ?? 'Friend';
                }

                final avatarUrl = avatarService.getAvatarUrlSync(userId);

                return _buildFriendRow(
                  displayName: displayName,
                  avatarUrl: avatarUrl,
                  avatarService: avatarService,
                  moments: userMoments,
                );
              },
            ),
    );
  }

  Widget _buildFriendRow({
    required String displayName,
    required String? avatarUrl,
    required dynamic avatarService,
    required List<Moment> moments,
  }) {
    final momentCount = moments.length;
    final previewMoments = moments.take(4).toList();

    return GestureDetector(
      onTap: () => _openFriendMoments(moments),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header with avatar + name + count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryBlue.withValues(
                        alpha: 0.15,
                      ),
                      foregroundImage: avatarService.getAvatarImageProvider(
                        avatarUrl,
                      ),
                      child: avatarUrl == null
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$momentCount moment${momentCount == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: AppTheme.textGray.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
            // Photo preview strip
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: previewMoments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final m = previewMoments[i];
                  return Container(
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: OfflineImage(
                      localPath: m.localMediaPath,
                      networkUrl: _getImageUrl(m),
                      cacheKey: m.mediaPath ?? m.id,
                      fit: BoxFit.cover,
                      errorWidget: _imagePlaceholder(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppTheme.borderGray.withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          color: AppTheme.textGray.withValues(alpha: 0.4),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.person_2,
            size: 48,
            color: AppTheme.textGray.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No friends\' moments yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}
