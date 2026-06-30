import 'package:freezed_annotation/freezed_annotation.dart';
import '_model_converters.dart';
import 'reaction.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@JsonEnum()
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

@JsonEnum()
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
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Message({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    @JsonKey(unknownEnumValue: MessageType.text) required MessageType messageType,
    String? mediaUrl,
    String? localMediaPath,
    @MetadataConverter() Map<String, dynamic>? metadata,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime createdAt,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime updatedAt,
    @JsonKey(fromJson: boolFromJson, toJson: boolToJson) @Default(false)
    bool isDeleted,
    @JsonKey(fromJson: boolFromJson, toJson: boolToJson) @Default(false)
    bool isRead,
    String? replyToMessageId,
    Message? replyToMessage,
    @JsonKey(fromJson: boolFromJson, toJson: boolToJson) @Default(false)
    bool isEdited,
    String? deletedFor,
    @Default([]) List<Reaction> reactions,
    @JsonKey(unknownEnumValue: MessageSendStatus.sent)
    @Default(MessageSendStatus.sent)
    MessageSendStatus sendStatus,
    @JsonKey(fromJson: boolFromJson, toJson: boolToJson) @Default(false)
    bool localOnly,
    @JsonKey(
      fromJson: nullableLocalDateTimeFromJson,
      toJson: nullableDateTimeToJson,
    )
    DateTime? deliveredAt,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}
