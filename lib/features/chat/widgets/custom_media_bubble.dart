import 'package:flutter/material.dart';

class CustomMediaBubble extends StatelessWidget {
  final bool isSender;
  final Widget? child;
  final bool tail;
  final Color color;

  final BoxConstraints? constraints;

  const CustomMediaBubble({
    Key? key,
    this.isSender = true,
    this.constraints,
    this.child,
    this.color = Colors.white70,
    this.tail = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.topRight : Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: CustomPaint(
          painter: _BubblePainter(
            color: color,
            alignment: isSender ? Alignment.topRight : Alignment.topLeft,
            tail: tail,
          ),
          child: Container(
            constraints:
                constraints ??
                BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * .7,
                ),
            padding: isSender
                ? const EdgeInsets.fromLTRB(4, 4, 14, 4)
                : const EdgeInsets.fromLTRB(14, 4, 4, 4),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: child ?? const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final Color color;
  final Alignment alignment;
  final bool tail;

  _BubblePainter({
    required this.color,
    required this.alignment,
    required this.tail,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getBubblePath(size, alignment, tail);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Shared Path Logic
Path _getBubblePath(Size size, Alignment alignment, bool tail) {
  var h = size.height;
  var w = size.width;
  final double _radius = 10.0;
  var path = Path();

  if (alignment == Alignment.topRight) {
    if (tail) {
      path.moveTo(_radius * 2, 0);
      path.quadraticBezierTo(0, 0, 0, _radius * 1.5);
      path.lineTo(0, h - _radius * 1.5);
      path.quadraticBezierTo(0, h, _radius * 2, h);
      path.lineTo(w - _radius * 3, h);
      path.quadraticBezierTo(
        w - _radius * 1.5,
        h,
        w - _radius * 1.5,
        h - _radius * 0.6,
      );
      path.quadraticBezierTo(w - _radius * 1, h, w, h);
      path.quadraticBezierTo(
        w - _radius * 0.8,
        h,
        w - _radius,
        h - _radius * 1.5,
      );
      path.lineTo(w - _radius, _radius * 1.5);
      path.quadraticBezierTo(w - _radius, 0, w - _radius * 3, 0);
    } else {
      path.moveTo(_radius * 2, 0);
      path.quadraticBezierTo(0, 0, 0, _radius * 1.5);
      path.lineTo(0, h - _radius * 1.5);
      path.quadraticBezierTo(0, h, _radius * 2, h);
      path.lineTo(w - _radius * 3, h);
      path.quadraticBezierTo(w - _radius, h, w - _radius, h - _radius * 1.5);
      path.lineTo(w - _radius, _radius * 1.5);
      path.quadraticBezierTo(w - _radius, 0, w - _radius * 3, 0);
    }
  } else {
    if (tail) {
      path.moveTo(_radius * 3, 0);
      path.quadraticBezierTo(_radius, 0, _radius, _radius * 1.5);
      path.lineTo(_radius, h - _radius * 1.5);
      path.quadraticBezierTo(_radius * .8, h, 0, h);
      path.quadraticBezierTo(_radius * 1, h, _radius * 1.5, h - _radius * 0.6);
      path.quadraticBezierTo(_radius * 1.5, h, _radius * 3, h);
      path.lineTo(w - _radius * 2, h);
      path.quadraticBezierTo(w, h, w, h - _radius * 1.5);
      path.lineTo(w, _radius * 1.5);
      path.quadraticBezierTo(w, 0, w - _radius * 2, 0);
    } else {
      path.moveTo(_radius * 3, 0);
      path.quadraticBezierTo(_radius, 0, _radius, _radius * 1.5);
      path.lineTo(_radius, h - _radius * 1.5);
      path.quadraticBezierTo(_radius, h, _radius * 3, h);
      path.lineTo(w - _radius * 2, h);
      path.quadraticBezierTo(w, h, w, h - _radius * 1.5);
      path.lineTo(w, _radius * 1.5);
      path.quadraticBezierTo(w, 0, w - _radius * 2, 0);
    }
  }
  return path;
}
