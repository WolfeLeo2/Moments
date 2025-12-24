import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/models/moment.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/signed_url_cache.dart';
import '../../../core/services/moment_storage_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/providers/moments_providers.dart';
import '../../../widgets/offline_image.dart';
import 'moment_details_page.dart';

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
  final MomentStorageService _storage = MomentStorageService();
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
      final localPath = await _storage.getLocalMediaPath(
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
      debugPrint('Error loading URLs: $e');
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  /// Get moments that belong to the same group as the tapped moment
  List<Moment> _getMomentsInSameGroup(Moment moment, List<Moment> allMoments) {
    // If the moment has a group ID, find all moments with the same group ID
    if (moment.momentGroupId != null) {
      return allMoments
          .where((m) => m.momentGroupId == moment.momentGroupId)
          .toList();
    }
    // If no group ID, return just this moment (ungrouped moments are standalone)
    return [moment];
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

  Widget _buildViewToggle({
    required dynamic icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        color: isActive ? AppTheme.primaryBlue : AppTheme.cardWhite,
        child: HugeIcon(
          icon: icon,
          size: 20.sp,
          color: isActive ? Colors.white : AppTheme.textDark,
        ),
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

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: monthKeys.length,
      itemBuilder: (context, monthIndex) {
        final monthKey = monthKeys[monthIndex];
        final monthMoments = grouped[monthKey]!;

        // Group month moments by date
        final dateGrouped = _groupByDate(monthMoments);
        final dateKeys = dateGrouped.keys.toList();

        return AnimatedBuilder(
          animation: _entryController,
          builder: (context, child) {
            final delay = (monthIndex * 0.1).clamp(0.0, 0.5);
            final progress = ((_entryController.value - delay) / 0.5).clamp(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month header - comic book style speech bubble
              Padding(
                padding: EdgeInsets.only(
                  bottom: 12.h,
                  top: monthIndex > 0 ? 24.h : 0,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.brightYellow,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                        border: Border.all(
                          color: AppTheme.borderBlack,
                          width: AppTheme.borderMedium,
                        ),
                        boxShadow: AppTheme.brutalShadowSmall,
                      ),
                      child: Text(
                        monthKey,
                        style: GoogleFonts.bebasNeue(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                          letterSpacing: 1.2.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Container(
                        height: AppTheme.borderMedium,
                        color: AppTheme.borderBlack,
                      ),
                    ),
                  ],
                ),
              ),

              // Timeline items grouped by date
              ...dateKeys.asMap().entries.map((dateEntry) {
                final dateIndex = dateEntry.key;
                final dateKey = dateEntry.value;
                final dateMoments = dateGrouped[dateKey]!;
                final isLastDateInMonth = dateIndex == dateKeys.length - 1;

                return _buildDateGroup(
                  dateMoments,
                  monthMoments,
                  isLastDateInMonth,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Build a group of moments for the same date with a single extended pin
  Widget _buildDateGroup(
    List<Moment> dateMoments,
    List<Moment> allMonthMoments,
    bool isLastInMonth,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLastInMonth ? 0 : 16.h),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline connector - single pin that extends for all cards in this date
            SizedBox(
              width: 24.w,
              child: Column(
                children: [
                  // The pin circle - always visible
                  Container(
                    width: 14.w,
                    height: 14.w,
                    margin: EdgeInsets.only(left: 5.w),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.borderBlack,
                        width: AppTheme.borderMedium,
                      ),
                    ),
                  ),
                  // Extended line covering all cards in this date group + connecting to next
                  Expanded(
                    child: Container(
                      width: AppTheme.borderMedium,
                      margin: EdgeInsets.only(left: 10.w),
                      color: isLastInMonth
                          ? Colors.transparent
                          : AppTheme.borderBlack,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 12.w),

            // Cards for this date
            Expanded(
              child: Column(
                children: dateMoments.asMap().entries.map((entry) {
                  final cardIndex = entry.key;
                  final moment = entry.value;
                  final globalIndex = allMonthMoments.indexOf(moment);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: cardIndex < dateMoments.length - 1 ? 12.h : 0,
                    ),
                    child: _buildTimelineCardContent(
                      moment,
                      allMonthMoments,
                      globalIndex,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCardContent(
    Moment moment,
    List<Moment> allMoments,
    int index,
  ) {
    final localPath = _localPaths[moment.id];
    final imageUrl = _imageUrls[moment.id];
    final isVideo = moment.mediaType == 'video';

    // Card content - neubrutalist style (no timeline connector, handled by parent)
    return GestureDetector(
      onTap: () => _navigateToDetails(
        allMoments,
        moment.location.split(',').first.trim(),
        index,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          border: Border.all(
            color: AppTheme.borderBlack,
            width: AppTheme.borderMedium,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with hero animation
            Hero(
              tag: 'gallery_${moment.id}',
              child: AspectRatio(
                aspectRatio: 16 / 9,
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
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Details
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    moment.title.toUpperCase(),
                    style: GoogleFonts.bebasNeue(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                      letterSpacing: 1.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.h),

                  // Location and date row
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation03,
                        size: 14.sp,
                        color: AppTheme.primaryBlue,
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
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          _formatDate(moment.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Caption if exists
                  if (moment.caption != null && moment.caption!.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      moment.caption!,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: AppTheme.textDark.withValues(alpha: 0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildGridView(List<Moment> moments) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 3 / 4,
      ),
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
          child: Transform.scale(scale: 0.8 + (0.2 * progress), child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _navigateToDetails(
          allMoments,
          moment.location.split(',').first.trim(),
          index,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            border: Border.all(
              color: AppTheme.borderBlack,
              width: AppTheme.borderMedium,
            ),
          ),

          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image with Hero
              Hero(
                tag: 'gallery_${moment.id}',
                child: OfflineImage(
                  localPath: localPath,
                  networkUrl: imageUrl,
                  cacheKey: moment.mediaPath,
                  fit: BoxFit.cover,
                ),
              ),

              // Video play icon
              if (isVideo)
                Center(
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),

              // Bottom gradient overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        moment.title.toUpperCase(),
                        style: GoogleFonts.bebasNeue(
                          fontSize: 16.sp,
                          color: Colors.white,
                          letterSpacing: 0.8.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _formatDate(moment.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
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
                      size: 14.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
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
          mainAxisSize: MainAxisSize.min, // Essential to keep the Row tight
          children: [
            // 1. Back button (Moved from leading)
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

            // 2. Control the exact gap size
            SizedBox(
              width: 8.w,
            ), // Adjust this value (e.g., 4.w, 8.w) for the desired small gap
            // 3. Title Text
            Text("GALLERY"),
          ],
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w), // Add padding to the right
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                border: Border.all(
                  color: AppTheme.borderBlack,
                  width: AppTheme.borderMedium,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewToggle(
                    icon: HugeIcons.strokeRoundedMenu09,
                    isActive: _viewMode == 'timeline',
                    onTap: () {
                      HapticService.selectionClick();
                      setState(() => _viewMode = 'timeline');
                    },
                  ),
                  Container(
                    width: AppTheme.borderMedium,
                    height: 32.h,
                    color: AppTheme.borderBlack,
                  ),
                  _buildViewToggle(
                    icon: HugeIcons.strokeRoundedGridView,
                    isActive: _viewMode == 'grid',
                    onTap: () {
                      HapticService.selectionClick();
                      setState(() => _viewMode = 'grid');
                    },
                  ),
                ],
              ),
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
