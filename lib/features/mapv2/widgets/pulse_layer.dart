import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/services/haptic_service.dart';

/// Overlay widget that renders an animated ripple "pulse" at a given screen
/// position. Used when a user long-presses a live friend's avatar on the map.
///
/// The animation consists of two expanding/fading rings emanating from the
/// tap point, paired with a haptic heartbeat pattern.
class PulseLayer extends StatefulWidget {
  /// Center position of the pulse in screen coordinates.
  final Offset center;

  /// Called when the animation completes.
  final VoidCallback? onComplete;

  /// Accent color for the rings (defaults to a warm amber).
  final Color color;

  const PulseLayer({
    super.key,
    required this.center,
    this.onComplete,
    this.color = const Color(0xFFFF9500),
  });

  @override
  State<PulseLayer> createState() => _PulseLayerState();
}

class _PulseLayerState extends State<PulseLayer> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _controller2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Fire haptic heartbeat
    HapticService.heartbeat();

    // Start the two rings staggered
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller2.forward();
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Wait for the second ring to finish too
        Future.delayed(const Duration(milliseconds: 400), () {
          widget.onComplete?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildRing(_controller),
        _buildRing(_controller2),
        // Center dot
        Positioned(
          left: widget.center.dx - 6,
          top: widget.center.dy - 6,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRing(AnimationController ctrl) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final scale = 1.0 + ctrl.value * 3.0; // Expand to 4x
        final opacity = (1.0 - ctrl.value).clamp(0.0, 0.7);
        final size = 40.0 * scale;

        return Positioned(
          left: widget.center.dx - size / 2,
          top: widget.center.dy - size / 2,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color,
                  width: math.max(1.0, 3.0 - ctrl.value * 2.5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
