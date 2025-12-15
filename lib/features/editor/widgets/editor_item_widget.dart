import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/editor_item.dart';
import '../controllers/editor_controller.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget for rendering and interacting with an editor item
class EditorItemWidget extends StatefulWidget {
  final EditorItem item;
  final bool isSelected;
  final EditorController controller;
  final VoidCallback onTap;

  const EditorItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.controller,
    required this.onTap,
  });

  @override
  State<EditorItemWidget> createState() => _EditorItemWidgetState();
}

class _EditorItemWidgetState extends State<EditorItemWidget> {
  double _initialRotation = 0;
  double _initialScale = 1;
  Offset _rotateScaleStart = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.item.position.dx,
      top: widget.item.position.dy,
      child: Transform.rotate(
        angle: widget.item.rotation,
        child: Transform.scale(
          scale: widget.item.scale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The actual item content with drag gesture
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                child: _buildItemContent(),
              ),

              // Selection handles (only when selected)
              if (widget.isSelected) ...[
                // Delete button
                Positioned(
                  top: -20,
                  right: -20,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.controller.deleteItem(widget.item.id),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // Rotate/Scale handle - LARGER for easier interaction
                Positioned(
                  bottom: -24,
                  right: -24,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _onRotateScaleStart,
                    onPanUpdate: _onRotateScaleUpdate,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.open_with,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // Selection border
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemContent() {
    switch (widget.item.type) {
      case EditorItemType.sticker:
        return _buildSticker(widget.item as StickerItem);
      case EditorItemType.text:
        return _buildText(widget.item as TextItem);
      case EditorItemType.drawing:
        return _buildDrawing(widget.item as DrawingItem);
    }
  }

  Widget _buildSticker(StickerItem sticker) {
    if (sticker.isEmoji && sticker.emojiChar != null) {
      return Text(sticker.emojiChar!, style: const TextStyle(fontSize: 64));
    }

    // Network or asset sticker
    if (sticker.assetPath.startsWith('http')) {
      return Image.network(
        sticker.assetPath,
        width: 100,
        height: 100,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
      );
    }

    return Image.asset(
      sticker.assetPath,
      width: 100,
      height: 100,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
    );
  }

  Widget _buildText(TextItem textItem) {
    final textStyle = _getTextStyle(textItem);

    Widget textWidget;
    if (textItem.hasOutline) {
      textWidget = Stack(
        children: [
          // Outline
          Text(
            textItem.text,
            style: textStyle.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4
                ..color = textItem.outlineColor,
            ),
            textAlign: textItem.textAlign,
          ),
          // Fill
          Text(textItem.text, style: textStyle, textAlign: textItem.textAlign),
        ],
      );
    } else {
      textWidget = Text(
        textItem.text,
        style: textStyle,
        textAlign: textItem.textAlign,
      );
    }

    if (textItem.backgroundColor != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: textItem.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: textWidget,
      );
    }

    return textWidget;
  }

  TextStyle _getTextStyle(TextItem textItem) {
    // Map font families to Google Fonts
    switch (textItem.fontFamily) {
      case 'Bangers':
        return GoogleFonts.bangers(
          fontSize: textItem.fontSize,
          fontWeight: textItem.fontWeight,
          color: textItem.textColor,
        );
      case 'Bebas Neue':
        return GoogleFonts.bebasNeue(
          fontSize: textItem.fontSize,
          fontWeight: textItem.fontWeight,
          color: textItem.textColor,
        );
      case 'Pacifico':
        return GoogleFonts.pacifico(
          fontSize: textItem.fontSize,
          fontWeight: textItem.fontWeight,
          color: textItem.textColor,
        );
      case 'Roboto':
        return GoogleFonts.roboto(
          fontSize: textItem.fontSize,
          fontWeight: textItem.fontWeight,
          color: textItem.textColor,
        );
      case 'Permanent Marker':
        return GoogleFonts.permanentMarker(
          fontSize: textItem.fontSize,
          fontWeight: textItem.fontWeight,
          color: textItem.textColor,
        );
      case 'Dancing Script':
        return GoogleFonts.dancingScript(
          fontSize: textItem.fontSize,
          fontWeight: textItem.fontWeight,
          color: textItem.textColor,
        );
      default:
        return GoogleFonts.inter(
          fontSize: textItem.fontSize,
          fontWeight: textItem.fontWeight,
          color: textItem.textColor,
        );
    }
  }

  Widget _buildDrawing(DrawingItem drawing) {
    if (drawing.points.isEmpty) return const SizedBox();

    return CustomPaint(
      painter: DrawingPainter(
        points: drawing.points,
        color: drawing.color,
        strokeWidth: drawing.strokeWidth,
      ),
      size: const Size(300, 300),
    );
  }

  void _onPanStart(DragStartDetails details) {
    // Position tracking not needed - we use delta in onPanUpdate
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final newPosition = widget.item.position + details.delta;
    widget.controller.updateItemPosition(widget.item.id, newPosition);
  }

  void _onRotateScaleStart(DragStartDetails details) {
    _rotateScaleStart = details.globalPosition;
    _initialRotation = widget.item.rotation;
    _initialScale = widget.item.scale;
  }

  void _onRotateScaleUpdate(DragUpdateDetails details) {
    // Calculate center of the item
    final center = widget.item.position + const Offset(50, 50);

    // Vector from center to start position
    final startVector = _rotateScaleStart - center;
    // Vector from center to current position
    final currentVector = details.globalPosition - center;

    // Calculate rotation change
    final startAngle = math.atan2(startVector.dy, startVector.dx);
    final currentAngle = math.atan2(currentVector.dy, currentVector.dx);
    final newRotation = _initialRotation + (currentAngle - startAngle);

    // Calculate scale change
    final startDistance = startVector.distance;
    final currentDistance = currentVector.distance;
    final scaleFactor = startDistance > 0
        ? currentDistance / startDistance
        : 1.0;
    final newScale = _initialScale * scaleFactor;

    widget.controller.updateItemTransform(
      widget.item.id,
      rotation: newRotation,
      scale: newScale,
    );
  }
}

/// Custom painter for drawing paths
class DrawingPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return points != oldDelegate.points ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
