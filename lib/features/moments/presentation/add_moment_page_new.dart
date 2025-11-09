import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../data/repositories/moment_repository.dart';
import '../../../widgets/spring_button.dart';

class AddMomentPageNew extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? imagePath;
  final List<String>? imagePaths; // For multiple images

  const AddMomentPageNew({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.imagePath,
    this.imagePaths,
  });

  @override
  State<AddMomentPageNew> createState() => _AddMomentPageNewState();
}

class _AddMomentPageNewState extends State<AddMomentPageNew> {
  final _titleController = TextEditingController(); // For "PLACE OF POWER" group title
  final _captionController = TextEditingController(); // For personal caption like "Midtown Manhattan"
  final MomentRepository _momentRepository = MomentRepository();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  List<File> _imageFiles = [];
  int _currentImageIndex = 0;
  double? _latitude;
  double? _longitude;
  String? _locationName;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    
    // Set images if provided (handle both single and multiple)
    if (widget.imagePaths != null && widget.imagePaths!.isNotEmpty) {
      print('📸 Adding multiple images: ${widget.imagePaths!.length}');
      _imageFiles.addAll(widget.imagePaths!.map((path) => File(path)));
    } else if (widget.imagePath != null) {
      print('📸 Adding single image: ${widget.imagePath}');
      _imageFiles.add(File(widget.imagePath!));
    } else {
      print('⚠️ No images provided to AddMomentPageNew');
    }
    
    print('🖼️ Total images loaded: ${_imageFiles.length}');
    
    // Set initial coordinates
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;

    // Get location automatically
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(AppConstants.locationServiceDisabled);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(AppConstants.locationPermissionDenied);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(AppConstants.locationPermissionDenied);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get city name using geocoding
      final cityName = await GeocodingService.getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationName = cityName;
      });
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.toString());
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );
      
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _imageFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();
          _currentImageIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to pick images: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _imageFiles.add(File(photo.path));
          _currentImageIndex = _imageFiles.length - 1;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to take picture: $e');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
      if (_currentImageIndex >= _imageFiles.length && _imageFiles.isNotEmpty) {
        _currentImageIndex = _imageFiles.length - 1;
      } else if (_imageFiles.isEmpty) {
        _currentImageIndex = 0;
      }
    });
  }

  Future<void> _createMoment() async {
    if (_imageFiles.isEmpty) {
      context.showErrorSnackBar('Please select at least one image');
      return;
    }

    if (_latitude == null || _longitude == null) {
      context.showErrorSnackBar('Location is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final caption = _captionController.text.trim();
      
      // Create moment with first image
      final moment = await _momentRepository.createMoment(
        title: title.isEmpty ? 'SUNSET COVE' : title, // Group title
        location: _locationName ?? 'Unknown Location',
        latitude: _latitude!,
        longitude: _longitude!,
        imageFile: _imageFiles.first,
        caption: caption.isNotEmpty ? caption : null, // Personal caption like "Midtown Manhattan"
        description: caption.isNotEmpty ? caption : null,
      );

      // Upload additional images if more than one
      if (_imageFiles.length > 1) {
        final additionalImages = _imageFiles.sublist(1);
        await _momentRepository.uploadMomentImages(
          momentId: moment.id,
          imageFiles: additionalImages,
        );
      }

      if (mounted) {
        context.showSuccessSnackBar(AppConstants.momentCreated);
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to create moment: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: TextField(
          controller: _titleController, // Changed to title controller for group name
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 1.5,
          ),
          decoration: const InputDecoration(
            hintText: 'Add a title ie SUNSET COVE', // User types their own title
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
          // Profile avatars of contributors
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
      body: _imageFiles.isEmpty ? _buildEmptyState() : _buildImagePreview(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildEmptyState() {
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
                onTap: _takePicture,
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
                onTap: _pickImages,
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

  Widget _buildImagePreview() {
    return Column(
      children: [
        // Image carousel with clean white containers
        Expanded(
          child: PageView.builder(
            itemCount: _imageFiles.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Stack(
                  children: [
                    // Clean white card with simple border
                    Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          maxWidth: 400,
                        ),
                        child: AspectRatio(
                          aspectRatio: 3 / 4, // Portrait card ratio
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
                                _imageFiles[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Simple X button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
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
        
        // Caption BELOW carousel (static - doesn't swipe with images)
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
        
        // Photo counter
        if (_imageFiles.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _imageFiles.length,
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

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundBeige,
        border: const Border(
          top: BorderSide(color: Colors.black12, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Emoji/Sticker button
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
          
          // Location tag
          if (_locationName != null)
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
                    _locationName!,
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
          
          // Preview button
          SpringButton(
            onTap: _isLoading ? null : _createMoment,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey : AppTheme.primaryBlue,
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
                _isLoading ? 'Posting...' : 'Preview',
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
