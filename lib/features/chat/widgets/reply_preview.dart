import 'package:flutter/material.dart';
import 'package:moments/data/models/message.dart';

/// WhatsApp-style reply preview shown inside message bubbles
/// Shows a compact preview with left accent border
class ReplyPreview extends StatelessWidget {
  const ReplyPreview({
    super.key,
    required this.message,
    required this.senderName,
    this.onCancel,
    this.isInsideBubble = false,
    this.isFromMe = false,
  });

  final Message message;
  final String senderName;
  final VoidCallback? onCancel;
  final bool isInsideBubble;
  final bool isFromMe; // Is the REPLY sender me (affects colors)

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine content preview
    String contentPreview;
    IconData? mediaIcon;

    if (message.isDeleted || message.deletedFor == 'everyone') {
      contentPreview = 'This message was deleted';
      mediaIcon = Icons.block;
    } else {
      switch (message.messageType) {
        case MessageType.image:
          contentPreview = '📷 Photo';
          mediaIcon = Icons.image;
          break;
        case MessageType.video:
          contentPreview = '🎬 Video';
          mediaIcon = Icons.videocam;
          break;
        case MessageType.audio:
          contentPreview = '🎤 Voice message';
          mediaIcon = Icons.mic;
          break;
        case MessageType.file:
          contentPreview = '📎 File';
          mediaIcon = Icons.attach_file;
          break;
        default:
          contentPreview = message.content.length > 60
              ? '${message.content.substring(0, 60)}...'
              : message.content;
      }
    }

    // Colors based on context
    final Color accentColor;
    final Color bgColor;
    final Color textColor;
    final Color nameColor;

    if (isInsideBubble) {
      // Inside a sent/received bubble
      if (isFromMe) {
        // Inside my (blue) bubble
        accentColor = Colors.white.withValues(alpha: 0.6);
        bgColor = Colors.white.withValues(alpha: 0.15);
        textColor = Colors.white.withValues(alpha: 0.9);
        nameColor = Colors.white;
      } else {
        // Inside their (white/grey) bubble
        accentColor = const Color(0xFF25D366); // WhatsApp green
        bgColor = isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.12);
        textColor = isDark ? Colors.white70 : Colors.black87;
        nameColor = const Color(0xFF25D366);
      }
    } else {
      // In input area (composing)
      accentColor = const Color(0xFF25D366);
      bgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
      textColor = isDark ? Colors.white70 : Colors.black87;
      nameColor = const Color(0xFF25D366);
    }

    return Container(
      margin: isInsideBubble
          ? const EdgeInsets.only(bottom: 6)
          : const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar (WhatsApp style)
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sender name
                    Text(
                      senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: nameColor,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Content preview
                    Row(
                      children: [
                        if (mediaIcon != null &&
                            message.messageType != MessageType.text) ...[
                          Icon(
                            mediaIcon,
                            size: 14,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            contentPreview,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                              fontStyle: message.isDeleted
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Cancel button (only in input area)
            if (onCancel != null)
              GestureDetector(
                onTap: onCancel,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
