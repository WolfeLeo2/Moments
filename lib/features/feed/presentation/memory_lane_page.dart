import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/router/app_router.dart';
import 'package:moments/core/services/signed_url_cache.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/core/providers/moments_providers.dart';
import 'package:moments/features/feed/presentation/widgets/memory_card.dart';
import 'package:moments/features/feed/presentation/widgets/chapter_header.dart';
import 'package:moments/features/feed/presentation/widgets/timeline_connector.dart';
import 'package:moments/features/feed/presentation/widgets/scrapbook_elements.dart';
import 'package:moments/features/moments/presentation/moment_details_page.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moments/widgets/offline_image.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/features/notifications/presentation/notifications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MemoryLaneStyleMode { quiet, scrapbook }

class _ChapterSection {
  const _ChapterSection({
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.anchorDate,
    required this.motifSeed,
    required this.moments,
  });

  final String title;
  final String subtitle;
  final String summary;
  final DateTime anchorDate;
  final int motifSeed;
  final List<Moment> moments;
}

/// Memory Lane - An emotional, timeline-based view of memories
/// Replaces the traditional feed with a journal-like experience
class MemoryLanePage extends ConsumerStatefulWidget {
  const MemoryLanePage({
    super.key,
    this.scrollController,
    this.viewLabel,
    this.pullDownMenuItems,
  });

  final ScrollController? scrollController;
  final String? viewLabel;
  final List<PullDownMenuEntry> Function()? pullDownMenuItems;

  @override
  ConsumerState<MemoryLanePage> createState() => _MemoryLanePageState();
}

