import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:moments/core/providers/moments_providers.dart';
import 'package:moments/core/providers/providers.dart';
import 'package:moments/core/providers/powersync_provider.dart';
import 'package:moments/core/utils/extensions.dart';
import 'package:moments/core/widgets/time_ago_text.dart';
import 'package:moments/data/models/friendship.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/data/models/moment_contributor.dart';
import 'package:moments/features/mapv2/providers/map_control_provider.dart';
import 'package:moments/features/moments/presentation/moment_details_page.dart';
import 'package:moments/features/notifications/models/notification_item.dart';
import 'package:moments/features/notifications/utils/notification_type_config.dart';

class NotificationCard extends ConsumerWidget {
  final NotificationItem item;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.item,
    this.onDismiss,
  });

  bool get _requiresAction =>
      item.type == NotificationType.friendRequest ||
      item.type == NotificationType.collaborationInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = NotificationTypeConfig.forType(item.type);

    // Friend requests may arrive without actor data — enrich from the profile provider.
    if (item.type == NotificationType.friendRequest && item.actorName == null) {
      final request = item.data as Friendship;
      final profileAsync = ref.watch(friendProfileProvider(request.userId));
      return profileAsync.when(
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          return _buildCard(
            context,
            ref,
            item.copyWith(
              actorName: profile.displayName ?? profile.username,
              actorAvatarUrl: profile.avatarUrl,
            ),
            config,
          );
        },
        loading: _buildLoadingCard,
        error: (e, _) => const SizedBox.shrink(),
      );
    }

    return _buildCard(context, ref, item, config);
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
    NotificationTypeConfig config,
  ) {
    final content = _CardContent(
      item: item,
      config: config,
      requiresAction: _requiresAction,
      onTap: () => _handleTap(context, ref, item),
      onAccept: () => _handleAccept(context, ref, item),
      onDecline: () => _handleDecline(context, ref, item),
    );

    if (!_requiresAction && onDismiss != null) {
      return Dismissible(
        key: ValueKey('dismiss_${item.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss!(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 24),
        ),
        child: content,
      );
    }

    return content;
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _handleTap(BuildContext context, WidgetRef ref, NotificationItem item) {
    if (!item.isRead) {
      ref.read(notificationsListProvider.notifier).markAsRead(item.id);
    }
    switch (item.type) {
      case NotificationType.momentLike:
      case NotificationType.momentInvite:
      case NotificationType.newMoment:
        final relatedId = item.data is Map ? item.data['related_id'] : null;
        if (relatedId == null) return;
        if (item.type == NotificationType.momentLike) {
          _navigateToMomentDetails(context, ref, relatedId.toString());
        } else {
          _navigateToMomentOnMap(context, ref, relatedId.toString());
        }
      default:
        break;
    }
  }

  Future<void> _navigateToMomentOnMap(
    BuildContext context,
    WidgetRef ref,
    String momentId,
  ) async {
    try {
      final moment = await _getMomentLocalFirst(ref, momentId);
      if (moment != null && context.mounted) {
        Navigator.pop(context);
        ref
            .read(mapCameraTargetProvider.notifier)
            .setTarget(LatLng(moment.latitude, moment.longitude));
      }
    } catch (_) {
      if (context.mounted) context.showErrorSnackBar('Could not find moment location');
    }
  }

  Future<void> _navigateToMomentDetails(
    BuildContext context,
    WidgetRef ref,
    String momentId,
  ) async {
    try {
      final moment = await _getMomentLocalFirst(ref, momentId);
      if (moment == null || !context.mounted) return;
      final moments = await _getMomentsByGroupLocalFirst(ref, moment.momentGroupId);
      final initialPage = moments.indexWhere((m) => m.id == momentId).clamp(0, moments.length);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MomentDetailsPage(
              locationName: moment.location,
              moments: moments,
              initialPage: initialPage,
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) context.showErrorSnackBar('Could not load moment');
    }
  }

  // ── Accept / Decline ──────────────────────────────────────────────────────

  Future<void> _handleAccept(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    HapticFeedback.mediumImpact();
    if (item.type == NotificationType.friendRequest) {
      try {
        await ref.read(friendRequestProvider.notifier).acceptRequest(
          (item.data as Friendship).id,
        );
        if (context.mounted) {
          context.showSuccessSnackBar('Friend request accepted!');
          ref.invalidate(friendsListProvider);
          ref.invalidate(pendingRequestsProvider);
        }
      } catch (_) {
        if (context.mounted) context.showErrorSnackBar('Failed to accept request');
      }
    } else if (item.type == NotificationType.collaborationInvite) {
      final invite = item.data as MomentContributor;
      try {
        await ref.read(momentRepositoryProvider).acceptInvitation(invite.id);
        if (!context.mounted) return;
        context.showSuccessSnackBar('Joined moment group!');
        try {
          final moments = await _getMomentsByGroupLocalFirst(ref, invite.momentId);
          if (context.mounted && moments.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MomentDetailsPage(
                  locationName: moments.first.location,
                  moments: moments,
                ),
              ),
            );
          }
        } catch (_) {}
      } catch (_) {
        if (context.mounted) context.showErrorSnackBar('Failed to join group');
      }
    }
  }

  Future<void> _handleDecline(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    HapticFeedback.lightImpact();
    if (item.type == NotificationType.friendRequest) {
      try {
        await ref.read(friendRequestProvider.notifier).rejectRequest(
          (item.data as Friendship).id,
        );
        if (context.mounted) {
          context.showSuccessSnackBar('Request declined');
          ref.invalidate(pendingRequestsProvider);
        }
      } catch (_) {
        if (context.mounted) context.showErrorSnackBar('Failed to decline request');
      }
    } else if (item.type == NotificationType.collaborationInvite) {
      try {
        await ref.read(momentRepositoryProvider).removeContributor(
          (item.data as MomentContributor).id,
        );
        if (context.mounted) context.showSuccessSnackBar('Invite declined');
      } catch (_) {
        if (context.mounted) context.showErrorSnackBar('Failed to decline invite');
      }
    }
  }

  // ── Local-first moment helpers ────────────────────────────────────────────

  Future<Moment?> _getMomentLocalFirst(WidgetRef ref, String momentId) async {
    final ps = ref.read(chatPowerSyncServiceProvider);
    if (await ps.ensureInitialized()) {
      final local = await ps.getMomentById(momentId);
      if (local != null) return local;
    }
    return ref.read(momentRepositoryProvider).getMomentById(momentId);
  }

  Future<List<Moment>> _getMomentsByGroupLocalFirst(
    WidgetRef ref,
    String groupId,
  ) async {
    final ps = ref.read(chatPowerSyncServiceProvider);
    if (await ps.ensureInitialized()) {
      final local = await ps.getMomentsByGroup(groupId);
      if (local.isNotEmpty) return local;
    }
    return ref.read(momentRepositoryProvider).getMomentsByGroup(groupId);
  }
}

