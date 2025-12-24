import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/haptic_service.dart';

/// Section showing moments shared with the user
class SharedMomentsSection extends StatelessWidget {
  final List<SharedMomentPreview> moments;
  final Function(SharedMomentPreview) onTap;
  final bool isLoading;

  const SharedMomentsSection({
    super.key,
    required this.moments,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedShare01,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Shared Moments',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            if (moments.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${moments.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Moments friends have shared with you',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (moments.isEmpty)
          _EmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: moments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _SharedMomentCard(
                moment: moments[index],
                onTap: () => onTap(moments[index]),
              );
            },
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedImage01,
              size: 28,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No shared moments yet',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'When friends share moments with you, they\'ll appear here',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SharedMomentCard extends StatelessWidget {
  final SharedMomentPreview moment;
  final VoidCallback onTap;

  const _SharedMomentCard({
    required this.moment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: moment.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: moment.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedImage01,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedImage01,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location
                    Row(
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedLocation01,
                          size: 14,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            moment.locationName ?? 'Unknown location',
                            style: GoogleFonts.inter(
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
                    const SizedBox(height: 6),
                    
                    // Owner
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: moment.ownerAvatarUrl != null
                              ? CachedNetworkImageProvider(moment.ownerAvatarUrl!)
                              : null,
                          child: moment.ownerAvatarUrl == null
                              ? Text(
                                  (moment.ownerDisplayName ?? 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'by ${moment.ownerDisplayName ?? moment.ownerUsername ?? 'Someone'}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Stats
                    Row(
                      children: [
                        if (moment.photoCount > 0) ...[
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedImage01,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${moment.photoCount}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (moment.contributorCount > 1) ...[
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedUserGroup,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${moment.contributorCount}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for a shared moment preview
class SharedMomentPreview {
  final String momentId;
  final String? locationName;
  final String? thumbnailUrl;
  final String? ownerUsername;
  final String? ownerDisplayName;
  final String? ownerAvatarUrl;
  final int photoCount;
  final int contributorCount;
  final DateTime sharedAt;

  const SharedMomentPreview({
    required this.momentId,
    this.locationName,
    this.thumbnailUrl,
    this.ownerUsername,
    this.ownerDisplayName,
    this.ownerAvatarUrl,
    required this.photoCount,
    required this.contributorCount,
    required this.sharedAt,
  });

  factory SharedMomentPreview.fromJson(Map<String, dynamic> json) {
    final momentGroup = json['moment_groups'] as Map<String, dynamic>?;
    final owner = json['owner'] as Map<String, dynamic>?;
    
    return SharedMomentPreview(
      momentId: json['moment_id'] as String,
      locationName: momentGroup?['location_name'] as String?,
      thumbnailUrl: momentGroup?['thumbnail_url'] as String?,
      ownerUsername: owner?['username'] as String?,
      ownerDisplayName: owner?['display_name'] as String?,
      ownerAvatarUrl: owner?['avatar_url'] as String?,
      photoCount: (momentGroup?['photo_count'] as int?) ?? 0,
      contributorCount: (json['contributor_count'] as int?) ?? 1,
      sharedAt: DateTime.parse(json['accepted_at'] as String),
    );
  }
}
