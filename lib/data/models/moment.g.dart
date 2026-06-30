// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Moment _$MomentFromJson(Map<String, dynamic> json) => _Moment(
  id: json['id'] as String,
  title: json['title'] as String? ?? 'Untitled',
  location: json['location'] as String? ?? 'Unknown',
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  imageUrl: json['image_url'] as String?,
  mediaPath: json['media_path'] as String?,
  caption: json['caption'] as String?,
  mediaType: json['media_type'] as String? ?? 'image',
  duration: (json['duration'] as num?)?.toInt(),
  thumbnailPath: json['thumbnail_path'] as String?,
  createdAt: localDateTimeFromJson(json['created_at'] as String),
  timestamp: localDateTimeFromJson(json['timestamp'] as String),
  userId: json['user_id'] as String?,
  description: json['description'] as String?,
  momentGroupId: json['moment_group_id'] as String,
  isPrivate: json['is_private'] == null
      ? false
      : boolFromJson(json['is_private']),
  audioPath: json['audio_path'] as String?,
  audioDuration: (json['audio_duration'] as num?)?.toInt(),
  musicData: const MusicDataConverter().fromJson(json['music_data']),
);

Map<String, dynamic> _$MomentToJson(_Moment instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'location': instance.location,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'image_url': instance.imageUrl,
  'media_path': instance.mediaPath,
  'caption': instance.caption,
  'media_type': instance.mediaType,
  'duration': instance.duration,
  'thumbnail_path': instance.thumbnailPath,
  'created_at': dateTimeToJson(instance.createdAt),
  'timestamp': dateTimeToJson(instance.timestamp),
  'user_id': instance.userId,
  'description': instance.description,
  'moment_group_id': instance.momentGroupId,
  'is_private': boolToJson(instance.isPrivate),
  'audio_path': instance.audioPath,
  'audio_duration': instance.audioDuration,
  'music_data': const MusicDataConverter().toJson(instance.musicData),
};
