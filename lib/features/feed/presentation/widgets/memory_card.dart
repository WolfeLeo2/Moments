import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/services/signed_url_cache.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/widgets/offline_image.dart';
import 'package:moments/widgets/audio_waveform_widget.dart';
import 'package:moments/widgets/music_indicator.dart';
import 'package:moments/features/feed/presentation/widgets/scrapbook_elements.dart';

/// Scrapbook-style memory card for the Memory Lane timeline view
/// Features: polaroid border, washi tape, slight rotation, handwritten captions,
/// location stamps, sticker decorations
class MemoryCard extends StatefulWidget {
  const MemoryCard({super.key, required this.moments, required this.onTap});

  final List<Moment> moments;
  final VoidCallback onTap;

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  Moment get primaryMoment => widget.moments.first;
  bool get hasMultiple => widget.moments.length > 1;

  /// Resolved signed URLs keyed by mediaPath
  final Map<String, String> _signedUrls = {};

  /// Deterministic random based on moment ID for consistent decoration
  late final Random _random;
  late final double _rotation;
  late final int _washiColorSeed;
  late final bool _showWashiTopLeft;
  late final bool _showWashiTopRight;
  late final bool _showPaperClip;
  late final bool _showSticker;
  late final bool _showStamp;

  @override
  void initState() {
    super.initState();
    _random = Random(primaryMoment.id.hashCode);
    // Slight random rotation: ±2°
    _rotation = (_random.nextDouble() - 0.5) * 0.07;
    _washiColorSeed = _random.nextInt(100);
    _showWashiTopLeft = _random.nextBool();
    _showWashiTopRight = !_showWashiTopLeft || _random.nextDouble() > 0.6;
    _showPaperClip = _random.nextDouble() > 0.65;
    _showSticker = _random.nextDouble() > 0.5;
    _showStamp = _random.nextDouble() > 0.7;

    _resolveSignedUrls();
  }

  /// Resolve mediaPath → signed URL for moments that need it
  Future<void> _resolveSignedUrls() async {
    final pathsToResolve = <String>[];
    for (final moment in widget.moments) {
      // If imageUrl is already set, use it directly
      if (moment.imageUrl != null && moment.imageUrl!.isNotEmpty) continue;
      // If we have a local file cached, skip signed URL generation
      if (moment.localMediaPath != null && moment.localMediaPath!.isNotEmpty)
        continue;
      // If mediaPath exists, we need a signed URL
      if (moment.mediaPath != null && moment.mediaPath!.isNotEmpty) {
        pathsToResolve.add(moment.mediaPath!);
      }
    }
    if (pathsToResolve.isEmpty) return;

    final urls = await SignedUrlCache.getSignedUrlsBatch(pathsToResolve);
    if (mounted && urls.isNotEmpty) {
      setState(() => _signedUrls.addAll(urls));
    }
  }

