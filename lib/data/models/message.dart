import 'package:freezed_annotation/freezed_annotation.dart';
import '_model_converters.dart';
import 'reaction.dart';

part 'message.freezed.dart';

enum MessageType {
  text,
  image,
  audio,
  video,
  file,
  gif,
  sticker;

  static MessageType fromString(String value) =>
      MessageType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => MessageType.text,
      );
}

enum MessageSendStatus {
  pending,
  sending,
  sent,
  delivered,
  read,
  failed;

  static MessageSendStatus fromString(String? value) {
    if (value == null) return MessageSendStatus.sent;
    return MessageSendStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageSendStatus.sent,
    );
  }
}

@freezed
abstract class Message with _$Message {
  const Message._();

  const factory Message({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    required MessageType messageType,
    String? mediaUrl,
    String? localMediaPath,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isDeleted,
    @Default(false) bool isRead,
    String? replyToMessageId,
    Message? replyToMessage,
    @Default(false) bool isEdited,
    String? deletedFor,
    @Default([]) List<Reaction> reactions,
    @Default(MessageSendStatus.sent) MessageSendStatus sendStatus,
    @Default(false) bool localOnly,
    DateTime? deliveredAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) {
    const metaConverter = MetadataConverter();
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      messageType: MessageType.fromString(json['message_type'] as String),
      mediaUrl: json['media_url'] as String?,
      localMediaPath: json['local_media_path'] as String?,
      metadata: metaConverter.fromJson(json['metadata']),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      isDeleted: json['is_deleted'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      replyToMessageId: json['reply_to_message_id'] as String?,
      replyToMessage: json['reply_to_message'] != null
          ? Message.fromJson(json['reply_to_message'] as Map<String, dynamic>)
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
      deletedFor: json['deleted_for'] as String?,
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((e) => Reaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sendStatus: MessageSendStatus.fromString(json['send_status'] as String?),
      localOnly: json['local_only'] as bool? ?? false,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': content,
    'message_type': messageType.name,
    'media_url': mediaUrl,
    'local_media_path': localMediaPath,
    'metadata': metadata,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_deleted': isDeleted,
    'is_read': isRead,
    'reply_to_message_id': replyToMessageId,
    'is_edited': isEdited,
    'deleted_for': deletedFor,
    'send_status': sendStatus.name,
    'local_only': localOnly,
    'delivered_at': deliveredAt?.toIso8601String(),
  };
}
