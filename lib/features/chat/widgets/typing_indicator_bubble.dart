import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';

/// Typing indicator bubble that appears when the other user is typing
class TypingIndicatorBubble extends StatelessWidget {
  const TypingIndicatorBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return const TypingIndicatorWave(
      showIndicator: true,
      bubbleColor: Colors.white,
      dotColor: Colors.black54,
      dotSize: 7,
    );
  }
}
