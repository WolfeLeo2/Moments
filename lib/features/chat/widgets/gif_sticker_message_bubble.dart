import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/message.dart';
import 'package:hugeicons/hugeicons.dart';

/// Renders a GIF or sticker as a floating media bubble (no message bubble background).
///
/// GIFs display with rounded corners + GIPHY attribution badge.
/// Stickers display with transparent background, no border.
class GifStickerMessageBubble extends StatelessWidget {
  const GifStickerMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onRetry,
  });

  final Message message;
  final bool isMe;
  final VoidCallback? onRetry;

  bool get _isSticker => message.messageType == MessageType.sticker;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.65;
    final mediaUrl = message.content;
    final hasReactions = message.reactions.isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isMe ? 64 : 8,
          right: isMe ? 8 : 64,
          top: 2,
          bottom: hasReactions ? 14 : 2,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: isMe ? Alignment.bottomRight : Alignment.bottomLeft,
          children: [
            Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // The media itself
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: _isSticker ? 150 : 250,
                  ),
                  child: _buildMedia(mediaUrl),
                ),

                // Status row for sent messages
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 4),
                    child: _buildStatusRow(context),
                  ),
              ],
            ),

            // Reactions
            if (hasReactions)
              Positioned(
                bottom: -10,
                right: isMe ? 12 : null,
                left: isMe ? null : 12,
                child: _buildReactions(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(String url) {
    if (_isSticker) {
      // Stickers: transparent background, no border
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (context, url) => const SizedBox(
          width: 120,
          height: 120,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    // GIF: rounded corners, GIPHY attribution
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
          // GIPHY attribution badge (bottom-left like WhatsApp)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'GIPHY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
    final statusColor = AppTheme.textGray.withValues(alpha: 0.5);
    const iconSize = 13.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [_buildStatusIcon(statusColor, iconSize)],
    );
  }

  Widget _buildStatusIcon(Color statusColor, double iconSize) {
    switch (message.sendStatus) {
      case MessageSendStatus.pending:
      case MessageSendStatus.sending:
        return SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: statusColor,
          ),
        );
      case MessageSendStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                color: AppTheme.emergencyRed,
                size: iconSize,
              ),
              const SizedBox(width: 4),
              const Text(
                'Tap to retry',
                style: TextStyle(
                  color: AppTheme.emergencyRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case MessageSendStatus.sent:
        return HugeIcon(
          icon: HugeIcons.strokeRoundedTick01,
          color: statusColor,
          size: iconSize,
        );
      case MessageSendStatus.delivered:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedTick01,
              color: statusColor,
              size: iconSize - 2,
            ),
            Transform.translate(
              offset: const Offset(-4, 0),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedTick01,
                color: statusColor,
                size: iconSize - 2,
              ),
            ),
          ],
        );
      case MessageSendStatus.read:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedTick01,
              color: AppTheme.primaryBlue,
              size: iconSize - 2,
            ),
            Transform.translate(
              offset: const Offset(-4, 0),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedTick01,
                color: AppTheme.primaryBlue,
                size: iconSize - 2,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildReactions(BuildContext context) {
    final emojiCounts = <String, int>{};
    for (final reaction in message.reactions) {
      emojiCounts[reaction.emoji] = (emojiCounts[reaction.emoji] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Wrap(
        spacing: 4,
        children: emojiCounts.entries.map((entry) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entry.key, style: const TextStyle(fontSize: 12)),
              if (entry.value > 1) ...[
                const SizedBox(width: 2),
                Text(
                  '${entry.value}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}
