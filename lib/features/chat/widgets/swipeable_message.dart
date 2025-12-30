import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wrapper that adds swipe-to-reply functionality with smooth animation
class SwipeableMessage extends StatefulWidget {
  const SwipeableMessage({
    super.key,
    required this.child,
    required this.onSwipe,
    this.isMe = false,
  });

  final Widget child;
  final VoidCallback onSwipe;
  final bool isMe;

  @override
  State<SwipeableMessage> createState() => _SwipeableMessageState();
}

class _SwipeableMessageState extends State<SwipeableMessage>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _hasTriggered = false;
  late AnimationController _iconController;

  static const _triggerThreshold = 60.0;
  static const _maxDrag = 80.0;

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
    setState(() {
      // Only allow dragging right
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(0, _maxDrag);

      // Update icon animation based on progress
      _iconController.value = (_dragOffset / _triggerThreshold).clamp(0, 1);

      // Trigger haptic when threshold is crossed
      if (_dragOffset >= _triggerThreshold && !_hasTriggered) {
        _hasTriggered = true;
        HapticFeedback.mediumImpact();
      } else if (_dragOffset < _triggerThreshold && _hasTriggered) {
        _hasTriggered = false;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset >= _triggerThreshold) {
      widget.onSwipe();
    }

    setState(() {
      _dragOffset = 0;
      _hasTriggered = false;
    });
    _iconController.animateTo(0, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Reply icon that appears as you swipe
          Positioned(
            left: 8,
            child: AnimatedBuilder(
              animation: _iconController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _iconController.value,
                  child: Opacity(
                    opacity: _iconController.value,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _hasTriggered
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.blue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.reply,
                        size: 20,
                        color: _hasTriggered
                            ? Colors.blue
                            : Colors.blue.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message with smooth offset animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: _dragOffset, end: _dragOffset),
            duration: _dragOffset == 0
                ? const Duration(milliseconds: 250)
                : Duration.zero,
            curve: Curves.easeOutBack,
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
