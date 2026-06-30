// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moment_reaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MomentReaction _$MomentReactionFromJson(Map<String, dynamic> json) =>
    _MomentReaction(
      id: json['id'] as String,
      momentId: json['moment_id'] as String,
      userId: json['user_id'] as String,
      emoji: json['emoji'] as String,
      createdAt: localDateTimeFromJson(json['created_at'] as String),
    );

Map<String, dynamic> _$MomentReactionToJson(_MomentReaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'moment_id': instance.momentId,
      'user_id': instance.userId,
      'emoji': instance.emoji,
      'created_at': dateTimeToJson(instance.createdAt),
    };
