import 'package:freezed_annotation/freezed_annotation.dart';
import '_model_converters.dart';

part 'moment_reaction.freezed.dart';
part 'moment_reaction.g.dart';

@freezed
abstract class MomentReaction with _$MomentReaction {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MomentReaction({
    required String id,
    required String momentId,
    required String userId,
    required String emoji,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime createdAt,
  }) = _MomentReaction;

  factory MomentReaction.fromJson(Map<String, dynamic> json) =>
      _$MomentReactionFromJson(json);
}

/// Aggregated reaction count for display — not a DB model, no serialization.
class ReactionSummary {
  final String emoji;
  final int count;
  final bool userReacted;

  const ReactionSummary({
    required this.emoji,
    required this.count,
    required this.userReacted,
  });
}
