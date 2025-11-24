import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/message.dart';

import 'package:chat_bubbles/chat_bubbles.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool tail;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.tail = true,
  });


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        BubbleSpecialThree(
          text: message.content,
          color: isMe ? AppTheme.electricPurple : Colors.white,
          tail: tail,
          textStyle: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 13,
          ),
          isSender: isMe,
          sent: isMe,
          delivered: isMe,
          seen: isMe && message.isRead,
        ),
      ],
    );
  }
}
