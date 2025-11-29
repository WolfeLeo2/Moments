import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/features/chat/widgets/custom_bubble_special_three.dart';

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
        CustomBubbleSpecialThree(
          child: Text(
            message.content,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
          color: isMe ? AppTheme.electricPurple : Colors.white,
          tail: tail,
          isSender: isMe,
        ),
      ],
    );
  }
}
