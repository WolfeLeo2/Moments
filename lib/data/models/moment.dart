import 'package:equatable/equatable.dart';

class Moment extends Equatable {
  final String id;
  final String title;
  final String location;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? mediaPath; // Storage path for the media (image or video)
  final String? caption; // User's personal caption
  final String mediaType; // 'image' or 'video'
  final int? duration; // Duration in seconds for videos
  final String? thumbnailPath; // Thumbnail for videos
  final DateTime createdAt;
  final DateTime timestamp;
  final String? userId;
  final String? description;
  final String? momentGroupId; // Reference to moment group
  final bool isLocked; // Prevents auto-contributions from friends
  final bool isPrivate; // Completely private, only visible to owner

  const Moment({
    required this.id,
    required this.title,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.mediaPath,
    this.caption,
    this.mediaType = 'image',
    this.duration,
    this.thumbnailPath,
    required this.createdAt,
    required this.timestamp,
    this.userId,
    this.description,
    this.momentGroupId,
    this.isLocked = false,
    this.isPrivate = false,
  });

  factory Moment.fromJson(Map<String, dynamic> json) {
    return Moment(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      location: json['location'] as String? ?? 'Unknown',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      mediaPath: json['media_path'] as String?,
      caption: json['caption'] as String?,
      mediaType: json['media_type'] as String? ?? 'image',
      duration: json['duration'] as int?,
      thumbnailPath: json['thumbnail_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      userId: json['user_id'] as String?,
      description: json['description'] as String?,
      momentGroupId: json['moment_group_id'] as String?,
      isLocked: json['is_locked'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'media_path': mediaPath,
      'caption': caption,
      'media_type': mediaType,
      'duration': duration,
      'thumbnail_path': thumbnailPath,
      'created_at': createdAt.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'description': description,
      'moment_group_id': momentGroupId,
      'is_locked': isLocked,
      'is_private': isPrivate,
    };
  }

  Map<String, dynamic> toInsertJson() {
    final json = toJson();
    json.remove('id'); // Let Supabase generate the ID
    return json;
  }

  Moment copyWith({
    String? id,
    String? title,
    String? location,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? mediaPath,
    String? caption,
    String? mediaType,
    int? duration,
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? timestamp,
    String? userId,
    String? description,
    String? momentGroupId,
    bool? isLocked,
    bool? isPrivate,
  }) {
    return Moment(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      mediaPath: mediaPath ?? this.mediaPath,
      caption: caption ?? this.caption,
      mediaType: mediaType ?? this.mediaType,
      duration: duration ?? this.duration,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      momentGroupId: momentGroupId ?? this.momentGroupId,
      isLocked: isLocked ?? this.isLocked,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    location,
    latitude,
    longitude,
    imageUrl,
    mediaPath,
    caption,
    mediaType,
    duration,
    thumbnailPath,
    createdAt,
    timestamp,
    userId,
    description,
    momentGroupId,
    isLocked,
    isPrivate,
  ];

  @override
  String toString() {
    return 'Moment(id: $id, title: $title, location: $location, lat: $latitude, lng: $longitude)';
  }
}
