import 'package:chat_bubbles/chat_bubbles.dart' as cb;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.tail = true,
    this.replySenderName,
    this.currentUserId,
    this.onTap,
    this.onLongPress,
    this.onRetry,
  });

  final Message message;
  final bool isMe;
  final bool tail;
  final String? replySenderName;
  final String? currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final textColor = isMe ? Colors.white : Colors.black87;
    final bubbleColor = isMe ? AppTheme.primaryBlue : Colors.white;
    final timestamp = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(message.createdAt));
    final status = _statusFromSendStatus(message.sendStatus);
    final isDeleted = message.isDeleted || message.deletedFor == 'everyone';

    Widget bubble;

    if (isDeleted) {
      bubble = cb.BubbleNormal(
        text: 'This message was deleted',
        isSender: isMe,
        color: bubbleColor.withValues(alpha: 0.7),
        tail: tail,
        textStyle:
            Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ) ??
            TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
        timestamp: timestamp,
        sent: status.sent,
        delivered: status.delivered,
        seen: status.seen,
        isEdited: message.isEdited,
      );
    } else if (message.replyToMessage != null) {
      bubble = cb.BubbleReply(
        repliedMessage: _replyPreview(message.replyToMessage!),
        repliedMessageSender: replySenderName ?? 'Unknown',
        text: message.content,
        isSender: isMe,
        color: bubbleColor,
        tail: tail,
        replyBorderColor: isMe
            ? Colors.white.withValues(alpha: 0.65)
            : AppTheme.primaryBlue,
        textStyle:
            Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: textColor) ??
            TextStyle(color: textColor, fontSize: 14),
        repliedMessageTextStyle:
            Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.78),
            ) ??
            TextStyle(color: textColor.withValues(alpha: 0.78), fontSize: 12),
        repliedMessageSenderTextStyle:
            Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isMe ? Colors.white : AppTheme.primaryBlue,
              fontWeight: FontWeight.w700,
            ) ??
            TextStyle(
              color: isMe ? Colors.white : AppTheme.primaryBlue,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
        timestamp: timestamp,
        sent: status.sent,
        delivered: status.delivered,
        seen: status.seen,
        isEdited: message.isEdited,
      );
    } else {
      bubble = cb.BubbleNormal(
        text: message.content,
        isSender: isMe,
        color: bubbleColor,
        tail: tail,
        textStyle:
            Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: textColor) ??
            TextStyle(color: textColor, fontSize: 14),
        timestamp: timestamp,
        sent: status.sent,
        delivered: status.delivered,
        seen: status.seen,
        isEdited: message.isEdited,
      );
    }

    if (onTap != null || onLongPress != null) {
      bubble = GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: bubble,
      );
    }

    final reactionModels = _buildReactionModels();

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bubble,
        if (reactionModels.isNotEmpty)
          cb.BubbleReaction(
            reactions: reactionModels,
            showAddButton: false,
            alignRight: isMe,
            backgroundColor: Colors.white,
            userReactionColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
            textColor: Colors.black87,
            borderColor: Colors.grey.withValues(alpha: 0.2),
            emojiSize: 14,
            chipPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            spacing: 4,
            borderRadius: 12,
          ),
        if (isMe && _hasUploadHint(message.sendStatus))
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 2, bottom: 6),
            child: _buildUploadHint(context),
          ),
      ],
    );
  }

  String _replyPreview(Message reply) {
    switch (reply.messageType) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎬 Video';
      case MessageType.audio:
        return '🎤 Audio';
      case MessageType.gif:
        return '🎞️ GIF';
      case MessageType.sticker:
        return '🎭 Sticker';
      default:
        final text = reply.content.trim();
        if (text.length <= 60) return text;
        return '${text.substring(0, 60)}...';
    }
  }

  List<cb.Reaction> _buildReactionModels() {
    final grouped = <String, int>{};
    final reactedByMe = <String, bool>{};

    for (final reaction in message.reactions) {
      grouped[reaction.emoji] = (grouped[reaction.emoji] ?? 0) + 1;
      if (reaction.userId == currentUserId) {
        reactedByMe[reaction.emoji] = true;
      }
    }

    return grouped.entries
        .map(
          (entry) => cb.Reaction(
            emoji: entry.key,
            count: entry.value,
            isUserReacted: reactedByMe[entry.key] ?? false,
          ),
        )
        .toList(growable: false);
  }

  bool _hasUploadHint(MessageSendStatus status) {
    return status == MessageSendStatus.pending ||
        status == MessageSendStatus.sending ||
        status == MessageSendStatus.failed;
  }

  Widget _buildUploadHint(BuildContext context) {
    switch (message.sendStatus) {
      case MessageSendStatus.pending:
      case MessageSendStatus.sending:
        return Text(
          'Sending...',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        );
      case MessageSendStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                color: AppTheme.emergencyRed,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                'Tap to retry',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.emergencyRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case MessageSendStatus.sent:
      case MessageSendStatus.delivered:
      case MessageSendStatus.read:
        return const SizedBox.shrink();
    }
  }

  _MessageStatusFlags _statusFromSendStatus(MessageSendStatus status) {
    switch (status) {
      case MessageSendStatus.read:
        return const _MessageStatusFlags(
          sent: true,
          delivered: true,
          seen: true,
        );
      case MessageSendStatus.delivered:
        return const _MessageStatusFlags(
          sent: true,
          delivered: true,
          seen: false,
        );
      case MessageSendStatus.sent:
        return const _MessageStatusFlags(
          sent: true,
          delivered: false,
          seen: false,
        );
      case MessageSendStatus.pending:
      case MessageSendStatus.sending:
      case MessageSendStatus.failed:
        return const _MessageStatusFlags(
          sent: false,
          delivered: false,
          seen: false,
        );
    }
  }
}

class _MessageStatusFlags {
  final bool sent;
  final bool delivered;
  final bool seen;

  const _MessageStatusFlags({
    required this.sent,
    required this.delivered,
    required this.seen,
  });
}
