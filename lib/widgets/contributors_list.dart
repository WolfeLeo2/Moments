import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/haptic_service.dart';
import '../../data/models/moment_contributor.dart';

/// Widget showing contributors for a collaborative moment
class ContributorsList extends StatelessWidget {
  final List<MomentContributor> contributors;
  final bool isOwner; // Current user is owner
  final VoidCallback? onInvite;
  final Function(MomentContributor)? onRemove;

  const ContributorsList({
    super.key,
    required this.contributors,
    this.isOwner = false,
    this.onInvite,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final acceptedContributors = contributors.where((c) => c.hasAccepted).toList();
    final pendingContributors = contributors.where((c) => c.isPending).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with invite button
        Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedUserGroup,
              size: 20,
              color: AppTheme.textDark,
            ),
            const SizedBox(width: 8),
            Text(
              'Contributors',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const Spacer(),
            if (isOwner && onInvite != null)
              GestureDetector(
                onTap: () {
                  HapticService.lightTap();
                  onInvite!();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedUserAdd01,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Invite',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Accepted contributors
        if (acceptedContributors.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: acceptedContributors.map((c) => _ContributorChip(
              contributor: c,
              canRemove: isOwner && !c.isOwner,
              onRemove: onRemove,
            )).toList(),
          ),
        ],
        
        // Pending invitations
        if (pendingContributors.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Pending invitations',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pendingContributors.map((c) => _ContributorChip(
              contributor: c,
              isPending: true,
              canRemove: isOwner,
              onRemove: onRemove,
            )).toList(),
          ),
        ],
        
        // Empty state
        if (contributors.length <= 1) // Only owner
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Invite friends to contribute photos',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _ContributorChip extends StatelessWidget {
  final MomentContributor contributor;
  final bool isPending;
  final bool canRemove;
  final Function(MomentContributor)? onRemove;

  const _ContributorChip({
    required this.contributor,
    this.isPending = false,
    this.canRemove = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = contributor.displayName ?? 
                        contributor.username ?? 
                        'User';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPending 
            ? Colors.orange.withOpacity(0.1)
            : contributor.isOwner 
                ? AppTheme.primaryBlue.withOpacity(0.1)
                : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending 
              ? Colors.orange.withOpacity(0.3)
              : contributor.isOwner 
                  ? AppTheme.primaryBlue.withOpacity(0.3)
                  : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey[200],
            backgroundImage: contributor.avatarUrl != null
                ? CachedNetworkImageProvider(contributor.avatarUrl!)
                : null,
            child: contributor.avatarUrl == null
                ? Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          
          // Name
          Text(
            displayName,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
          
          // Role badge for owner
          if (contributor.isOwner) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Owner',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          
          // Pending indicator
          if (isPending) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Pending',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          
          // Remove button
          if (canRemove && onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                HapticService.lightTap();
                onRemove!(contributor);
              },
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
