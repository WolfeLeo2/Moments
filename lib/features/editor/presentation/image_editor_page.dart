import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../controllers/editor_controller.dart';
import '../widgets/editor_canvas.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/sticker_picker.dart';

/// Main image editor page - Instagram/Snapchat style
class ImageEditorPage extends StatefulWidget {
  final List<String> imagePaths;
  final Function(List<String> editedPaths)? onComplete;

  const ImageEditorPage({super.key, required this.imagePaths, this.onComplete});

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  late EditorController _controller;
  bool _isExporting = false;

  // Canvas size (will be calculated based on screen)
  double _canvasWidth = 0;
  double _canvasHeight = 0;

  @override
  void initState() {
    super.initState();
    _controller = EditorController(imagePaths: widget.imagePaths);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Calculate canvas size based on screen
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    _canvasWidth = screenWidth - 40; // 20px padding on each side
    _canvasHeight = screenHeight * 0.55; // Leave room for toolbar
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.backgroundBeige,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              // Image thumbnails (for multiple images)
              if (widget.imagePaths.length > 1) _buildImageThumbnails(),

              // Main canvas area
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Deselect when tapping outside
                    if (_controller.mode == EditorMode.select) {
                      _controller.clearSelection();
                    }
                  },
                  child: Container(
                    color: AppTheme.backgroundBeige,
                    child: Center(
                      child: EditorCanvas(
                        controller: _controller,
                        width: _canvasWidth,
                        height: _canvasHeight,
                      ),
                    ),
                  ),
                ),
              ),

              // Drawing toolbar (when in draw mode)
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.mode == EditorMode.draw) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DrawingToolbar(controller: _controller),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Bottom toolbar
              EditorToolbar(
                controller: _controller,
                onStickerTap: _showStickerPicker,
                onTextTap: _showTextInput,
                onPreview: _handlePreview,
              ),
            ],
          ),
        ),
        // Loading overlay when exporting
        if (_isExporting)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Saving...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.backgroundBeige,
      elevation: 0,
      leading: IconButton(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          color: AppTheme.borderBlack,
          size: 28,
        ),
        onPressed: () => _handleBack(),
      ),
      title: Text(
        'Edit',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.borderBlack,
        ),
      ),
      centerTitle: true,
      actions: [
        // Undo button (if there are items)
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.selectedItem != null) {
              return IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  HapticService.lightTap();
                  _controller.deleteSelectedItem();
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildImageThumbnails() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.imagePaths.length,
            itemBuilder: (context, index) {
              final isSelected = index == _controller.currentImageIndex;
              final hasEdits = _controller.getItemsForImage(index).isNotEmpty;

              return GestureDetector(
                onTap: () {
                  HapticService.lightTap();
                  _controller.setCurrentImage(index);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.file(
                          File(widget.imagePaths[index]),
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                        ),
                      ),
                      // Edit indicator
                      if (hasEdits)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.brightYellow,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.borderBlack,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showStickerPicker() {
    HapticService.lightTap();
    _controller.setMode(EditorMode.sticker);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StickerPicker(controller: _controller),
    );
  }

  void _showTextInput() {
    HapticService.lightTap();
    _controller.setMode(EditorMode.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TextInputDialog(controller: _controller),
    );
  }

  void _handleBack() {
    if (_controller.hasEdits) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Discard Changes?',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You have unsaved edits. Are you sure you want to discard them?',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close editor
              },
              child: Text(
                'Discard',
                style: GoogleFonts.inter(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handlePreview() async {
    HapticService.mediumTap();

    if (!_controller.hasEdits) {
      // No edits, just return original paths
      widget.onComplete?.call(widget.imagePaths);
      Navigator.pop(context, widget.imagePaths);
      return;
    }

    setState(() => _isExporting = true);

    try {
      // Export edited images
      final editedPaths = await _exportAllImages();

      widget.onComplete?.call(editedPaths);
      if (mounted) {
        Navigator.pop(context, editedPaths);
      }
    } catch (e) {
      debugPrint('Error exporting images: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving edits: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<List<String>> _exportAllImages() async {
    final exportedPaths = <String>[];
    final tempDir = await getTemporaryDirectory();

    // Save current image index
    final originalIndex = _controller.currentImageIndex;

    for (int i = 0; i < widget.imagePaths.length; i++) {
      final items = _controller.getItemsForImage(i);

      if (items.isEmpty) {
        // No edits for this image, use original
        exportedPaths.add(widget.imagePaths[i]);
      } else {
        // Switch to this image and capture
        _controller.setCurrentImage(i);

        // Wait for rebuild
        await Future.delayed(const Duration(milliseconds: 100));

        // Capture the canvas
        final path = await _captureCanvas(i, tempDir.path);
        exportedPaths.add(path ?? widget.imagePaths[i]);
      }
    }

    // Restore original index
    _controller.setCurrentImage(originalIndex);

    return exportedPaths;
  }

  Future<String?> _captureCanvas(int imageIndex, String tempPath) async {
    try {
      final boundary =
          _controller.canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      final fileName =
          'edited_${imageIndex}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '$tempPath/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return filePath;
    } catch (e) {
      debugPrint('Error capturing canvas: $e');
      return null;
    }
  }
}
