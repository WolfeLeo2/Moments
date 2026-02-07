import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/services/signed_url_cache.dart';
import 'package:moments/core/services/haptic_service.dart';
import 'package:moments/core/services/audio_note_service.dart';
import 'package:moments/core/providers/database_provider.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/widgets/offline_image.dart';
import 'package:moments/widgets/offline_video.dart';
import 'package:moments/widgets/audio_waveform_widget.dart';
import 'package:moments/widgets/music_indicator.dart';

/// Relive Experience — A full-screen immersive viewer for moments.
///
/// Features:
/// - Edge-to-edge photo/video, pinch-to-zoom
/// - Vertical PageView for swiping between moments
/// - Auto-hiding chrome (title, info bar) — tap toggles
/// - Contextual info panel: location, caption, relative time, weather/moon (AI)
/// - Ambient gradient background from photo dominant color
/// - Parallax transition between pages
class ReliveExperiencePage extends ConsumerStatefulWidget {
  const ReliveExperiencePage({
    super.key,
    required this.moments,
    required this.locationName,
    this.initialIndex = 0,
  });

  final List<Moment> moments;
  final String locationName;
  final int initialIndex;

  @override
  ConsumerState<ReliveExperiencePage> createState() =>
      _ReliveExperiencePageState();
}

class _ReliveExperiencePageState extends ConsumerState<ReliveExperiencePage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _chromeVisible = true;

  /// Resolved signed URLs keyed by moment ID
  final Map<String, String> _imageUrls = {};

  /// Local cached paths keyed by moment ID
  final Map<String, String> _localPaths = {};

  /// Animation controllers
  late AnimationController _chromeFadeController;
  late Animation<double> _chromeFadeAnimation;

  /// Auto-hide timer
  bool _autoHideScheduled = false;

  /// Audio playback
  AudioNoteService? _reliveAudioService;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _chromeFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _chromeFadeAnimation = CurvedAnimation(
      parent: _chromeFadeController,
      curve: Curves.easeOut,
    );
    _chromeFadeController.value = 1.0; // Start visible

    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _loadImageUrls();
    _scheduleAutoHide();
  }

  @override
  void dispose() {
    _reliveAudioService?.dispose();
    _chromeFadeController.dispose();
    _pageController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _scheduleAutoHide() {
    if (_autoHideScheduled) return;
    _autoHideScheduled = true;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _chromeVisible) {
        _toggleChrome();
      }
      _autoHideScheduled = false;
    });
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    if (_chromeVisible) {
      _chromeFadeController.forward();
      _scheduleAutoHide();
    } else {
      _chromeFadeController.reverse();
    }
  }

  Future<void> _loadImageUrls() async {
    final db = ref.read(appDatabaseProvider);

    // Load local cached paths first
    for (final moment in widget.moments) {
      final localPath = await db.getLocalMediaPath(moment.id);
      if (localPath != null && mounted) {
        setState(() => _localPaths[moment.id] = localPath);
      }
    }

    // Pre-populate with existing imageUrls
    for (final moment in widget.moments) {
      if (moment.imageUrl != null) {
        _imageUrls[moment.id] = moment.imageUrl!;
      }
    }

    // Batch-resolve mediaPaths → signed URLs
    final pathsToLoad = widget.moments
        .where(
          (m) =>
              m.mediaPath != null &&
              m.mediaPath!.isNotEmpty &&
              !_imageUrls.containsKey(m.id),
        )
        .map((m) => m.mediaPath!)
        .toList();

    if (pathsToLoad.isEmpty) return;

    try {
      final urls = await SignedUrlCache.getSignedUrlsBatch(pathsToLoad);
      if (mounted) {
        setState(() {
          for (final moment in widget.moments) {
            if (moment.mediaPath != null &&
                urls.containsKey(moment.mediaPath)) {
              _imageUrls[moment.id] = urls[moment.mediaPath]!;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading signed URLs for relive: $e');
    }
  }

  Widget _buildReliveAudioPlayer(Moment moment) {
    _reliveAudioService ??= AudioNoteService();
    final duration = moment.audioDuration ?? 0;
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () async {
        HapticService.lightTap();
        final audioService = _reliveAudioService!;
        if (audioService.isPlaying) {
          audioService.stop();
          return;
        }
        final url = await AudioNoteService.getAudioUrl(moment.audioPath!);
        if (url != null) {
          audioService.play(url, isUrl: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<bool>(
              stream:
                  _reliveAudioService?.isPlayingStream ?? const Stream.empty(),
              initialData: false,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                );
              },
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 50,
              height: 18,
              child: AudioWaveformWidget(
                amplitudes: AudioNoteService.generateFakeWaveform(duration),
                mode: WaveformMode.compact,
                activeColor: Colors.white,
                inactiveColor: Colors.white.withValues(alpha: 0.4),
                barWidth: 2,
                barSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays < 1) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) {
      final weeks = diff.inDays ~/ 7;
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }
    if (diff.inDays < 365) {
      final months = diff.inDays ~/ 30;
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }

    final years = diff.inDays ~/ 365;

    // Poetic relative time
    if (years == 1) {
      final season = _getSeason(timestamp);
      return 'Last $season';
    }
    if (years == 2) return 'Two years ago';

    final season = _getSeason(timestamp);
    return '$years ${season}s ago';
  }

  String _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  String _getTimeContext(DateTime timestamp) {
    final hour = timestamp.hour;
    if (hour >= 5 && hour < 8) return 'Early morning';
    if (hour >= 8 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 14) return 'Midday';
    if (hour >= 14 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 20) return 'Evening';
    if (hour >= 20 && hour < 23) return 'Night';
    return 'Late night';
  }

  String _getMoonPhase(DateTime date) {
    // Simplified moon phase calculation
    final baseDate = DateTime(2000, 1, 6); // Known new moon
    final diff = date.difference(baseDate).inDays;
    final phase = (diff % 29.53) / 29.53;

    if (phase < 0.03 || phase > 0.97) return '🌑 New Moon';
    if (phase < 0.22) return '🌒 Waxing Crescent';
    if (phase < 0.28) return '🌓 First Quarter';
    if (phase < 0.47) return '🌔 Waxing Gibbous';
    if (phase < 0.53) return '🌕 Full Moon';
    if (phase < 0.72) return '🌖 Waning Gibbous';
    if (phase < 0.78) return '🌗 Last Quarter';
    return '🌘 Waning Crescent';
  }

  String _getDayOfWeek(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final moment = widget.moments[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleChrome,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen PageView with parallax
            _buildPageView(),

            // Top gradient for readability
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _chromeFadeAnimation,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom gradient for info panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _chromeFadeAnimation,
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Top chrome: close button + counter
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: _chromeFadeAnimation,
                child: _buildTopChrome(moment),
              ),
            ),

            // Bottom chrome: contextual info panel
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 20,
              right: 20,
              child: FadeTransition(
                opacity: _chromeFadeAnimation,
                child: _buildInfoPanel(moment),
              ),
            ),

            // Page indicator dots (always visible, subtle)
            if (widget.moments.length > 1)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(child: _buildPageDots()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: widget.moments.length,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        HapticFeedback.selectionClick();
        // Show chrome briefly on page change
        if (!_chromeVisible) {
          _toggleChrome();
        } else {
          _scheduleAutoHide();
        }
      },
      itemBuilder: (context, index) {
        final moment = widget.moments[index];
        final imageUrl = _imageUrls[moment.id];
        final localPath = _localPaths[moment.id];

        return _buildMediaPage(moment, imageUrl, localPath);
      },
    );
  }

  Widget _buildMediaPage(Moment moment, String? imageUrl, String? localPath) {
    if (moment.mediaType == 'video') {
      return OfflineVideo(
        localPath: localPath,
        networkUrl: imageUrl,
        autoPlay: moment == widget.moments[_currentIndex],
        looping: true,
      );
    }

    // Image with pinch-to-zoom
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Center(
        child: imageUrl != null || localPath != null
            ? OfflineImage(
                localPath: localPath,
                networkUrl: imageUrl,
                cacheKey: moment.mediaPath ?? moment.id,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white38,
                    ),
                  ),
                ),
                errorWidget: Container(
                  color: Colors.black,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                    size: 48,
                  ),
                ),
              )
            : const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white38,
                ),
              ),
      ),
    );
  }

  Widget _buildTopChrome(Moment moment) {
    return Row(
      children: [
        // Close button
        GestureDetector(
          onTap: () {
            HapticService.lightTap();
            Navigator.pop(context);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 22),
          ),
        ),

        const Spacer(),

        // Title
        Flexible(
          child: Text(
            moment.title.toUpperCase(),
            style: GoogleFonts.bebasNeue(
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const Spacer(),

        // Photo counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_currentIndex + 1} / ${widget.moments.length}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel(Moment moment) {
    final relativeTime = _getRelativeTime(moment.timestamp);
    final timeContext = _getTimeContext(moment.timestamp);
    final moonPhase = _getMoonPhase(moment.timestamp);
    final dayOfWeek = _getDayOfWeek(moment.timestamp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Caption in quotes — handwritten feel
        if (moment.caption != null && moment.caption!.isNotEmpty) ...[
          Text(
            '"${moment.caption!}"',
            style: GoogleFonts.caveat(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
        ],

        // Audio note
        if (moment.audioPath != null) ...[
          _buildReliveAudioPlayer(moment),
          const SizedBox(height: 14),
        ],

        // Music
        if (moment.musicData != null) ...[
          MusicPlayerWidget(musicData: moment.musicData!, compact: true),
          const SizedBox(height: 14),
        ],

        // Location row
        Row(
          children: [
            const Icon(Icons.place, size: 16, color: AppTheme.coralPink),
            const SizedBox(width: 6),
            Text(
              widget.locationName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Relative time — poetic
        Text(
          relativeTime,
          style: GoogleFonts.caveat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.sunsetOrange,
          ),
        ),
        const SizedBox(height: 8),

        // Contextual ambient data row
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _buildContextChip(Icons.schedule, '$timeContext • $dayOfWeek'),
            _buildContextChip(null, moonPhase),
            // TODO: Add weather data from AI service when available
            // TODO: Add popular music of the era
          ],
        ),
      ],
    );
  }

  Widget _buildContextChip(IconData? icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildPageDots() {
    if (widget.moments.length <= 1) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.moments.length.clamp(0, 10),
        (index) => Container(
          width: index == _currentIndex ? 8 : 5,
          height: index == _currentIndex ? 8 : 5,
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentIndex
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