// ── Card layout ───────────────────────────────────────────────────────────────

class _CardContent extends StatelessWidget {
  final NotificationItem item;
  final NotificationTypeConfig config;
  final bool requiresAction;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _CardContent({
    required this.item,
    required this.config,
    required this.requiresAction,
    required this.onTap,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead
                ? Colors.grey.shade200
                : config.accentColor.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent strip
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: config.accentColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Avatar(item: item, config: config),
                            const SizedBox(width: 12),
                            Expanded(child: _TextContent(item: item, config: config)),
                            if (!item.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: config.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (requiresAction)
                        _ActionRow(
                          config: config,
                          onAccept: onAccept,
                          onDecline: onDecline,
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
}

class _Avatar extends StatelessWidget {
  final NotificationItem item;
  final NotificationTypeConfig config;

  const _Avatar({required this.item, required this.config});

  @override
  Widget build(BuildContext context) {
    if (item.actorAvatarUrl != null && item.actorAvatarUrl!.isNotEmpty) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: item.actorAvatarUrl!,
            fit: BoxFit.cover,
            placeholder: (ctx, url) => _iconAvatar(config),
            errorWidget: (ctx, url, err) => _iconAvatar(config),
          ),
        ),
      );
    }
    return _iconAvatar(config);
  }

  Widget _iconAvatar(NotificationTypeConfig config) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: config.accentColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(config.icon, color: config.accentColor, size: 20)),
    );
  }
}

class _TextContent extends StatelessWidget {
  final NotificationItem item;
  final NotificationTypeConfig config;

  const _TextContent({required this.item, required this.config});

  @override
  Widget build(BuildContext context) {
    final bodyText = (item.actorName != null && item.body.startsWith(item.actorName!))
        ? item.body.substring(item.actorName!.length).trim()
        : item.body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: config.accentColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            config.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: config.accentColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Actor + body
        RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.4),
            children: [
              if (item.actorName != null)
                TextSpan(
                  text: '${item.actorName} ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              TextSpan(
                text: bodyText,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // Group title (collab invites)
        if (item.type == NotificationType.collaborationInvite &&
            item.groupTitle != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(CupertinoIcons.folder, size: 14, color: config.accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.groupTitle!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: config.accentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        TimeAgoText(
          dateTime: item.createdAt,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final NotificationTypeConfig config;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _ActionRow({
    required this.config,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Accept',
              isPrimary: true,
              color: config.accentColor,
              onPressed: onAccept,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              label: 'Decline',
              isPrimary: false,
              color: Colors.grey,
              onPressed: onDecline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? color : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
