import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wrapper that adds swipe-to-dismiss functionality with smooth elastic animation
/// Similar to SwipeableMessage but for notifications (swipe left to dismiss)
class SwipeableNotification extends StatefulWidget {
  const SwipeableNotification({
    super.key,
    required this.child,
    required this.onDismiss,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onDismiss;
  final bool enabled;

  @override
  State<SwipeableNotification> createState() => _SwipeableNotificationState();
}

class _SwipeableNotificationState extends State<SwipeableNotification>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _hasTriggered = false;
  late AnimationController _iconController;

  static const _triggerThreshold = 80.0;
  static const _maxDrag = 120.0;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;

    setState(() {
      // Only allow dragging left (negative values)
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-_maxDrag, 0);

      // Update icon animation based on progress
      _iconController.value = (_dragOffset.abs() / _triggerThreshold).clamp(
        0,
        1,
      );

      // Trigger haptic when threshold is crossed
      if (_dragOffset.abs() >= _triggerThreshold && !_hasTriggered) {
        _hasTriggered = true;
        HapticFeedback.mediumImpact();
      } else if (_dragOffset.abs() < _triggerThreshold && _hasTriggered) {
        _hasTriggered = false;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() >= _triggerThreshold) {
      // Animate out before dismissing
      setState(() {
        _dragOffset = -MediaQuery.of(context).size.width;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        debugPrint('SwipeableNotification: Dismiss triggered via swipe');
        widget.onDismiss();
      });
    } else {
      setState(() {
        _dragOffset = 0;
        _hasTriggered = false;
      });
      _iconController.animateTo(0, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          // Delete icon removed as per request

          // Notification with smooth offset animation (elastic bounce back)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: _dragOffset, end: _dragOffset),
            duration: _dragOffset == 0
                ? const Duration(milliseconds: 300)
                : Duration.zero,
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(value, 0),
                child: child,
              );
            },
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
