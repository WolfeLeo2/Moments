import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/haptic_service.dart';

/// Widget showing pending invitations for the current user
class PendingInvitationsWidget extends StatelessWidget {
  final List<PendingInvitation> invitations;
  final Function(PendingInvitation) onAccept;
  final Function(PendingInvitation) onDecline;

  const PendingInvitationsWidget({
    super.key,
    required this.invitations,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    if (invitations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedMail01,
                size: 18,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Moment Invitations',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${invitations.length}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Invitations list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invitations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _InvitationCard(
              invitation: invitations[index],
              onAccept: () => onAccept(invitations[index]),
              onDecline: () => onDecline(invitations[index]),
            );
          },
        ),
      ],
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final PendingInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InvitationCard({
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inviter info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                backgroundImage: invitation.inviterAvatarUrl != null
                    ? CachedNetworkImageProvider(invitation.inviterAvatarUrl!)
                    : null,
                child: invitation.inviterAvatarUrl == null
                    ? Text(
                        (invitation.inviterDisplayName ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.inviterDisplayName ?? 
                          invitation.inviterUsername ?? 
                          'Someone',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      'invited you to contribute',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Moment preview
          if (invitation.momentLocationName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedLocation01,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      invitation.momentLocationName!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Decline',
                  isAccept: false,
                  onTap: onDecline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Accept',
                  isAccept: true,
                  onTap: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isAccept;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.isAccept,
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isAccept ? AppTheme.primaryBlue : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: isAccept ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isAccept ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for a pending invitation
class PendingInvitation {
  final String id;
  final String momentId;
  final String? momentLocationName;
  final String? inviterUsername;
  final String? inviterDisplayName;
  final String? inviterAvatarUrl;
  final DateTime invitedAt;

  const PendingInvitation({
    required this.id,
    required this.momentId,
    this.momentLocationName,
    this.inviterUsername,
    this.inviterDisplayName,
    this.inviterAvatarUrl,
    required this.invitedAt,
  });

  factory PendingInvitation.fromJson(Map<String, dynamic> json) {
    final inviter = json['inviter'] as Map<String, dynamic>?;
    final momentGroup = json['moment_groups'] as Map<String, dynamic>?;
    
    return PendingInvitation(
      id: json['id'] as String,
      momentId: json['moment_id'] as String,
      momentLocationName: momentGroup?['location_name'] as String?,
      inviterUsername: inviter?['username'] as String?,
      inviterDisplayName: inviter?['display_name'] as String?,
      inviterAvatarUrl: inviter?['avatar_url'] as String?,
      invitedAt: DateTime.parse(json['invited_at'] as String),
    );
  }
}
