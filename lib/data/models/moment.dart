import 'package:equatable/equatable.dart';

class Moment extends Equatable {
  final String id;
  final String title;
  final String location;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? mediaPath; // Storage path for the image
  final String? caption; // User's personal caption
  final DateTime createdAt;
  final DateTime timestamp;
  final String? userId;
  final String? description;

  const Moment({
    required this.id,
    required this.title,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.mediaPath,
    this.caption,
    required this.createdAt,
    required this.timestamp,
    this.userId,
    this.description,
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
      createdAt: DateTime.parse(json['created_at'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['user_id'] as String?,
      description: json['description'] as String?,
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
      'created_at': createdAt.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'description': description,
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
    DateTime? createdAt,
    DateTime? timestamp,
    String? userId,
    String? description,
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
      createdAt: createdAt ?? this.createdAt,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      description: description ?? this.description,
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
        createdAt,
        timestamp,
        userId,
        description,
      ];

  @override
  String toString() {
    return 'Moment(id: $id, title: $title, location: $location, lat: $latitude, lng: $longitude)';
  }
}
