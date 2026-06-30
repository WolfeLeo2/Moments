// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moment_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MomentComment _$MomentCommentFromJson(Map<String, dynamic> json) =>
    _MomentComment(
      id: json['id'] as String,
      momentId: json['moment_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$MomentCommentToJson(_MomentComment instance) =>
    <String, dynamic>{
      'moment_id': instance.momentId,
      'user_id': instance.userId,
      'content': instance.content,
    };
