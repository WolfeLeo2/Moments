import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/moment.dart';
import '../../../core/services/share_service.dart';
import 'package:moments/core/services/app_logger.dart';


final _log = AppLogger('YearInReview');
/// Year in Review page - Spotify Wrapped-style recap of user's moments
/// Features animated statistics, beautiful gradients, and shareable cards
class YearInReviewPage extends StatefulWidget {
  final List<Moment> moments;
  final int year;

  const YearInReviewPage({
    super.key,
    required this.moments,
    required this.year,
  });

  @override
  State<YearInReviewPage> createState() => _YearInReviewPageState();
}

class _YearInReviewPageState extends State<YearInReviewPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final YearInReviewStats _stats;
  int _currentPage = 0;

  // Repaint keys for each shareable page
  final List<GlobalKey> _repaintKeys = List.generate(5, (_) => GlobalKey());

  // Gradient colors for each page (Spotify Wrapped inspired)
  static const List<List<Color>> _gradients = [
    [Color(0xFF1DB954), Color(0xFF191414)], // Spotify green
    [Color(0xFF8B5CF6), Color(0xFF3B0764)], // Purple
    [Color(0xFFEC4899), Color(0xFF831843)], // Pink
    [Color(0xFFF59E0B), Color(0xFF78350F)], // Amber
    [Color(0xFF06B6D4), Color(0xFF164E63)], // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _stats = ShareService.generateYearStats(widget.moments, widget.year);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareCurrentPage() async {
    final key = _repaintKeys[_currentPage];

    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/year_review_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'My ${widget.year} in Moments ✨');
    } catch (e) {
      _log.e('Error sharing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stats.totalMoments == 0) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Page view with gradient backgrounds
          PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            children: [
              _buildTotalMomentsPage(),
              _buildLocationsPage(),
              _buildTopLocationPage(),
              _buildMonthlyBreakdownPage(),
              _buildFinalSummaryPage(),
            ],
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  IconButton(
                    onPressed: _shareCurrentPage,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedShare08,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Page indicators
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),

          // Swipe hint on first page
          if (_currentPage == 0)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white54,
                      size: 32,
                    ),
                    Text(
                      'Swipe to explore',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_album_outlined,
              color: Colors.white54,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'No moments in ${widget.year}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start capturing memories to see your year in review!',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Page 1: Total Moments
  Widget _buildTotalMomentsPage() {
    return RepaintBoundary(
      key: _repaintKeys[0],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradients[0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your ${widget.year}',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: _stats.totalMoments),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      '$value',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.white,
                        fontSize: 140,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'MOMENTS CAPTURED',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatPill(
                      icon: Icons.photo,
                      value: '${_stats.photoCount}',
                      label: 'Photos',
                    ),
                    const SizedBox(width: 16),
                    _buildStatPill(
                      icon: Icons.videocam,
                      value: '${_stats.videoCount}',
                      label: 'Videos',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Page 2: Locations explored
  Widget _buildLocationsPage() {
    return RepaintBoundary(
      key: _repaintKeys[1],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradients[1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.explore, color: Colors.white70, size: 48),
                const SizedBox(height: 24),
                Text(
                  'You explored',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: _stats.uniqueLocations),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      '$value',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.white,
                        fontSize: 120,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    );
                  },
                ),
                Text(
                  _stats.uniqueLocations == 1
                      ? 'UNIQUE PLACE'
                      : 'UNIQUE PLACES',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_stats.longestStreak} day streak',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Page 3: Top location
  Widget _buildTopLocationPage() {
    return RepaintBoundary(
      key: _repaintKeys[2],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradients[2],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your favorite spot',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _stats.topLocation ?? 'Unknown',
                        style: GoogleFonts.bebasNeue(
                          color: Colors.black,
                          fontSize: 32,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_stats.topLocationCount} moments',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Keep making memories there! 💕',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Page 4: Monthly breakdown
  Widget _buildMonthlyBreakdownPage() {
    final maxCount = _stats.monthCounts.reduce((a, b) => a > b ? a : b);

    return RepaintBoundary(
      key: _repaintKeys[3],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradients[3],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your busiest month',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ShareService.getMonthName(_stats.busiestMonth).toUpperCase(),
                  style: GoogleFonts.bebasNeue(
                    color: Colors.white,
                    fontSize: 48,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '${_stats.busiestMonthCount} moments',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),
                // Mini bar chart
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(12, (index) {
                      final count = _stats.monthCounts[index];
                      final height = maxCount > 0
                          ? (count / maxCount) * 100
                          : 0.0;
                      final isBusiest = index == _stats.busiestMonth;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: Duration(
                              milliseconds: 500 + (index * 50),
                            ),
                            curve: Curves.easeOutCubic,
                            width: 16,
                            height: height.clamp(4, 100),
                            decoration: BoxDecoration(
                              color: isBusiest
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getMonthAbbr(index),
                            style: GoogleFonts.inter(
                              color: isBusiest ? Colors.white : Colors.white54,
                              fontSize: 10,
                              fontWeight: isBusiest
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Page 5: Final summary with featured moment
  Widget _buildFinalSummaryPage() {
    // Future enhancement: use featured moment for a preview image
    // final featuredMoment = _stats.moments.isNotEmpty
    //     ? _stats.moments[DateTime.now().millisecond % _stats.moments.length]
    //     : null;

    return RepaintBoundary(
      key: _repaintKeys[4],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradients[4],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.year} WRAPPED',
                  style: GoogleFonts.bebasNeue(
                    color: Colors.white,
                    fontSize: 42,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 32),
                // Summary card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        icon: Icons.photo_album_outlined,
                        label: 'Total Moments',
                        value: '${_stats.totalMoments}',
                      ),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        icon: Icons.location_pin,
                        label: 'Places Visited',
                        value: '${_stats.uniqueLocations}',
                      ),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        icon: Icons.favorite,
                        label: 'Favorite Spot',
                        value: _stats.topLocation ?? '-',
                        isLocation: true,
                      ),
                      const Divider(height: 24),
                      _buildSummaryRow(
                        icon: Icons.local_fire_department_outlined,
                        label: 'Best Streak',
                        value: '${_stats.longestStreak} days',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Here\'s to more moments in ${widget.year + 1}! 🎉',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Share button
                ElevatedButton.icon(
                  onPressed: _shareCurrentPage,
                  icon: const Icon(Icons.share),
                  label: const Text('Share My Year'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _gradients[4][0],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
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

  Widget _buildStatPill({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLocation = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: _gradients[4][0], size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: isLocation ? 14 : 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getMonthAbbr(int month) {
    const abbrs = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    return abbrs[month];
  }
}
