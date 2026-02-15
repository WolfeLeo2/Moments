import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/haptic_service.dart';
import '../../data/models/moment_contributor.dart';

/// Widget showing contributors for a collaborative moment.
/// Uses a vertical [ListView.builder] with [ListTile]-style rows.
class ContributorsList extends StatelessWidget {
  final List<MomentContributor> contributors;
  final bool isOwner;
  final VoidCallback? onInvite;
  final Function(MomentContributor)? onRemove;
  final Function(MomentContributor)? onTap;

  const ContributorsList({
    super.key,
    required this.contributors,
    this.isOwner = false,
    this.onInvite,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final acceptedContributors =
        contributors.where((c) => c.hasAccepted).toList();
    final pendingContributors =
        contributors.where((c) => c.isPending).toList();

    final allItems = <_ContributorItem>[];

    // Add accepted contributors
    for (final c in acceptedContributors) {
      allItems.add(_ContributorItem(contributor: c, isPending: false));
    }

    // Add pending contributors
    for (final c in pendingContributors) {
      allItems.add(_ContributorItem(contributor: c, isPending: true));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${acceptedContributors.length}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
            const Spacer(),
            if (isOwner && onInvite != null)
              Material(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    HapticService.lightTap();
                    onInvite!();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
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
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Pending section label
        if (pendingContributors.isNotEmpty && acceptedContributors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: const SizedBox.shrink(),
          ),

        // Contributors list
        if (allItems.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final item = allItems[index];
              // Insert pending section header
              final showPendingHeader = item.isPending &&
                  (index == 0 || !allItems[index - 1].isPending);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showPendingHeader)
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
                      child: Text(
                        'PENDING INVITATIONS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  _ContributorListTile(
                    contributor: item.contributor,
                    isPending: item.isPending,
                    canRemove: isOwner && !item.contributor.isOwner,
                    onRemove: onRemove,
                    onTap: onTap,
                  ),
                ],
              );
            },
          )
        else
          // Empty state
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedUserAdd01,
                    size: 32,
                    color: Colors.grey[400]!,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invite friends to contribute photos',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Internal model grouping a contributor with its pending state.
class _ContributorItem {
  final MomentContributor contributor;
  final bool isPending;
  const _ContributorItem({required this.contributor, required this.isPending});
}

/// A single contributor row using ListTile-style layout.
class _ContributorListTile extends StatelessWidget {
  final MomentContributor contributor;
  final bool isPending;
  final bool canRemove;
  final Function(MomentContributor)? onRemove;
  final Function(MomentContributor)? onTap;

  const _ContributorListTile({
    required this.contributor,
    this.isPending = false,
    this.canRemove = false,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        contributor.displayName ?? contributor.username ?? 'User';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null ? () => onTap!(contributor) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: isPending
                    ? Colors.orange.withValues(alpha: 0.15)
                    : contributor.isOwner
                        ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                        : Colors.grey[200],
                backgroundImage: contributor.avatarUrl != null
                    ? CachedNetworkImageProvider(contributor.avatarUrl!)
                    : null,
                child: contributor.avatarUrl == null
                    ? Text(
                        displayName.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isPending
                              ? Colors.orange
                              : contributor.isOwner
                                  ? AppTheme.primaryBlue
                                  : Colors.grey[600],
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name + role/status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (contributor.isOwner)
                      Text(
                        'Owner',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (isPending)
                      Text(
                        'Pending invitation',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        'Contributor',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),

              // Remove button
              if (canRemove && onRemove != null)
                IconButton(
                  onPressed: () {
                    HapticService.lightTap();
                    onRemove!(contributor);
                  },
                  icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                  splashRadius: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
