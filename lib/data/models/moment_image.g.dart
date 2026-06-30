// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moment_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MomentImage _$MomentImageFromJson(Map<String, dynamic> json) => _MomentImage(
  id: json['id'] as String,
  momentId: json['moment_id'] as String,
  imageUrl: json['image_url'] as String?,
  mediaPath: json['media_path'] as String,
  caption: json['caption'] as String?,
  displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
  createdAt: localDateTimeFromJson(json['created_at'] as String),
);

Map<String, dynamic> _$MomentImageToJson(_MomentImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'moment_id': instance.momentId,
      'image_url': instance.imageUrl,
      'media_path': instance.mediaPath,
      'caption': instance.caption,
      'display_order': instance.displayOrder,
      'created_at': dateTimeToJson(instance.createdAt),
    };
