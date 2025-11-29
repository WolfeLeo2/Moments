import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:moments/features/chat/widgets/custom_bubble_special_three.dart';

/// Typing indicator bubble that appears when the other user is typing
class TypingIndicatorBubble extends StatelessWidget {
  const TypingIndicatorBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomBubbleSpecialThree(
      isSender: false,
      tail: true,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal:0, vertical: 0),
        child: SizedBox(
          width: 60,
          height: 50,
          child: Lottie.asset(
            'assets/animations/typing.json',
            fit: BoxFit.contain,
            repeat: true, // Loop the animation continuously
          ),
        ),
      ),
    );
  }
}
