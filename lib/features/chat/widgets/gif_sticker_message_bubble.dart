import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_bubbles/chat_bubbles.dart' as cb;
import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/message.dart';

class GifStickerMessageBubble extends StatelessWidget {
  const GifStickerMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.currentUserId,
    this.onRetry,
  });

  final Message message;
  final bool isMe;
  final String? currentUserId;
  final VoidCallback? onRetry;

  bool get _isSticker => message.messageType == MessageType.sticker;

  @override
  Widget build(BuildContext context) {
    final status = _statusFromSendStatus(message.sendStatus);
    final reactions = _buildReactionModels();

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        cb.BubbleNormalImage(
          id: 'gif_sticker_${message.id}',
          image: _buildMedia(message.content),
          isSender: isMe,
          color: isMe ? AppTheme.primaryBlue : Colors.white,
          tail: true,
          sent: status.sent,
          delivered: status.delivered,
          seen: status.seen,
          timestamp: MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(message.createdAt),
          ),
          messageId: message.id,
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        ),
        if (reactions.isNotEmpty)
          cb.BubbleReaction(
            reactions: reactions,
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

  Widget _buildMedia(String url) {
    if (_isSticker) {
      return SizedBox(
        width: 140,
        height: 140,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (context, _) => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, _, __) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      width: 220,
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, _) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, _, __) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
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
      ),
    );
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
          child: Text(
            'Tap to retry',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.emergencyRed,
                  fontWeight: FontWeight.w600,
                ),
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
        return const _MessageStatusFlags(sent: true, delivered: true, seen: true);
      case MessageSendStatus.delivered:
        return const _MessageStatusFlags(sent: true, delivered: true, seen: false);
      case MessageSendStatus.sent:
        return const _MessageStatusFlags(sent: true, delivered: false, seen: false);
      case MessageSendStatus.pending:
      case MessageSendStatus.sending:
      case MessageSendStatus.failed:
        return const _MessageStatusFlags(sent: false, delivered: false, seen: false);
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
