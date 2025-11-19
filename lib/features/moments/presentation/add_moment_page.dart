import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../widgets/spring_button.dart';
import '../providers/add_moment_notifier.dart';
import '../providers/add_moment_state.dart';

class AddMomentPage extends ConsumerStatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? imagePath;
  final List<String>? imagePaths;

  const AddMomentPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.imagePath,
    this.imagePaths,
  });

  @override
  ConsumerState<AddMomentPage> createState() => _AddMomentPageState();
}

class _AddMomentPageState extends ConsumerState<AddMomentPage> {
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  final AuthService _authService = AuthService();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the notifier with passed arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(addMomentProvider.notifier)
          .initialize(
            initialLatitude: widget.initialLatitude,
            initialLongitude: widget.initialLongitude,
            imagePath: widget.imagePath,
            imagePaths: widget.imagePaths,
          );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _handleCreateMoment() async {
    final success = await ref
        .read(addMomentProvider.notifier)
        .createMoment(
          title: _titleController.text.trim(),
          caption: _captionController.text.trim(),
        );

    if (success && mounted) {
      context.showSuccessSnackBar(AppConstants.momentCreated);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addMomentProvider);

    // Listen for errors
    ref.listen<AddMomentState>(addMomentProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        context.showErrorSnackBar(next.errorMessage!);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        elevation: 0,
        leading: IconButton(
          onPressed: state.status == AddMomentStatus.loading
              ? null
              : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: TextField(
          controller: _titleController,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 1.5,
          ),
          decoration: const InputDecoration(
            hintText: 'Add a title ie SUNSET COVE',
            hintStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black38,
              letterSpacing: 1.5,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          maxLines: 1,
        ),
        centerTitle: false,
        actions: [
          if (_authService.currentUserPhotoUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                      image: DecorationImage(
                        image: NetworkImage(_authService.currentUserPhotoUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: state.imageFiles.isEmpty
          ? _buildEmptyState(state)
          : _buildImagePreview(state),
      bottomNavigationBar: _buildBottomBar(state),
    );
  }

  Widget _buildEmptyState(AddMomentState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_photo_alternate_outlined,
            size: 100,
            color: Colors.black26,
          ),
          const SizedBox(height: 24),
          const Text(
            'Add photos to create a moment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpringButton(
                onTap: () => ref.read(addMomentProvider.notifier).takePicture(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    border: Border.all(color: Colors.black, width: 2.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Camera',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SpringButton(
                onTap: () => ref.read(addMomentProvider.notifier).pickImages(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brightYellow,
                    border: Border.all(color: Colors.black, width: 2.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.photo_library, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        'Gallery',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(AddMomentState state) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: state.imageFiles.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                state.imageFiles[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(addMomentProvider.notifier)
                            .removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: TextField(
            controller: _captionController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            decoration: const InputDecoration(
              hintText: 'Add caption...',
              hintStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black38,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: 1,
          ),
        ),
        if (state.imageFiles.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                state.imageFiles.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentImageIndex ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentImageIndex
                        ? AppTheme.primaryBlue
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.black,
                      width: index == _currentImageIndex ? 1.5 : 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(AddMomentState state) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundBeige,
        border: const Border(top: BorderSide(color: Colors.black12, width: 1)),
      ),
      child: Row(
        children: [
          SpringButton(
            onTap: () {
              // TODO: Show emoji/sticker picker
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_emotions_outlined, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          if (state.isGettingLocation)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              ),
            )
          else if (state.locationName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(
                    state.locationName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          SpringButton(
            onTap: state.status == AddMomentStatus.loading
                ? null
                : _handleCreateMoment,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: state.status == AddMomentStatus.loading
                    ? Colors.grey
                    : AppTheme.primaryBlue,
                border: Border.all(color: Colors.black, width: 2.5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                state.status == AddMomentStatus.loading
                    ? 'Posting...'
                    : 'Preview',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
