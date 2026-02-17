import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/utils/emoji_utils.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/features/chat/widgets/custom_bubble_special_three.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.tail = true,
    this.replySenderName,
    this.onTap,
    this.onLongPress,
    this.onSwipe,
    this.onRetry,
  });

  final bool isMe;
  final Message message;
  final bool tail;
  final String? replySenderName;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipe;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? AppTheme.primaryBlue : Colors.white;
    final textColor = isMe ? Colors.white : Colors.black87;
    // slightly reduced max width to accommodate reaction overlap if needed
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    // Handle deleted messages
    if (message.isDeleted || message.deletedFor == 'everyone') {
      return CustomBubbleSpecialThree(
        color: bubbleColor.withValues(alpha: 0.7),
        tail: tail,
        isSender: isMe,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 14,
              color: textColor.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              'This message was deleted',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // ── Emoji-only messages: render without bubble (WhatsApp-style) ──
    final content = message.content;
    if (message.messageType == MessageType.text &&
        message.replyToMessage == null &&
        isEmojiOnly(content)) {
      final emojiCount = countEmojis(content);
      final fontSize = emojiOnlyFontSize(emojiCount);
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
                  Text(content, style: TextStyle(fontSize: fontSize)),
                  // Status row
                  if (isMe)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _buildStatusIcon(
                        AppTheme.textGray.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
              // Reactions
              if (hasReactions)
                Positioned(
                  bottom: -10,
                  right: isMe ? 12 : null,
                  left: isMe ? null : 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                    child: _buildReactions(context),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Reaction variables
    final hasReactions = message.reactions.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onHorizontalDragEnd: onSwipe != null
          ? (details) {
              if (details.velocity.pixelsPerSecond.dx > 100) {
                onSwipe?.call();
              }
            }
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: isMe ? Alignment.bottomRight : Alignment.bottomLeft,
        children: [
          // Base Bubble
          Padding(
            padding: EdgeInsets.only(bottom: hasReactions ? 12.0 : 0),
            child: CustomBubbleSpecialThree(
              color: bubbleColor,
              tail: tail,
              isSender: isMe,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  minWidth: 80, // Ensure enough width for reactions
                ),
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reply preview
                      if (message.replyToMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: _buildCompactReplyPreview(context, textColor),
                        ),

                      // Message content
                      Text(
                        message.content,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: textColor),
                      ),

                      // Status row: edited label + send status (for sender only)
                      if (message.isEdited || isMe)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (message.isEdited)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    'Edited',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: textColor.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontStyle: FontStyle.italic,
                                          fontSize: 10,
                                        ),
                                  ),
                                ),
                              if (isMe) _buildStatusIcon(textColor),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Reactions overlay - positioned outside/at edge
          if (hasReactions)
            Positioned(
              bottom: 0,
              right: isMe ? 20 : null, // Shift slightly in from tail
              left: isMe ? null : 20,
              child: Container(
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
                child: _buildReactions(context),
              ),
            ),
        ],
      ),
    );
  }

  /// Compact reply preview
  Widget _buildCompactReplyPreview(BuildContext context, Color textColor) {
    final reply = message.replyToMessage!;
    final accentColor = isMe
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF25D366);
    final bgColor = isMe
        ? Colors.black.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.1);
    final nameColor = isMe
        ? Colors.white.withValues(alpha: 0.95)
        : const Color(0xFF25D366);
    final contentColor = isMe
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.black87;

    String preview = reply.content;
    if (reply.messageType == MessageType.image) {
      preview = '📷 Photo';
    } else if (reply.messageType == MessageType.video) {
      preview = '🎬 Video';
    } else if (reply.messageType == MessageType.audio) {
      preview = '🎤 Audio';
    } else if (reply.messageType == MessageType.gif) {
      preview = '🎞️ GIF';
    } else if (reply.messageType == MessageType.sticker) {
      preview = '🎭 Sticker';
    } else if (preview.length > 60) {
      preview = '${preview.substring(0, 60)}...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replySenderName ?? 'Unknown',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: nameColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            preview,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: contentColor, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build reaction row
  Widget _buildReactions(BuildContext context) {
    // Group reactions by emoji
    final emojiCounts = <String, int>{};
    for (final reaction in message.reactions) {
      emojiCounts[reaction.emoji] = (emojiCounts[reaction.emoji] ?? 0) + 1;
    }

    return Wrap(
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
    );
  }

  /// Build message send status icon (✓ ✓✓)
  Widget _buildStatusIcon(Color textColor) {
    final statusColor = textColor.withValues(alpha: 0.6);
    const iconSize = 14.0;

    switch (message.sendStatus) {
      case MessageSendStatus.pending:
        return SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: statusColor,
          ),
        );

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
              Text(
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
        // Blue double tick for read
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
}
