import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/constants.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../data/repositories/moment_repository.dart';
import 'add_moment_state.dart';

final addMomentProvider =
    StateNotifierProvider.autoDispose<AddMomentNotifier, AddMomentState>((ref) {
      return AddMomentNotifier(MomentRepository());
    });

class AddMomentNotifier extends StateNotifier<AddMomentState> {
  final MomentRepository _momentRepository;
  final ImagePicker _picker = ImagePicker();

  AddMomentNotifier(this._momentRepository) : super(const AddMomentState());

  void initialize({
    double? initialLatitude,
    double? initialLongitude,
    String? imagePath,
    List<String>? imagePaths,
  }) {
    List<File> initialImages = [];
    if (imagePaths != null && imagePaths.isNotEmpty) {
      initialImages.addAll(imagePaths.map((path) => File(path)));
    } else if (imagePath != null) {
      initialImages.add(File(imagePath));
    }

    state = state.copyWith(
      imageFiles: initialImages,
      latitude: initialLatitude,
      longitude: initialLongitude,
    );

    // If no location provided, fetch it
    if (initialLatitude == null || initialLongitude == null) {
      getCurrentLocation();
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
    } catch (e) {
      state = state.copyWith(
        isGettingLocation: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
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
        imageQuality: 85,
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

  Future<bool> createMoment({
    required String title,
    required String caption,
  }) async {
    if (state.imageFiles.isEmpty) {
      state = state.copyWith(errorMessage: 'Please select at least one image');
      return false;
    }

    if (state.latitude == null || state.longitude == null) {
      state = state.copyWith(errorMessage: 'Location is required');
      return false;
    }

    state = state.copyWith(status: AddMomentStatus.loading, errorMessage: null);

    try {
      // Create moment with first image
      final moment = await _momentRepository.createMoment(
        title: title.isEmpty ? 'SUNSET COVE' : title,
        location: state.locationName ?? 'Unknown Location',
        latitude: state.latitude!,
        longitude: state.longitude!,
        imageFile: state.imageFiles.first,
        caption: caption.isNotEmpty ? caption : null,
        description: caption.isNotEmpty ? caption : null,
      );

      // Upload additional images if more than one
      if (state.imageFiles.length > 1) {
        final additionalImages = state.imageFiles.sublist(1);
        await _momentRepository.uploadMomentImages(
          momentId: moment.id,
          imageFiles: additionalImages,
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
