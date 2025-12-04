import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../data/models/moment_group.dart';

enum AddMomentStatus { initial, loading, success, error }

class AddMomentState extends Equatable {
  final AddMomentStatus status;
  final List<File> imageFiles; // Now also includes video files
  final bool isVideo; // Whether this is a video moment
  final int? videoDuration; // Duration in seconds for videos
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? errorMessage;
  final bool isGettingLocation;
  final String caption;
  final bool isPrivate;
  final List<MomentGroup> nearbyGroups;
  final String? selectedGroupId;

  const AddMomentState({
    this.status = AddMomentStatus.initial,
    this.imageFiles = const [],
    this.isVideo = false,
    this.videoDuration,
    this.latitude,
    this.longitude,
    this.locationName,
    this.errorMessage,
    this.isGettingLocation = false,
    this.caption = '',
    this.isPrivate = false,
    this.nearbyGroups = const [],
    this.selectedGroupId,
  });

  AddMomentState copyWith({
    AddMomentStatus? status,
    List<File>? imageFiles,
    bool? isVideo,
    int? videoDuration,
    double? latitude,
    double? longitude,
    String? locationName,
    String? errorMessage,
    bool? isGettingLocation,
    String? caption,
    bool? isPrivate,
    List<MomentGroup>? nearbyGroups,
    String? selectedGroupId,
  }) {
    return AddMomentState(
      status: status ?? this.status,
      imageFiles: imageFiles ?? this.imageFiles,
      isVideo: isVideo ?? this.isVideo,
      videoDuration: videoDuration ?? this.videoDuration,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      errorMessage: errorMessage, // Allow clearing error by passing null
      isGettingLocation: isGettingLocation ?? this.isGettingLocation,
      caption: caption ?? this.caption,
      isPrivate: isPrivate ?? this.isPrivate,
      nearbyGroups: nearbyGroups ?? this.nearbyGroups,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    imageFiles,
    isVideo,
    videoDuration,
    latitude,
    longitude,
    locationName,
    errorMessage,
    isGettingLocation,
    caption,
    isPrivate,
    nearbyGroups,
    selectedGroupId,
  ];
}
