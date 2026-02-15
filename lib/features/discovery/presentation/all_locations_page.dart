import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../data/models/moment.dart';
import '../../../widgets/offline_image.dart';
import '../../moments/presentation/moment_details_page.dart';

/// Full-screen page showing all moments grouped by location.
/// Navigated from the "By Location" chevron on the discovery page.
class AllLocationsPage extends StatefulWidget {
  const AllLocationsPage({super.key, required this.moments});

  final List<Moment> moments;

  @override
  State<AllLocationsPage> createState() => _AllLocationsPageState();
}

class _AllLocationsPageState extends State<AllLocationsPage> {
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

  void _openLocationMoments(List<Moment> moments) {
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

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    // Group by location
    final locationMap = <String, List<Moment>>{};
    for (final m in widget.moments) {
      final loc = m.location.split(',').first.trim();
      locationMap.putIfAbsent(loc, () => []).add(m);
    }
    final sortedLocations = locationMap.entries.toList()
      ..sort((a, b) {
        final aDate = a.value
            .map((m) => m.createdAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        final bDate = b.value
            .map((m) => m.createdAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        return bDate.compareTo(aDate);
      });

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
          'By Location',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: sortedLocations.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              itemCount: sortedLocations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final entry = sortedLocations[index];
                return _buildLocationCard(entry.key, entry.value);
              },
            ),
    );
  }

  Widget _buildLocationCard(String locationName, List<Moment> moments) {
    moments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final cover = moments.first;
    final count = moments.length;
    final lastTime = _formatTimeAgo(cover.createdAt);

    return GestureDetector(
      onTap: () => _openLocationMoments(moments),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            OfflineImage(
              localPath: cover.localMediaPath,
              networkUrl: _getImageUrl(cover),
              cacheKey: cover.mediaPath ?? cover.id,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: AppTheme.borderGray.withValues(alpha: 0.2),
                child: Center(
                  child: Icon(
                    CupertinoIcons.photo,
                    color: AppTheme.textGray.withValues(alpha: 0.4),
                    size: 28,
                  ),
                ),
              ),
            ),
            // Gradient scrim
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Count badge
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.photo_fill_on_rectangle_fill,
                      size: 12,
                      color: AppTheme.textDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom info
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.location_solid,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              locationName,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        lastTime,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cover.title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (moments.length > 1) ...[
                    const SizedBox(height: 10),
                    // Mini preview strip
                    SizedBox(
                      height: 36,
                      child: Row(
                        children: [
                          ...moments
                              .skip(1)
                              .take(4)
                              .toList()
                              .asMap()
                              .entries
                              .map((e) {
                                final i = e.key;
                                final m = e.value;
                                return Transform.translate(
                                  offset: Offset(-i * 6.0, 0),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: OfflineImage(
                                      localPath: m.localMediaPath,
                                      networkUrl: _getImageUrl(m),
                                      cacheKey: m.mediaPath ?? m.id,
                                      fit: BoxFit.cover,
                                      errorWidget: Container(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          if (moments.length > 5)
                            Transform.translate(
                              offset: Offset(-4 * 6.0, 0),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                child: Center(
                                  child: Text(
                                    '+${moments.length - 5}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
            CupertinoIcons.location,
            size: 48,
            color: AppTheme.textGray.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No locations yet',
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
