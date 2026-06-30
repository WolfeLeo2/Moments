import 'package:freezed_annotation/freezed_annotation.dart';
import '_model_converters.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
abstract class Conversation with _$Conversation {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Conversation({
    required String id,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime createdAt,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime updatedAt,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
