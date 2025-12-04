import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/moment.dart';
import '../../core/theme/app_theme.dart';

/// Beautiful shareable card design inspired by Instagram Stories, BeReal, and Polaroid aesthetics.
/// This widget is designed to be captured as an image for sharing.
class MomentShareCard extends StatelessWidget {
  final Moment moment;
  final String? imageUrl;
  final String? localImagePath;
  final ShareCardStyle style;

  const MomentShareCard({
    super.key,
    required this.moment,
    this.imageUrl,
    this.localImagePath,
    this.style = ShareCardStyle.polaroid,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case ShareCardStyle.polaroid:
        return _buildPolaroidStyle();
      case ShareCardStyle.minimal:
        return _buildMinimalStyle();
      case ShareCardStyle.story:
        return _buildStoryStyle();
      case ShareCardStyle.postcard:
        return _buildPostcardStyle();
    }
  }

  /// Classic Polaroid-style card with white border and handwritten caption
  Widget _buildPolaroidStyle() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(
          0xFFFFFEFC,
        ), // Slightly warm white like real Polaroid
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image area - thick white border on top/sides, thinner on bottom
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: AspectRatio(aspectRatio: 1, child: _buildImage()),
          ),

          // Bottom white space - classic Polaroid has more space at bottom
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Caption in handwriting style (if exists)
                if (moment.caption != null && moment.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      moment.caption!,
                      style: GoogleFonts.caveat(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Location and date row
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: AppTheme.textGray),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        moment.location,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatDateShort(moment.timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Minimal modern style with gradient overlay
  Widget _buildMinimalStyle() {
    return Container(
      width: 340,
      height: 450,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            _buildImage(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),

            // Content at bottom
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption
                  if (moment.caption != null && moment.caption!.isNotEmpty)
                    Text(
                      moment.caption!,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 12),

                  // Location and date row
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          moment.location,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDateShort(moment.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // App branding - subtle
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Moments',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Instagram Story-style full bleed with rounded corners
  Widget _buildStoryStyle() {
    return Container(
      width: 340,
      height: 600,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            _buildImage(),

            // Top gradient for header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Bottom gradient for content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Header with location
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      size: 18,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moment.location,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatDate(moment.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Caption at bottom
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (moment.caption != null && moment.caption!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        moment.caption!,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Moments branding
                  Center(
                    child: Text(
                      'Moments ✨',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vintage postcard style
  Widget _buildPostcardStyle() {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.borderGray, width: 1),
      ),
      child: Row(
        children: [
          // Left side - Image
          Expanded(
            flex: 5,
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
                child: _buildImage(),
              ),
            ),
          ),

          // Right side - Postcard content
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stamp area
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          width: 50,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.borderGray,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.favorite,
                              color: AppTheme.neonPink.withOpacity(0.7),
                              size: 24,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // "Greetings from" text
                      Text(
                        'GREETINGS FROM',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGray,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Location
                      Text(
                        moment.location.toUpperCase(),
                        style: GoogleFonts.bebasNeue(
                          fontSize: 22,
                          color: AppTheme.primaryBlue,
                          letterSpacing: 1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Divider line
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 1,
                    color: AppTheme.borderGray,
                  ),

                  // Message area
                  if (moment.caption != null && moment.caption!.isNotEmpty)
                    Text(
                      moment.caption!,
                      style: GoogleFonts.caveat(
                        fontSize: 16,
                        color: AppTheme.textDark,
                        height: 1.3,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const Spacer(),

                  // Date
                  Text(
                    _formatDate(moment.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.textGray,
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

  Widget _buildImage() {
    if (localImagePath != null) {
      return Image.file(
        File(localImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _buildPlaceholder(),
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.borderGray.withOpacity(0.3),
      child: Center(
        child: Icon(Icons.photo, size: 48, color: AppTheme.textGray),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateShort(DateTime date) {
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
}

/// Available sharing card styles
enum ShareCardStyle {
  polaroid, // Classic Polaroid with white border
  minimal, // Modern minimal with gradient
  story, // Instagram story style
  postcard, // Vintage postcard
}