class _MemoryLanePageState extends ConsumerState<MemoryLanePage>
    with AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  MemoryLaneStyleMode _styleMode = MemoryLaneStyleMode.quiet;

  static const _memoryLaneStylePrefKey = 'memory_lane_style_mode';
  static const int _clusterWindowMinutes = 120;
  static const List<Color> _chapterPalette = [
    AppTheme.coralPink,
    AppTheme.skyBlue,
    AppTheme.mintGreen,
    AppTheme.sunsetOrange,
    AppTheme.lavenderPop,
  ];

  /// Signed URLs resolved for anniversary mini-cards
  final Map<String, String> _miniCardUrls = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _loadStyleMode();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _showNotificationsPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const NotificationsPage()));
  }

  Future<void> _loadStyleMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_memoryLaneStylePrefKey);
    if (!mounted) return;

    setState(() {
      _styleMode = saved == MemoryLaneStyleMode.scrapbook.name
          ? MemoryLaneStyleMode.scrapbook
          : MemoryLaneStyleMode.quiet;
    });
  }

  Future<void> _setStyleMode(MemoryLaneStyleMode mode) async {
    if (_styleMode == mode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_memoryLaneStylePrefKey, mode.name);
    if (!mounted) return;

    HapticFeedback.selectionClick();
    setState(() => _styleMode = mode);
  }

  bool get _isQuietMode => _styleMode == MemoryLaneStyleMode.quiet;

  String _styleModeLabel(MemoryLaneStyleMode mode) {
    return mode == MemoryLaneStyleMode.quiet ? 'Quiet Journal' : 'Scrapbook';
  }

  Color _accentForSeed(int seed) {
    return _chapterPalette[seed.abs() % _chapterPalette.length];
  }

  List<_ChapterSection> _buildChapterSections(List<Moment> moments) {
    final sortedMoments = List<Moment>.from(moments)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    final buckets = <String, List<Moment>>{};
    final anchors = <String, DateTime>{};

    for (final moment in sortedMoments) {
      final momentDate = DateTime(
        moment.timestamp.year,
        moment.timestamp.month,
        moment.timestamp.day,
      );

      late final String chapterTitle;
      late final DateTime chapterAnchor;

      if (momentDate.isAtSameMomentAs(today)) {
        chapterTitle = 'Today';
        chapterAnchor = today;
      } else if (momentDate.isAtSameMomentAs(yesterday)) {
        chapterTitle = 'Yesterday';
        chapterAnchor = yesterday;
      } else if (momentDate.isAfter(thisWeekStart) ||
          momentDate.isAtSameMomentAs(thisWeekStart)) {
        chapterTitle = 'This Week';
        chapterAnchor = thisWeekStart;
      } else if (momentDate.isAfter(lastWeekStart) ||
          momentDate.isAtSameMomentAs(lastWeekStart)) {
        chapterTitle = 'Last Week';
        chapterAnchor = lastWeekStart;
      } else if (momentDate.isAfter(thisMonthStart) ||
          momentDate.isAtSameMomentAs(thisMonthStart)) {
        chapterTitle = 'This Month';
        chapterAnchor = thisMonthStart;
      } else if (momentDate.isAfter(lastMonthStart) ||
          momentDate.isAtSameMomentAs(lastMonthStart)) {
        chapterTitle = 'Last Month';
        chapterAnchor = lastMonthStart;
      } else {
        chapterTitle =
            '${_getSeason(moment.timestamp.month)} ${moment.timestamp.year}';
        chapterAnchor = _seasonAnchor(moment.timestamp);
      }

      buckets.putIfAbsent(chapterTitle, () => <Moment>[]).add(moment);
      final existingAnchor = anchors[chapterTitle];
      if (existingAnchor == null || chapterAnchor.isAfter(existingAnchor)) {
        anchors[chapterTitle] = chapterAnchor;
      }
    }

    final sections =
        buckets.entries
            .map(
              (entry) => _ChapterSection(
                title: entry.key,
                subtitle: _chapterSubtitle(entry.value),
                summary: _chapterSummary(entry.value),
                anchorDate: anchors[entry.key] ?? entry.value.first.timestamp,
                motifSeed: entry.key.hashCode,
                moments: entry.value,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.anchorDate.compareTo(a.anchorDate));

    return sections;
  }

  DateTime _seasonAnchor(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return DateTime(date.year, 3, 1);
    if (month >= 6 && month <= 8) return DateTime(date.year, 6, 1);
    if (month >= 9 && month <= 11) return DateTime(date.year, 9, 1);
    return DateTime(date.year, 12, 1);
  }

  String _chapterSubtitle(List<Moment> moments) {
    if (moments.isEmpty) return '';
    final sorted = List<Moment>.from(moments)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final first = sorted.first.timestamp;
    final last = sorted.last.timestamp;

    if (first.year == last.year &&
        first.month == last.month &&
        first.day == last.day) {
      return '${_formatShortDate(first)} · ${moments.length} memories';
    }

    return '${_formatShortDate(last)} - ${_formatShortDate(first)} · ${moments.length} memories';
  }

  String _chapterSummary(List<Moment> moments) {
    if (moments.isEmpty) return 'A quiet page of memories.';

    final locationCounts = <String, int>{};
    var captionCount = 0;
    for (final moment in moments) {
      if (moment.caption != null && moment.caption!.trim().isNotEmpty) {
        captionCount++;
      }
      final location = moment.location.trim();
      if (location.isEmpty) continue;
      locationCounts[location] = (locationCounts[location] ?? 0) + 1;
    }

    final topLocation = locationCounts.entries.isEmpty
        ? 'different places'
        : (locationCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

    if (captionCount > 0) {
      return '$captionCount notes, centered around $topLocation.';
    }

    return 'Snapshots centered around $topLocation.';
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }

  String _getSeason(int month) {
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Fall';
    return 'Winter';
  }

  /// Group consecutive moments by location for "cluster" display
  List<List<Moment>> _clusterByLocation(List<Moment> moments) {
    if (moments.isEmpty) return [];

    // Sort by timestamp descending
    final sorted = List<Moment>.from(moments)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final clusters = <List<Moment>>[];
    List<Moment> currentCluster = [sorted.first];

    for (var i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final previous = sorted[i - 1];

      // Cluster if same non-empty momentGroupId, or same-location moments
      // captured within a short same-day window.
      final timeDiff = previous.timestamp
          .difference(current.timestamp)
          .inMinutes
          .abs();
      final currentGroup = current.momentGroupId.trim();
      final previousGroup = previous.momentGroupId.trim();
      final sameGroup =
          currentGroup.isNotEmpty &&
          previousGroup.isNotEmpty &&
          currentGroup == previousGroup;
      final sameLocation =
          current.location.trim().toLowerCase() ==
          previous.location.trim().toLowerCase();
      final sameDay =
          current.timestamp.year == previous.timestamp.year &&
          current.timestamp.month == previous.timestamp.month &&
          current.timestamp.day == previous.timestamp.day;

      if (sameGroup ||
          (sameLocation && sameDay && timeDiff <= _clusterWindowMinutes)) {
        currentCluster.add(current);
      } else {
        clusters.add(currentCluster);
        currentCluster = [current];
      }
    }

    if (currentCluster.isNotEmpty) {
      clusters.add(currentCluster);
    }

    return clusters;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final momentsAsync = ref.watch(momentsStreamProvider);
    final notificationCount = ref.watch(notificationCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: widget.pullDownMenuItems != null
            ? PullDownButton(
                itemBuilder: (context) => widget.pullDownMenuItems!(),
                buttonBuilder: (context, showMenu) => GestureDetector(
                  onTap: showMenu,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.viewLabel ?? 'Memory Lane',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 14,
                        color: AppTheme.textGray,
                      ),
                    ],
                  ),
                ),
              )
            : Text(
                'Memory Lane',
                style: GoogleFonts.caveat(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
        actions: [
          PopupMenuButton<MemoryLaneStyleMode>(
            tooltip: 'Timeline style',
            initialValue: _styleMode,
            onSelected: _setStyleMode,
            icon: Icon(
              _isQuietMode
                  ? CupertinoIcons.book
                  : CupertinoIcons.photo_on_rectangle,
              color: AppTheme.textDark,
              size: 22,
            ),
            itemBuilder: (context) => MemoryLaneStyleMode.values
                .map(
                  (mode) => PopupMenuItem<MemoryLaneStyleMode>(
                    value: mode,
                    child: Row(
                      children: [
                        Icon(
                          mode == MemoryLaneStyleMode.quiet
                              ? CupertinoIcons.book
                              : CupertinoIcons.photo_on_rectangle,
                          size: 18,
                          color: _styleMode == mode
                              ? AppTheme.primaryBlue
                              : AppTheme.textGray,
                        ),
                        const SizedBox(width: 10),
                        Text(_styleModeLabel(mode)),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          Badge(
            isLabelVisible: (notificationCount.value ?? 0) > 0,
            label: Text(
              '${notificationCount.value ?? 0}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: AppTheme.coralPink,
            child: IconButton(
              onPressed: _showNotificationsPage,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.invalidate(momentsStreamProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppTheme.dustyRose,
        child: momentsAsync.when(
          data: (moments) => _buildTimeline(moments),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildTimeline(List<Moment> moments) {
    if (moments.isEmpty) {
      return _buildEmptyState();
    }

    final chapters = _buildChapterSections(moments);
    final isQuietMode = _isQuietMode;

    return Stack(
      children: [
        Positioned.fill(
          child: isQuietMode
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.96),
                        AppTheme.backgroundBeige,
                      ],
                    ),
                  ),
                )
              : RuledLinesBackground(
                  lineColor: AppTheme.textGray.withValues(alpha: 0.04),
                  lineSpacing: 28,
                  child: const SizedBox.expand(),
                ),
        ),

        // Main scroll content
        CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Anniversary memories at top (if any)
            ..._buildAnniversarySection(moments),

            // Timeline content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final chapter = chapters[index];
                  final clusters = _clusterByLocation(chapter.moments);

                  return _buildChapterSection(chapter, clusters, index == 0);
                }, childCount: chapters.length),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildAnniversarySection(List<Moment> moments) {
    final anniversaries = moments
        .where((m) => AppTheme.isAnniversary(m.timestamp))
        .toList();

    if (anniversaries.isEmpty) return [];

    final yearsAgo = DateTime.now().year - anniversaries.first.timestamp.year;

    return [
      SliverToBoxAdapter(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(2, 3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppTheme.sunsetOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        yearsAgo == 1
                            ? 'One year ago today'
                            : '$yearsAgo years ago today',
                        style: GoogleFonts.caveat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: anniversaries.take(5).length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final moment = anniversaries[index];
                        return _buildMiniMemoryCard(moment);
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Washi tape decoration on anniversary card
            Positioned(
              top: 8,
              left: 26,
              child: WashiTape(
                color: AppTheme.sunsetOrange.withValues(alpha: 0.6),
                width: 55,
                angle: -0.1,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildMiniMemoryCard(Moment moment) {
    // Resolve the image URL: prefer imageUrl, then signed URL from mediaPath
    String? imageUrl = moment.imageUrl;
    if (imageUrl == null &&
        moment.mediaPath != null &&
        moment.mediaPath!.isNotEmpty) {
      imageUrl = _miniCardUrls[moment.mediaPath];
      // If not yet resolved, kick off resolution
      if (imageUrl == null) {
        _resolveMiniCardUrl(moment.mediaPath!);
      }
    }

    return GestureDetector(
      onTap: () => _openMemoryDetail([moment]),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: OfflineImage(
            localPath: moment.localMediaPath,
            networkUrl: imageUrl,
            cacheKey: moment.mediaPath ?? moment.id,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: AppTheme.dustyRose.withValues(alpha: 0.2),
              child: const Icon(Icons.photo, color: AppTheme.dustyRose),
            ),
          ),
        ),
      ),
    );
  }

  /// Resolve a signed URL for a mini card and trigger rebuild
  Future<void> _resolveMiniCardUrl(String mediaPath) async {
    if (_miniCardUrls.containsKey(mediaPath)) return;
    final url = await SignedUrlCache.getSignedUrl(mediaPath);
    if (url != null && mounted) {
      setState(() => _miniCardUrls[mediaPath] = url);
    }
  }

  Widget _buildChapterSection(
    _ChapterSection chapter,
    List<List<Moment>> clusters,
    bool isFirst,
  ) {
    final accent = _accentForSeed(chapter.motifSeed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chapter header
        ChapterHeader(
          title: chapter.title,
          subtitle: chapter.subtitle,
          memoryCount: chapter.moments.length,
          isFirst: isFirst,
          quietMode: _isQuietMode,
          accentColor: accent,
        ),

        _buildChapterIntroCard(chapter, accent),

        // Memory clusters with timeline
        ...clusters.asMap().entries.map((entry) {
          final isLast = entry.key == clusters.length - 1;
          final cluster = entry.value;

          return TimelineConnector(
            isLast: isLast,
            quietMode: _isQuietMode,
            accentColor: accent,
            child: MemoryCard(
              moments: cluster,
              quietMode: _isQuietMode,
              accentColor: accent,
              onTap: () => _openMemoryDetail(cluster),
            ),
          );
        }),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChapterIntroCard(_ChapterSection chapter, Color accent) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _isQuietMode
            ? Colors.white.withValues(alpha: 0.88)
            : accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: _isQuietMode ? 0.20 : 0.26),
          width: 1,
        ),
      ),
      child: Text(
        chapter.summary,
        style: (_isQuietMode ? GoogleFonts.inter : GoogleFonts.caveat)(
          fontSize: _isQuietMode ? 13 : 19,
          fontWeight: _isQuietMode ? FontWeight.w400 : FontWeight.w500,
          color: AppTheme.textDark.withValues(alpha: 0.82),
          height: 1.35,
        ),
      ),
    );
  }

  void _openMemoryDetail(List<Moment> moments) {
    if (moments.isEmpty) return;
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MomentDetailsPage(
          locationName: moments.first.location,
          moments: moments,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildShimmerCard(),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 8, right: 16),
            decoration: BoxDecoration(
              color: AppTheme.dustyRose.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          // Card shimmer
          Expanded(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
        ],
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.dustyRose.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 56,
                color: AppTheme.dustyRose,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your story begins here',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Capture your first moment and\nstart building your memory lane',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textGray),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => AppRouter.goToAddMoment(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.sageGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 20),
              label: const Text('Capture a moment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: AppTheme.dustyRose),
            const SizedBox(height: 24),
            Text(
              'Couldn\'t load memories',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textGray),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => ref.invalidate(momentsStreamProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.twilightBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
