import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../data/models/moment.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../widgets/offline_image.dart';
import 'moment_details_page.dart';
import 'package:moments/core/services/app_logger.dart';


final _log = AppLogger('TimelineGallery');
/// Timeline/Gallery view with neubrutalism comic-style design
class TimelineGalleryPage extends ConsumerStatefulWidget {
  const TimelineGalleryPage({super.key});

  @override
  ConsumerState<TimelineGalleryPage> createState() =>
      _TimelineGalleryPageState();
}

class _TimelineGalleryPageState extends ConsumerState<TimelineGalleryPage>
    with SingleTickerProviderStateMixin {
  // Animation controller for staggered entry
  late AnimationController _entryController;

  final Map<String, String> _imageUrls = {};
  final Map<String, String> _localPaths = {};
  final ScrollController _scrollController = ScrollController();
  // View mode: 'grid' or 'timeline'
  String _viewMode = 'timeline';

  @override
  void dispose() {
    _scrollController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entryController.forward();
  }

  Future<void> _loadImagesForMoments(List<Moment> moments) async {
    // Load local paths first and track which moments have valid local files
    final momentsNeedingNetworkUrls = <Moment>[];

    for (var moment in moments) {
      if (_localPaths.containsKey(moment.id)) {
        // Already have local path, skip network URL fetch
        continue;
      }

      final isThumbnail = moment.mediaType == 'video';
      final db = ref.read(appDatabaseProvider);
      final localPath = await db.getLocalMediaPath(
        moment.id,
        isThumbnail: isThumbnail,
      );

      if (localPath != null && mounted) {
        setState(() {
          _localPaths[moment.id] = localPath;
        });
        // Has valid local path, no need for network URL
      } else {
        // No local path, will need network URL
        momentsNeedingNetworkUrls.add(moment);
      }
    }

    // Only fetch network URLs for moments without local paths
    if (momentsNeedingNetworkUrls.isEmpty) return;

    // Collect paths to load for network URLs
    final pathsToLoad = <String>[];
    for (var moment in momentsNeedingNetworkUrls) {
      if (_imageUrls.containsKey(moment.id)) continue;

      if (moment.mediaType == 'video') {
        if (moment.thumbnailPath != null && moment.thumbnailPath!.isNotEmpty) {
          pathsToLoad.add(moment.thumbnailPath!);
        }
      } else {
        if (moment.mediaPath != null && moment.mediaPath!.isNotEmpty) {
          pathsToLoad.add(moment.mediaPath!);
        }
      }
    }

    if (pathsToLoad.isEmpty) return;

    try {
      final urls = await SignedUrlCache.getSignedUrlsBatch(pathsToLoad);

      if (mounted) {
        setState(() {
          for (var moment in momentsNeedingNetworkUrls) {
            if (moment.mediaType == 'video') {
              if (moment.thumbnailPath != null) {
                final thumbUrl = urls[moment.thumbnailPath];
                if (thumbUrl != null) {
                  _imageUrls[moment.id] = thumbUrl;
                }
              }
            } else {
              if (moment.mediaPath != null) {
                final url = urls[moment.mediaPath];
                if (url != null) {
                  _imageUrls[moment.id] = url;
                }
              }
            }
          }
        });
      }
    } catch (e) {
      _log.e('Error loading URLs: $e');
    }
  }

  /// Group moments by month/year
  Map<String, List<Moment>> _groupByMonth(List<Moment> moments) {
    final grouped = <String, List<Moment>>{};

    for (final moment in moments) {
      final key = _formatMonthYear(moment.timestamp);
      if (grouped.containsKey(key)) {
        grouped[key]!.add(moment);
      } else {
        grouped[key] = [moment];
      }
    }

    return grouped;
  }

  /// Group moments by exact date (day/month/year)
  Map<String, List<Moment>> _groupByDate(List<Moment> moments) {
    final grouped = <String, List<Moment>>{};

    for (final moment in moments) {
      final key =
          '${moment.timestamp.year}-${moment.timestamp.month}-${moment.timestamp.day}';
      if (grouped.containsKey(key)) {
        grouped[key]!.add(moment);
      } else {
        grouped[key] = [moment];
      }
    }

    return grouped;
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      '',
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${months[date.month]} ${date.year}';
  }

  /// Get moments that belong to the same group as the tapped moment
  List<Moment> _getMomentsInSameGroup(Moment moment, List<Moment> allMoments) {
    return allMoments
        .where((m) => m.momentGroupId == moment.momentGroupId)
        .toList();
  }

  void _navigateToDetails(
    List<Moment> monthMoments,
    String placeName,
    int index,
  ) {
    HapticService.mediumTap();

    // Get the tapped moment
    final tappedMoment = monthMoments[index];

    // Get only moments from the same group (by moment_group_id)
    final groupMoments = _getMomentsInSameGroup(tappedMoment, monthMoments);

    // Find the index of the tapped moment within the group
    final groupIndex = groupMoments.indexWhere((m) => m.id == tappedMoment.id);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MomentDetailsPage(
              locationName: placeName,
              moments: groupMoments,
              heroTag: 'gallery_${tappedMoment.id}',
              initialPage: groupIndex >= 0 ? groupIndex : 0,
            ),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Comic-style empty box
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.borderBlack,
                width: AppTheme.borderThick,
              ),
              boxShadow: AppTheme.brutalShadow,
            ),
            child: Column(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedImage01,
                  size: 64.sp,
                  color: AppTheme.textGray,
                ),
                SizedBox(height: 16.h),
                Text(
                  'NO MOMENTS YET!',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24.sp,
                    color: AppTheme.textDark,
                    letterSpacing: 1.5.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Start capturing memories',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineView(List<Moment> moments) {
    final grouped = _groupByMonth(moments);
    final monthKeys = grouped.keys.toList();

    // Recap Logic: Moments from last 7 days
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    final recaps = moments.where((m) => m.timestamp.isAfter(lastWeek)).toList();
    final hasRecap = recaps.isNotEmpty;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: monthKeys.length + (hasRecap ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasRecap && index == 0) {
          return _buildRecapHeader(recaps);
        }

        final monthIndex = hasRecap ? index - 1 : index;
        final monthKey = monthKeys[monthIndex];
        final monthMoments = grouped[monthKey]!;
        final dateGrouped = _groupByDate(monthMoments);
        final dateKeys = dateGrouped.keys.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                24.w,
                monthIndex == 0 && !hasRecap ? 24.h : 32.h,
                24.w,
                16.h,
              ),
              child: Text(
                monthKey,
                style: GoogleFonts.bebasNeue(
                  fontSize: 32.sp,
                  color: AppTheme.textDark.withValues(alpha: 0.2),
                  letterSpacing: 2.0,
                ),
              ),
            ),

            ...dateKeys.map((dateKey) {
              final dateMoments = dateGrouped[dateKey]!;
              final date = dateMoments.first.timestamp;
              return _buildCompactDay(date, dateMoments, moments);
            }),
          ],
        );
      },
    );
  }

  Widget _buildRecapHeader(List<Moment> recaps) {
    return Card(
      margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 200.h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Collage Background (First 3 images)
            if (recaps.isNotEmpty)
              Row(
                children: recaps.take(3).map((m) {
                  final localPath = _localPaths[m.id];
                  final imageUrl = _imageUrls[m.id];
                  return Expanded(
                    child: OfflineImage(
                      localPath: localPath,
                      networkUrl: imageUrl,
                      cacheKey: m.mediaPath,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'THIS WEEK',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${recaps.length} Moments Captured',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 28.sp,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticService.lightTap();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDay(
    DateTime date,
    List<Moment> dayMoments,
    List<Moment> allMoments,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sticky-style Date Indicator (Left)
          SizedBox(
            width: 50.w,
            child: Column(
              children: [
                Text(
                  '${date.day}',
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    height: 1.0,
                  ),
                ),
                Text(
                  _getDayName(date),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textGray,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Compact List Column (Right)
          Expanded(
            child: Column(
              children: dayMoments.asMap().entries.map((entry) {
                final moment = entry.value;
                final globalIndex = allMoments.indexOf(moment);

                return _buildCompactTile(moment, allMoments, globalIndex);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTile(Moment moment, List<Moment> allMoments, int index) {
    final localPath = _localPaths[moment.id];
    final imageUrl = _imageUrls[moment.id];
    final isVideo = moment.mediaType == 'video';

    // Format time for the badge
    String formatTime(DateTime dt) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
    }

    // Native ListTile implementation for compactness
    return ListTile(
      contentPadding: EdgeInsets.fromLTRB(0, 4.h, 16.w, 4.h),
      dense: true,
      onTap: () => _navigateToDetails(
        allMoments,
        moment.location.split(',').first.trim(),
        index,
      ),
      leading: Hero(
        tag: 'compact_${moment.id}',
        child: Container(
          width: 72.w,
          height: 72.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              OfflineImage(
                localPath: localPath,
                networkUrl: imageUrl,
                cacheKey: moment.mediaPath,
                fit: BoxFit.cover,
              ),
              if (isVideo)
                Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white.withOpacity(0.8),
                    size: 20.sp,
                  ),
                ),
              // Time badge
              Positioned(
                bottom: 2.h,
                right: 2.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    formatTime(moment.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      title: Text(
        moment.title.isNotEmpty ? moment.title : 'Untitled',
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 2.h),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedLocation01,
              size: 10.sp,
              color: AppTheme.textGray,
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                moment.location.split(',').first.trim(),
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      trailing: HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        size: 16.sp,
        color: AppTheme.textGray.withOpacity(0.5),
      ),
    );
  }

  Widget _buildJournalDay(
    DateTime date,
    List<Moment> dayMoments,
    List<Moment> allMoments,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sticky-style Date Indicator
          SizedBox(
            width: 50.w,
            child: Column(
              children: [
                Text(
                  '${date.day}',
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    height: 1.0,
                  ),
                ),
                Text(
                  _getDayName(date),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textGray,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),

          // Moments Column
          Expanded(
            child: Column(
              children: dayMoments.asMap().entries.map((entry) {
                final moment = entry.value;
                final globalIndex = allMoments.indexOf(moment);

                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _buildJournalCard(moment, allMoments, globalIndex),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCard(Moment moment, List<Moment> allMoments, int index) {
    final localPath = _localPaths[moment.id];
    final imageUrl = _imageUrls[moment.id];
    final isVideo = moment.mediaType == 'video';

    return GestureDetector(
      onTap: () => _navigateToDetails(
        allMoments,
        moment.location.split(',').first.trim(),
        index,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'journal_${moment.id}',
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: OfflineImage(
                      localPath: localPath,
                      networkUrl: imageUrl,
                      cacheKey: moment.mediaPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isVideo)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (moment.title.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        moment.title,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),

                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        size: 12.sp,
                        color: AppTheme.textGray,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          moment.location.split(',').first.trim(),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppTheme.textGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  String _getDayName(DateTime date) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[date.weekday - 1];
  }

  Widget _buildGridView(List<Moment> moments) {
    return MasonryGridView.count(
      controller: _scrollController,
      padding: EdgeInsets.all(10.w),
      crossAxisCount: 2,
      mainAxisSpacing: 10.h,
      crossAxisSpacing: 10.w,
      itemCount: moments.length,
      itemBuilder: (context, index) {
        final moment = moments[index];
        return _buildGridCard(moment, moments, index);
      },
    );
  }

  Widget _buildGridCard(Moment moment, List<Moment> allMoments, int index) {
    final localPath = _localPaths[moment.id];
    final imageUrl = _imageUrls[moment.id];
    final isVideo = moment.mediaType == 'video';

    // Generate consistent pseudo-random aspect ratio based on moment ID
    // This creates the masonry "varying heights" effect
    final hash = moment.id.hashCode;
    final aspectRatioIndex = hash.abs() % 3;
    final aspectRatio = switch (aspectRatioIndex) {
      0 => 0.75, // 3:4 - tall
      1 => 1.0, // 1:1 - square
      _ => 1.33, // 4:3 - wide
    };

    // Soft Minimalism: Rounded corners, soft shadow, no hard borders
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final delay = (index * 0.05).clamp(0.0, 0.5);
        final progress = ((_entryController.value - delay) / 0.4).clamp(
          0.0,
          1.0,
        );

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _navigateToDetails(
          allMoments,
          moment.location.split(',').first.trim(),
          index,
        ),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                Hero(
                  tag: 'gallery_${moment.id}',
                  child: OfflineImage(
                    localPath: localPath,
                    networkUrl: imageUrl,
                    cacheKey: moment.mediaPath,
                    fit: BoxFit.cover,
                  ),
                ),

                // Video indicator
                if (isVideo)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ),

                // Private badge
                if (moment.isPrivate)
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSquareLock02,
                        size: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final momentsAsync = ref.watch(momentsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back button
            GestureDetector(
              onTap: () {
                HapticService.lightTap();
                Navigator.pop(context);
              },
              child: SvgPicture.asset(
                'assets/icons/Left arrow.svg',
                width: 34.w,
                height: 34.h,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'GALLERY',
              style: GoogleFonts.bebasNeue(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5.sp,
              ),
            ),
          ],
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'timeline',
                  icon: Icon(Icons.view_agenda_outlined),
                ),
                ButtonSegment<String>(
                  value: 'grid',
                  icon: Icon(Icons.grid_view_rounded),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (Set<String> newSelection) {
                HapticService.selectionClick();
                setState(() => _viewMode = newSelection.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: momentsAsync.when(
                data: (moments) {
                  if (moments.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Load images
                  _loadImagesForMoments(moments);

                  // Sort by timestamp (newest first)
                  final sortedMoments = List<Moment>.from(moments)
                    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                  if (_viewMode == 'grid') {
                    return _buildGridView(sortedMoments);
                  } else {
                    return _buildTimelineView(sortedMoments);
                  }
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedAlert02,
                        size: 48,
                        color: AppTheme.emergencyRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ERROR LOADING',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 20,
                          color: AppTheme.emergencyRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
