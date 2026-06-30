import 'package:freezed_annotation/freezed_annotation.dart';

part 'reaction.freezed.dart';
part 'reaction.g.dart';

@freezed
abstract class Reaction with _$Reaction {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Reaction({
    required String id,
    required String messageId,
    required String userId,
    required String emoji,
    required DateTime createdAt,
  }) = _Reaction;

  factory Reaction.fromJson(Map<String, dynamic> json) =>
      _$ReactionFromJson(json);
}