  /// Get the best available image URL for a moment
  String? _getImageUrl(Moment moment) {
    // Prefer existing imageUrl
    if (moment.imageUrl != null && moment.imageUrl!.isNotEmpty) {
      return moment.imageUrl;
    }
    // Fall back to resolved signed URL from mediaPath
    if (moment.mediaPath != null && _signedUrls.containsKey(moment.mediaPath)) {
      return _signedUrls[moment.mediaPath!];
    }
    return null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moment = primaryMoment;
    final timeOfDayTint = AppTheme.getTimeOfDayTint(moment.timestamp);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Transform.rotate(
          angle: _rotation,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main polaroid card
              _buildPolaroidCard(moment, timeOfDayTint),

              // Washi tape top-left
              if (_showWashiTopLeft)
                Positioned(
                  top: -6,
                  left: 16,
                  child: WashiTape(
                    color: WashiTape.colorFromSeed(_washiColorSeed),
                    angle: -0.15 + _random.nextDouble() * 0.3,
                    width: 50 + _random.nextDouble() * 20,
                  ),
                ),

              // Washi tape top-right
              if (_showWashiTopRight)
                Positioned(
                  top: -5,
                  right: 20,
                  child: WashiTape(
                    color: WashiTape.colorFromSeed(_washiColorSeed + 3),
                    angle: 0.1 + _random.nextDouble() * 0.2,
                    width: 45 + _random.nextDouble() * 15,
                  ),
                ),

              // Paper clip on right edge
              if (_showPaperClip)
                Positioned(
                  top: -8,
                  right: -4,
                  child: PaperClip(
                    color: AppTheme.textGray.withValues(alpha: 0.45),
                    size: 36,
                    angle: 0.1,
                  ),
                ),

              // Sticker near bottom-right
              if (_showSticker)
                Positioned(
                  bottom: 55,
                  right: 10,
                  child: ScrapbookSticker(
                    emoji: ScrapbookSticker.stickerForLocation(moment.location),
                    size: 22,
                    angle: (_random.nextDouble() - 0.5) * 0.4,
                  ),
                ),

              // Location stamp (bottom-right, only on some cards)
              if (_showStamp)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: LocationStamp(
                    location: moment.location,
                    year: moment.timestamp.year,
                    color: WashiTape.colorFromSeed(
                      _washiColorSeed + 1,
                    ).withValues(alpha: 0.5),
                    size: 52,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The core polaroid-style card: white border, photo, caption area
  Widget _buildPolaroidCard(Moment moment, Color tint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            offset: const Offset(2, 4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo with polaroid-style thick white border
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: _buildPhotoSection(tint),
          ),

          // Caption / metadata area (polaroid bottom section)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location row
                Row(
                  children: [
                    const Icon(
                      Icons.place,
                      size: 15,
                      color: AppTheme.coralPink,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        moment.location,
                        style: GoogleFonts.rubik(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Caption in handwritten font
                if (moment.caption != null && moment.caption!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '"${moment.caption!}"',
                    style: GoogleFonts.caveat(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Date / relative time
                Text(
                  AppTheme.formatRelativeTime(moment.timestamp),
                  style: GoogleFonts.caveat(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
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

  Widget _buildPhotoSection(Color tint) {
    return Stack(
      children: [
        // Photo(s) with tight border radius for polaroid feel
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: hasMultiple
                ? _buildPhotoCarousel(tint)
                : _buildSinglePhoto(primaryMoment, tint),
          ),
        ),

        // Carousel dots
        if (hasMultiple)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.moments.length.clamp(0, 5),
                (index) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),

        // Video indicator
        if (primaryMoment.mediaType == 'video')
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                  if (primaryMoment.duration != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(primaryMoment.duration!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

        // Audio note indicator
        if (primaryMoment.audioPath != null)
          Positioned(
            top: primaryMoment.mediaType == 'video' ? 40 : 10,
            right: 10,
            child: AudioNoteIndicator(
              durationSeconds: primaryMoment.audioDuration ?? 0,
            ),
          ),

        // Music indicator
        if (primaryMoment.musicData != null)
          Positioned(
            bottom: 10,
            left: 10,
            child: MusicNoteIndicator(musicData: primaryMoment.musicData!),
          ),
      ],
    );
  }

  Widget _buildPhotoCarousel(Color tint) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.moments.length,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
        HapticFeedback.selectionClick();
      },
      itemBuilder: (context, index) {
        return _buildSinglePhoto(widget.moments[index], tint);
      },
    );
  }

  Widget _buildSinglePhoto(Moment moment, Color tint) {
    final imageUrl = _getImageUrl(moment);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Always render OfflineImage — it checks localPath first,
        // so images load even without a network URL.
        OfflineImage(
          localPath: moment.localMediaPath,
          networkUrl: imageUrl,
          cacheKey: moment.mediaPath ?? moment.id,
          fit: BoxFit.cover,
          errorWidget: Container(
            color: AppTheme.coralPink.withValues(alpha: 0.08),
            child: Icon(
              Icons.broken_image_outlined,
              color: AppTheme.coralPink.withValues(alpha: 0.4),
              size: 48,
            ),
          ),
        ),

        // Time-of-day tint overlay
        if (tint != Colors.transparent) Container(color: tint),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
