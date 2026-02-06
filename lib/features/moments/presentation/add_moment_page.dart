import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:moments/core/utils/extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/services/haptic_service.dart';
import '../../../widgets/spring_button.dart';
import '../../../widgets/video_player_widget.dart';
import '../providers/add_moment_notifier.dart';
import '../providers/add_moment_state.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddMomentPage extends ConsumerStatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? mediaPath; // Single media file (image or video)
  final List<String>? mediaPaths; // Multiple media files
  final bool isVideo; // Whether the media is video
  final int? videoDuration; // Video duration in seconds

  const AddMomentPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.mediaPath,
    this.mediaPaths,
    this.isVideo = false,
    this.videoDuration,
  });

  @override
  ConsumerState<AddMomentPage> createState() => _AddMomentPageState();
}

class _AddMomentPageState extends ConsumerState<AddMomentPage> {
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();

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
            imagePath: widget.mediaPath,
            imagePaths: widget.mediaPaths,
            isVideo: widget.isVideo,
            videoDuration: widget.videoDuration,
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
      HapticService.success();
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

    // Listen for group selection to update title
    ref.listen<AddMomentState>(addMomentProvider, (previous, next) {
      if (next.selectedGroupId != previous?.selectedGroupId) {
        if (next.selectedGroupId != null) {
          final group = next.nearbyGroups.firstWhere(
            (g) => g.id == next.selectedGroupId,
            orElse: () => next.nearbyGroups.first,
          );
          _titleController.text = group.title;
        }
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        leading: IconButton(
          onPressed: state.status == AddMomentStatus.loading
              ? null
              : () => Navigator.of(context).pop(),
          icon: SvgPicture.asset(
            'assets/icons/Left arrow.svg',
            width: 34,
            height: 34,
          ),
        ),
        title: Text(
          'NEW MOMENT',
          style: GoogleFonts.bebasNeue(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          if (state.status == AddMomentStatus.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: state.imageFiles.isEmpty
                    ? null
                    : _handleCreateMoment,
                child: Text(
                  'POST',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    color: state.imageFiles.isEmpty
                        ? AppTheme.textGray
                        : AppTheme.primaryBlue,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: state.imageFiles.isEmpty
          ? _buildEmptyState(state)
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Title Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: _titleController,
                      onChanged: (value) {
                        if (state.selectedGroupId != null) {
                          final group = state.nearbyGroups.firstWhere(
                            (g) => g.id == state.selectedGroupId,
                          );
                          if (group.title != value) {
                            ref
                                .read(addMomentProvider.notifier)
                                .selectGroup(null);
                          }
                        }
                      },
                      style: GoogleFonts.bebasNeue(
                        fontSize: 46,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: 1.5,
                        height: 1.0,
                      ),
                      decoration: InputDecoration(
                        hintText: 'GIVE IT A TITLE',
                        hintStyle: GoogleFonts.bebasNeue(
                          fontSize: 46,
                          fontWeight: FontWeight.w600,
                          color: Colors.black12,
                          letterSpacing: 1.5,
                          height: 1.0,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),

                  // Album Selection (Moved here)
                  if (state.nearbyGroups.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'OR ADD TO EXISTING GROUP:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: state.nearbyGroups.length,
                        itemBuilder: (context, index) {
                          final group = state.nearbyGroups[index];
                          final isSelected = group.id == state.selectedGroupId;
                          return Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(addMomentProvider.notifier)
                                  .selectGroup(group.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryBlue
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  group.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Location
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.locationDot,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        if (state.isGettingLocation)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1),
                          )
                        else
                          Text(
                            state.locationName?.toUpperCase() ?? 'LOCATING...',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Carousel
                  _buildCarousel(state),

                  const SizedBox(height: 32),

                  // Caption
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CAPTION',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              side: BorderSide(
                                color: AppTheme.borderGray,
                                width: 1,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: TextField(
                            controller: _captionController,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textDark,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'What\'s happening?',
                              hintStyle: TextStyle(color: AppTheme.textGray),
                              border: InputBorder.none,
                            ),
                            maxLines: 3,
                            minLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Visibility Toggle (Group-level privacy)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VISIBILITY',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticService.lightTap();
                                  ref
                                      .read(addMomentProvider.notifier)
                                      .setGroupPrivacy(false);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: !state.isGroupPrivate
                                        ? AppTheme.primaryBlue
                                        : Colors.white,
                                    shape: RoundedSuperellipseBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSmall,
                                      ),
                                      side: BorderSide(
                                        color: !state.isGroupPrivate
                                            ? AppTheme.primaryBlue
                                            : AppTheme.borderGray,
                                        width: 1,
                                      ),
                                    ),
                                    shadows: [
                                      BoxShadow(
                                        color: !state.isGroupPrivate
                                            ? AppTheme.primaryBlue.withOpacity(
                                                0.3,
                                              )
                                            : Colors.transparent,
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.users,
                                        size: 18,
                                        color: !state.isGroupPrivate
                                            ? Colors.white
                                            : Colors.black54,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Friends',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: !state.isGroupPrivate
                                              ? Colors.white
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticService.lightTap();
                                  ref
                                      .read(addMomentProvider.notifier)
                                      .setGroupPrivacy(true);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: ShapeDecoration(
                                    color: state.isGroupPrivate
                                        ? AppTheme.emergencyRed
                                        : Colors.white,
                                    shape: RoundedSuperellipseBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSmall,
                                      ),
                                      side: BorderSide(
                                        color: state.isGroupPrivate
                                            ? AppTheme.emergencyRed
                                            : AppTheme.borderGray,
                                        width: 1,
                                      ),
                                    ),
                                    shadows: [
                                      BoxShadow(
                                        color: state.isGroupPrivate
                                            ? AppTheme.emergencyRed.withOpacity(
                                                0.3,
                                              )
                                            : Colors.transparent,
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.lock,
                                        size: 18,
                                        color: state.isGroupPrivate
                                            ? Colors.white
                                            : Colors.black54,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Only Me',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: state.isGroupPrivate
                                              ? Colors.white
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Helper text
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            state.isGroupPrivate
                                ? 'Only you can see this moment. All photos are private.'
                                : 'Friends can see and contribute. Tap photos to make individual ones private.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black45,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const SizedBox(height: 48), // Bottom padding
                ],
              ),
            ),
    );
  }

  Widget _buildCarousel(AddMomentState state) {
    // Add +1 for the "Add Media" card
    final itemCount = state.imageFiles.length + 1;

    return CarouselSlider.builder(
      itemCount: itemCount,
      options: CarouselOptions(
        height: 400,
        viewportFraction: 0.75,
        enlargeCenterPage: true,
        enlargeFactor: 0.25,
        enableInfiniteScroll: false,
      ),
      itemBuilder: (context, index, realIndex) {
        // "Add Media" Card
        if (index == state.imageFiles.length) {
          return GestureDetector(
            onTap: () => ref.read(addMomentProvider.notifier).pickImages(),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  side: const BorderSide(color: Colors.black12, width: 2),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundBeige,
                        shape: BoxShape.circle,
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.userPlus,
                        size: 32,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ADD PHOTO',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Media Card (Image or Video)
        final file = state.imageFiles[index];
        // Check if this specific file is a video based on extension
        final filePath = file.path.toLowerCase();
        final isVideoFile =
            filePath.endsWith('.mp4') ||
            filePath.endsWith('.mov') ||
            filePath.endsWith('.avi') ||
            filePath.endsWith('.mkv') ||
            filePath.endsWith('.3gp');

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              side: const BorderSide(color: Colors.transparent, width: 0),
            ),
            shadows: AppTheme.brutalShadow, // Soft shadow from theme
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Show video player for video files
                if (isVideoFile)
                  VideoPlayerWidget(
                    videoUrl: file.path,
                    isLocalFile: true,
                    autoPlay: true,
                    looping: true,
                  )
                else
                  Image.file(File(file.path), fit: BoxFit.cover),
                // Delete Button
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(addMomentProvider.notifier).removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                // Privacy Toggle Button (bottom left)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: state.isGroupPrivate
                        ? null // Disabled when group is private
                        : () {
                            HapticService.lightTap();
                            ref
                                .read(addMomentProvider.notifier)
                                .togglePhotoPrivacy(index);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: state.isPhotoPrivate(index)
                            ? AppTheme.emergencyRed.withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: state.isPhotoPrivate(index)
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            state.isPhotoPrivate(index)
                                ? FontAwesomeIcons.lock
                                : FontAwesomeIcons.earthAmericas,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            state.isPhotoPrivate(index) ? 'Private' : 'Visible',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Index Indicator
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}/${state.imageFiles.length}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
  }

  Widget _buildEmptyState(AddMomentState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.brutalShadow,
            ),
            child: const Icon(
              Icons.add_a_photo_outlined,
              size: 48,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'CAPTURE THE MOMENT',
            style: GoogleFonts.bebasNeue(
              fontSize: 32,
              color: Colors.black,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your world with friends',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 48),
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
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  child: Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.camera,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CAMERA',
                        style: GoogleFonts.bebasNeue(
                          color: Colors.white,
                          fontSize: 20,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SpringButton(
                onTap: () => ref.read(addMomentProvider.notifier).pickImages(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brightYellow,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  child: Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.image,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GALLERY',
                        style: GoogleFonts.bebasNeue(
                          color: Colors.black,
                          fontSize: 20,
                          letterSpacing: 1.0,
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
}
