import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';

/// Animated heart widget using dotLottie animation
/// Plays heart (like) or dislike animation based on [isLike] parameter
class HeartAnimation extends StatefulWidget {
  final double size;
  final bool isLike; // true = heart animation, false = dislike animation
  final VoidCallback? onAnimationComplete;

  const HeartAnimation({
    super.key,
    this.size = 100,
    this.isLike = true,
    this.onAnimationComplete,
  });

  @override
  State<HeartAnimation> createState() => _HeartAnimationState();
}

class _HeartAnimationState extends State<HeartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
    
    // Start animation immediately
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animationPath = widget.isLike 
        ? 'assets/animations/heart.lottie'
        : 'assets/animations/dislike.lottie';
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: DotLottieLoader.fromAsset(
        animationPath,
        frameBuilder: (BuildContext ctx, DotLottie? dotlottie) {
          if (dotlottie != null) {
            return Lottie.memory(
              dotlottie.animations.values.single,
              controller: _controller,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              // Don't repeat - play once
              repeat: false,
            );
          } else {
            // Fallback while loading
            return const SizedBox.shrink();
          }
        },
        errorBuilder: (ctx, error, stack) {
          // Fallback to icon on error
          return Icon(
            widget.isLike ? Icons.favorite : Icons.heart_broken,
            size: widget.size * 0.8,
            color: widget.isLike ? Colors.red : Colors.grey,
          );
        },
      ),
    );
  }
}
