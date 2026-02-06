import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/moment.dart';

/// A memory card for the Memory Lane timeline view
/// Displays a photo with location, caption, and relative time
/// Supports multiple photos in a cluster (carousel dots shown)
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
        // TODO: Show quick actions menu
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMomentCard),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo section
            _buildPhotoSection(timeOfDayTint),

            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location row
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: AppTheme.sageGreen,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          moment.location,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: AppTheme.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Caption (if exists) - handwritten font
                  if (moment.caption != null && moment.caption!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      moment.caption!,
                      style: GoogleFonts.caveat(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Relative time
                  Text(
                    AppTheme.formatRelativeTime(moment.timestamp),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.textGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(Color tint) {
    return Stack(
      children: [
        // Photo(s)
        ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusMomentCard),
          ),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: hasMultiple
                ? _buildPhotoCarousel(tint)
                : _buildSinglePhoto(primaryMoment, tint),
          ),
        ),

        // Carousel dots (if multiple)
        if (hasMultiple)
          Positioned(
            bottom: 12,
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
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),

        // Video indicator (if video)
        if (primaryMoment.mediaType == 'video')
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        if (moment.imageUrl != null)
          CachedNetworkImage(
            imageUrl: moment.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppTheme.dustyRose.withOpacity(0.1),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.dustyRose,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppTheme.dustyRose.withOpacity(0.1),
              child: Icon(
                Icons.broken_image_outlined,
                color: AppTheme.dustyRose.withOpacity(0.5),
                size: 48,
              ),
            ),
          )
        else
          Container(
            color: AppTheme.dustyRose.withOpacity(0.1),
            child: Icon(
              Icons.photo_outlined,
              color: AppTheme.dustyRose.withOpacity(0.5),
              size: 48,
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
