import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../providers/story_providers.dart';

/// Quick-capture page for creating a story.
/// Phase 1: use image_picker for camera/gallery. Phase 2: custom camera UI.
class StoryCameraPage extends ConsumerStatefulWidget {
  const StoryCameraPage({super.key});

  @override
  ConsumerState<StoryCameraPage> createState() => _StoryCameraPageState();
}

class _StoryCameraPageState extends ConsumerState<StoryCameraPage> {
  final _imagePicker = ImagePicker();
  File? _capturedFile;
  String _mediaType = 'photo';
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Immediately open camera on page launch
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCamera());
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (file != null) {
      setState(() {
        _capturedFile = File(file.path);
        _mediaType = 'photo';
      });
    } else if (_capturedFile == null) {
      // User cancelled without capturing — go back
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (file != null) {
      setState(() {
        _capturedFile = File(file.path);
        _mediaType = 'photo';
      });
    }
  }

  Future<void> _captureVideo() async {
    final file = await _imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 30),
    );

    if (file != null) {
      setState(() {
        _capturedFile = File(file.path);
        _mediaType = 'video';
      });
    }
  }

  Future<void> _postStory() async {
    if (_capturedFile == null || _isUploading) return;

    setState(() => _isUploading = true);
    HapticService.mediumTap();

    try {
      final repo = ref.read(storyRepositoryProvider);
      await repo.createStory(
        mediaFile: _capturedFile!,
        mediaType: _mediaType,
        caption: _captionController.text.trim().isNotEmpty
            ? _captionController.text.trim()
            : null,
      );

      // Refresh stories list via explicit event signal.
      ref.read(storiesRefreshSignalProvider.notifier).bump();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post story: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedFile == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CupertinoActivityIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'Opening camera...',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return _buildEditor();
  }

  Widget _buildEditor() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  // Retake button
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    onPressed: _openCamera,
                    child: Text(
                      'Retake',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Preview
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _mediaType == 'photo'
                    ? Image.file(
                        _capturedFile!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.videocam_fill,
                              color: Colors.white54,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Video ready',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Caption + actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  // Caption field
                  CupertinoTextField(
                    controller: _captionController,
                    placeholder: 'Add a caption...',
                    placeholderStyle: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 15,
                    ),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),

                  // Bottom actions
                  Row(
                    children: [
                      // Gallery button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _pickFromGallery,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.photo,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Video button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _captureVideo,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.videocam,
                            color: Colors.white70,
                            size: 22,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Share to Story button
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(24),
                        onPressed: _isUploading ? null : _postStory,
                        child: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CupertinoActivityIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.arrow_up_circle_fill,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Share Story',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
