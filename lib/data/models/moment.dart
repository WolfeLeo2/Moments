import 'package:freezed_annotation/freezed_annotation.dart';
import '_model_converters.dart';
import 'music_data.dart';

part 'moment.freezed.dart';

@freezed
abstract class Moment with _$Moment {
  const Moment._();

  const factory Moment({
    required String id,
    required String title,
    required String location,
    required double latitude,
    required double longitude,
    String? imageUrl,
    String? mediaPath,
    String? caption,
    @Default('image') String mediaType,
    int? duration,
    String? thumbnailPath,
    required DateTime createdAt,
    required DateTime timestamp,
    String? userId,
    String? description,
    required String momentGroupId,
    @Default(false) bool isPrivate,
    String? audioPath,
    int? audioDuration,
    MusicData? musicData,
    /// Local cache path — not persisted to DB or sent in toJson.
    String? localMediaPath,
    /// Local cache path — not persisted to DB or sent in toJson.
    String? localThumbnailPath,
  }) = _Moment;

  factory Moment.fromJson(Map<String, dynamic> json) {
    const musicConverter = MusicDataConverter();
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
      momentGroupId: json['moment_group_id'] as String,
      isPrivate: json['is_private'] as bool? ?? false,
      audioPath: json['audio_path'] as String?,
      audioDuration: json['audio_duration'] as int?,
      musicData: musicConverter.fromJson(json['music_data']),
    );
  }

  Map<String, dynamic> toJson() => {
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
    'is_private': isPrivate,
    'audio_path': audioPath,
    'audio_duration': audioDuration,
    'music_data': musicData?.toJson(),
  };

  Map<String, dynamic> toInsertJson() {
    final json = toJson()..remove('id');
    return json;
  }

  @override
  String toString() =>
      'Moment(id: $id, title: $title, location: $location, lat: $latitude, lng: $longitude)';
}
