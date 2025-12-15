import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/constants.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../data/repositories/moment_repository.dart';
import 'add_moment_state.dart';

part 'add_moment_notifier.g.dart';

@riverpod
class AddMoment extends _$AddMoment {
  final ImagePicker _picker = ImagePicker();

  MomentRepository get _momentRepository => MomentRepository();

  @override
  AddMomentState build() => const AddMomentState();

  void initialize({
    double? initialLatitude,
    double? initialLongitude,
    String? imagePath,
    List<String>? imagePaths,
    bool isVideo = false,
    int? videoDuration,
  }) {
    List<File> initialImages = [];
    if (imagePaths != null && imagePaths.isNotEmpty) {
      initialImages.addAll(imagePaths.map((path) => File(path)));
    } else if (imagePath != null) {
      initialImages.add(File(imagePath));
    }

    state = state.copyWith(
      imageFiles: initialImages,
      isVideo: isVideo,
      videoDuration: videoDuration,
      latitude: initialLatitude,
      longitude: initialLongitude,
    );

    // If no location provided, fetch it
    if (initialLatitude == null || initialLongitude == null) {
      getCurrentLocation();
    } else {
      // If coordinates provided, still need to fetch the city name and groups
      _fetchCityName(initialLatitude, initialLongitude);
      _fetchNearbyGroups(initialLatitude, initialLongitude);
    }
  }

  Future<void> _fetchCityName(double lat, double lng) async {
    try {
      final cityName = await GeocodingService.getCityFromCoordinates(lat, lng);
      state = state.copyWith(locationName: cityName);
    } catch (e) {
      // Fail silently for name, user can still post with coords
      print('Error fetching city name: $e');
    }
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isGettingLocation: true, errorMessage: null);

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

      final cityName = await GeocodingService.getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: cityName,
        isGettingLocation: false,
      );

      _fetchNearbyGroups(position.latitude, position.longitude);
    } catch (e) {
      state = state.copyWith(
        isGettingLocation: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _fetchNearbyGroups(double lat, double lng) async {
    try {
      final groups = await _momentRepository.getNearbyGroups(lat, lng);
      state = state.copyWith(nearbyGroups: groups);
    } catch (e) {
      print('Error fetching nearby groups: $e');
    }
  }

  void selectGroup(String? groupId) {
    if (groupId == state.selectedGroupId) {
      // Deselect if already selected
      state = state.copyWith(selectedGroupId: null);
    } else {
      // Select new group
      state = state.copyWith(selectedGroupId: groupId);

      // Optional: Auto-fill title with group title
      // We can't easily update the text controller from here,
      // but the UI can listen to state changes.
    }
  }

  void togglePrivacy(bool isPrivate) {
    state = state.copyWith(isPrivate: isPrivate);
  }

  Future<void> pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70,
      );

      if (pickedFiles.isNotEmpty) {
        final newFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();
        state = state.copyWith(
          imageFiles: [...state.imageFiles, ...newFiles],
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to pick images: $e');
    }
  }

  Future<void> takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null) {
        state = state.copyWith(
          imageFiles: [...state.imageFiles, File(photo.path)],
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to take picture: $e');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < state.imageFiles.length) {
      final newFiles = List<File>.from(state.imageFiles)..removeAt(index);
      state = state.copyWith(imageFiles: newFiles);
    }
  }

  /// Update image paths after editing
  /// Used when images are edited with stickers/text and saved as new files
  void updateImagePaths(List<String> editedPaths) {
    // Create new file list, replacing originals with edited versions
    final newFiles = <File>[];
    int editedIndex = 0;

    for (final originalFile in state.imageFiles) {
      final originalPath = originalFile.path.toLowerCase();
      final isVideo = originalPath.endsWith('.mp4') ||
                      originalPath.endsWith('.mov') ||
                      originalPath.endsWith('.avi') ||
                      originalPath.endsWith('.mkv') ||
                      originalPath.endsWith('.3gp');
      
      if (isVideo) {
        // Videos are not edited, keep original
        newFiles.add(originalFile);
      } else if (editedIndex < editedPaths.length) {
        // Replace with edited version
        newFiles.add(File(editedPaths[editedIndex]));
        editedIndex++;
      } else {
        // Fallback to original
        newFiles.add(originalFile);
      }
    }
    
    state = state.copyWith(imageFiles: newFiles);
  }

  Future<bool> createMoment({
    required String title,
    required String caption,
  }) async {
    if (state.imageFiles.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please select at least one image or video',
      );
      return false;
    }

    if (state.latitude == null || state.longitude == null) {
      state = state.copyWith(errorMessage: 'Location is required');
      return false;
    }

    state = state.copyWith(status: AddMomentStatus.loading, errorMessage: null);

    try {
      // If single media (could be video or single image)
      if (state.imageFiles.length == 1) {
        await _momentRepository.createMoment(
          state.imageFiles.first,
          title,
          caption,
          state.locationName ?? 'Unknown Location',
          state.latitude!,
          state.longitude!,
          isPrivate: state.isPrivate,
          momentGroupId: state.selectedGroupId,
          isVideo: state.isVideo,
          videoDuration: state.videoDuration,
        );
      } else {
        // Multiple images - use batch
        await _momentRepository.createMomentsBatch(
          state.imageFiles,
          title,
          caption,
          state.locationName ?? 'Unknown Location',
          state.latitude!,
          state.longitude!,
          isPrivate: state.isPrivate,
          momentGroupId: state.selectedGroupId,
        );
      }

      state = state.copyWith(status: AddMomentStatus.success);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AddMomentStatus.error,
        errorMessage: 'Failed to create moment: $e',
      );
      return false;
    }
  }
}
