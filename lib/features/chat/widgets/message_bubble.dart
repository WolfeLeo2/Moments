import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/features/chat/widgets/custom_bubble_special_three.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.tail = true,
  });

  final bool isMe;
  final Message message;
  final bool tail;

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
              fontSize: 14.5,
            ),
          ),
          color: isMe ? AppTheme.primaryBlue : Colors.white,
          tail: tail,
          isSender: isMe,
        ),
      ],
    );
  }
}
