import 'dart:io';
import 'package:equatable/equatable.dart';

enum AddMomentStatus { initial, loading, success, error }

class AddMomentState extends Equatable {
  final AddMomentStatus status;
  final List<File> imageFiles;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? errorMessage;
  final bool isGettingLocation;

  const AddMomentState({
    this.status = AddMomentStatus.initial,
    this.imageFiles = const [],
    this.latitude,
    this.longitude,
    this.locationName,
    this.errorMessage,
    this.isGettingLocation = false,
  });

  AddMomentState copyWith({
    AddMomentStatus? status,
    List<File>? imageFiles,
    double? latitude,
    double? longitude,
    String? locationName,
    String? errorMessage,
    bool? isGettingLocation,
  }) {
    return AddMomentState(
      status: status ?? this.status,
      imageFiles: imageFiles ?? this.imageFiles,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      errorMessage: errorMessage, // Allow clearing error by passing null
      isGettingLocation: isGettingLocation ?? this.isGettingLocation,
    );
  }

  @override
  List<Object?> get props => [
    status,
    imageFiles,
    latitude,
    longitude,
    locationName,
    errorMessage,
    isGettingLocation,
  ];
}
