// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  id: json['id'] as String,
  conversationId: json['conversation_id'] as String,
  senderId: json['sender_id'] as String,
  content: json['content'] as String,
  messageType: $enumDecode(
    _$MessageTypeEnumMap,
    json['message_type'],
    unknownValue: MessageType.text,
  ),
  mediaUrl: json['media_url'] as String?,
  localMediaPath: json['local_media_path'] as String?,
  metadata: const MetadataConverter().fromJson(json['metadata']),
  createdAt: localDateTimeFromJson(json['created_at'] as String),
  updatedAt: localDateTimeFromJson(json['updated_at'] as String),
  isDeleted: json['is_deleted'] == null
      ? false
      : boolFromJson(json['is_deleted']),
  isRead: json['is_read'] == null ? false : boolFromJson(json['is_read']),
  replyToMessageId: json['reply_to_message_id'] as String?,
  replyToMessage: json['reply_to_message'] == null
      ? null
      : Message.fromJson(json['reply_to_message'] as Map<String, dynamic>),
  isEdited: json['is_edited'] == null ? false : boolFromJson(json['is_edited']),
  deletedFor: json['deleted_for'] as String?,
  reactions:
      (json['reactions'] as List<dynamic>?)
          ?.map((e) => Reaction.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  sendStatus:
      $enumDecodeNullable(
        _$MessageSendStatusEnumMap,
        json['send_status'],
        unknownValue: MessageSendStatus.sent,
      ) ??
      MessageSendStatus.sent,
  localOnly: json['local_only'] == null
      ? false
      : boolFromJson(json['local_only']),
  deliveredAt: nullableLocalDateTimeFromJson(json['delivered_at'] as String?),
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'id': instance.id,
  'conversation_id': instance.conversationId,
  'sender_id': instance.senderId,
  'content': instance.content,
  'message_type': _$MessageTypeEnumMap[instance.messageType]!,
  'media_url': instance.mediaUrl,
  'local_media_path': instance.localMediaPath,
  'metadata': const MetadataConverter().toJson(instance.metadata),
  'created_at': dateTimeToJson(instance.createdAt),
  'updated_at': dateTimeToJson(instance.updatedAt),
  'is_deleted': boolToJson(instance.isDeleted),
  'is_read': boolToJson(instance.isRead),
  'reply_to_message_id': instance.replyToMessageId,
  'reply_to_message': instance.replyToMessage?.toJson(),
  'is_edited': boolToJson(instance.isEdited),
  'deleted_for': instance.deletedFor,
  'reactions': instance.reactions.map((e) => e.toJson()).toList(),
  'send_status': _$MessageSendStatusEnumMap[instance.sendStatus]!,
  'local_only': boolToJson(instance.localOnly),
  'delivered_at': nullableDateTimeToJson(instance.deliveredAt),
};

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.audio: 'audio',
  MessageType.video: 'video',
  MessageType.file: 'file',
  MessageType.gif: 'gif',
  MessageType.sticker: 'sticker',
};

const _$MessageSendStatusEnumMap = {
  MessageSendStatus.pending: 'pending',
  MessageSendStatus.sending: 'sending',
  MessageSendStatus.sent: 'sent',
  MessageSendStatus.delivered: 'delivered',
  MessageSendStatus.read: 'read',
  MessageSendStatus.failed: 'failed',
};
