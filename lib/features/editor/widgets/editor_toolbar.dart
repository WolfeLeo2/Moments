import 'package:flutter/material.dart';
import '../controllers/editor_controller.dart';
import '../../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom toolbar for the editor with mode switching and tools
class EditorToolbar extends StatelessWidget {
  final EditorController controller;
  final VoidCallback onStickerTap;
  final VoidCallback onTextTap;
  final VoidCallback onPreview;
  
  const EditorToolbar({
    super.key,
    required this.controller,
    required this.onStickerTap,
    required this.onTextTap,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundBeige,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tool buttons
                Row(
                  children: [
                    _buildToolButton(
                      icon: Icons.emoji_emotions_outlined,
                      label: 'Sticker',
                      isSelected: controller.mode == EditorMode.sticker,
                      onTap: onStickerTap,
                    ),
                    const SizedBox(width: 8),
                    _buildToolButton(
                      icon: Icons.gesture,
                      label: 'Draw',
                      isSelected: controller.mode == EditorMode.draw,
                      onTap: () {
                        controller.setMode(
                          controller.mode == EditorMode.draw
                              ? EditorMode.select
                              : EditorMode.draw,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildToolButton(
                      icon: Icons.text_fields,
                      label: 'Text',
                      isSelected: controller.mode == EditorMode.text,
                      onTap: onTextTap,
                    ),
                  ],
                ),
                
                // Preview button
                _buildPreviewButton(onPreview),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.borderBlack : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.borderBlack : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : AppTheme.borderBlack,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreviewButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.borderBlack,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          'Preview',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Drawing tools toolbar (shown when in draw mode)
class DrawingToolbar extends StatelessWidget {
  final EditorController controller;
  
  const DrawingToolbar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderBlack, width: 2),
            boxShadow: AppTheme.brutalShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildColorOption(Colors.white),
                  _buildColorOption(Colors.black),
                  _buildColorOption(Colors.red),
                  _buildColorOption(Colors.orange),
                  _buildColorOption(Colors.yellow),
                  _buildColorOption(Colors.green),
                  _buildColorOption(Colors.blue),
                  _buildColorOption(Colors.purple),
                ],
              ),
              const SizedBox(height: 12),
              // Stroke width slider
              Row(
                children: [
                  const Icon(Icons.line_weight, size: 18),
                  Expanded(
                    child: Slider(
                      value: controller.drawingStrokeWidth,
                      min: 2,
                      max: 20,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (value) {
                        controller.setDrawingStrokeWidth(value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildColorOption(Color color) {
    final isSelected = controller.drawingColor == color;
    return GestureDetector(
      onTap: () => controller.setDrawingColor(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: color == Colors.white
              ? [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
