import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../data/models/moment.dart';
import '../../../widgets/offline_image.dart';
import '../../moments/presentation/moment_details_page.dart';

/// Full-screen page showing all moments in a specific category.
/// Used when tapping a section chevron on the discovery page.
class AllMomentsPage extends StatefulWidget {
  const AllMomentsPage({super.key, required this.title, required this.moments});

  final String title;
  final List<Moment> moments;

  @override
  State<AllMomentsPage> createState() => _AllMomentsPageState();
}

class _AllMomentsPageState extends State<AllMomentsPage> {
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

  void _openMoment(Moment moment) {
    HapticService.mediumTap();
    final placeName = moment.location.split(',').first.trim();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MomentDetailsPage(
          locationName: placeName,
          moments: [moment],
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
          widget.title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: widget.moments.isEmpty
          ? _buildEmpty()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemCount: widget.moments.length,
              itemBuilder: (context, index) =>
                  _buildMomentCard(widget.moments[index]),
            ),
    );
  }

  Widget _buildMomentCard(Moment moment) {
    final location = moment.location.split(',').first.trim();
    final timeAgo = _formatTimeAgo(moment.createdAt);

    return GestureDetector(
      onTap: () => _openMoment(moment),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
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
            OfflineImage(
              localPath: moment.localMediaPath,
              networkUrl: _getImageUrl(moment),
              cacheKey: moment.mediaPath ?? moment.id,
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
            // Bottom gradient scrim
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 90,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
            // Video badge
            if (moment.mediaType == 'video')
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moment.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 10,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
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
            CupertinoIcons.photo_on_rectangle,
            size: 48,
            color: AppTheme.textGray.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No moments here yet',
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
