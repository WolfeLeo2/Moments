import 'dart:io';
import 'package:flutter/material.dart';
import '../models/editor_item.dart';
import '../controllers/editor_controller.dart';
import 'editor_item_widget.dart';

/// The main canvas where the image and items are rendered
class EditorCanvas extends StatelessWidget {
  final EditorController controller;
  final double width;
  final double height;
  
  const EditorCanvas({
    super.key,
    required this.controller,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return RepaintBoundary(
          key: controller.canvasKey,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  _buildImage(),
                  
                  // Editor items (stickers, text, drawings)
                  ..._buildItems(),
                  
                  // Current drawing path (while drawing)
                  if (controller.mode == EditorMode.draw &&
                      controller.currentDrawingPoints.isNotEmpty)
                    CustomPaint(
                      painter: DrawingPainter(
                        points: controller.currentDrawingPoints,
                        color: controller.drawingColor,
                        strokeWidth: controller.drawingStrokeWidth,
                      ),
                      size: Size(width, height),
                    ),
                  
                  // Drawing gesture detector (when in draw mode)
                  if (controller.mode == EditorMode.draw)
                    GestureDetector(
                      onPanStart: (details) {
                        controller.startDrawing(details.localPosition);
                      },
                      onPanUpdate: (details) {
                        controller.continueDrawing(details.localPosition);
                      },
                      onPanEnd: (_) {
                        controller.endDrawing();
                      },
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  
                  // Tap to deselect (when in select mode)
                  if (controller.mode == EditorMode.select && 
                      controller.selectedItemId != null)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          // Only deselect if tapping on background
                          controller.clearSelection();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildImage() {
    final imagePath = controller.currentImagePath;
    
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[800],
          child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
        ),
      );
    }
    
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[800],
        child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
      ),
    );
  }
  
  List<Widget> _buildItems() {
    // Sort items by zIndex for proper layering
    final sortedItems = List<EditorItem>.from(controller.currentItems)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    
    return sortedItems.map((item) {
      return EditorItemWidget(
        key: ValueKey(item.id),
        item: item,
        isSelected: item.id == controller.selectedItemId,
        controller: controller,
        onTap: () {
          if (controller.mode == EditorMode.select ||
              controller.mode == EditorMode.sticker ||
              controller.mode == EditorMode.text) {
            controller.selectItem(item.id);
          }
        },
      );
    }).toList();
  }
}
