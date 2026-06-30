// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  id: json['id'] as String,
  username: json['username'] as String?,
  displayName: json['display_name'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  bio: json['bio'] as String?,
  phoneNumber: json['phone_number'] as String?,
  inviteCode: json['invite_code'] as String? ?? '',
  createdAt: localDateTimeFromJson(json['created_at'] as String),
  updatedAt: localDateTimeFromJson(json['updated_at'] as String),
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'display_name': instance.displayName,
  'avatar_url': instance.avatarUrl,
  'bio': instance.bio,
  'phone_number': instance.phoneNumber,
  'invite_code': instance.inviteCode,
  'created_at': dateTimeToJson(instance.createdAt),
  'updated_at': dateTimeToJson(instance.updatedAt),
};
