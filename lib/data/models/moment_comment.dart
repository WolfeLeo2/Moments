import 'package:freezed_annotation/freezed_annotation.dart';

part 'moment_comment.freezed.dart';
part 'moment_comment.g.dart';

@freezed
abstract class MomentComment with _$MomentComment {
  /// toJson is the insert payload (moment_id, user_id, content only).
  /// Fields excluded from toJson carry @JsonKey(includeToJson: false).
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MomentComment({
    @JsonKey(includeToJson: false) required String id,
    required String momentId,
    required String userId,
    required String content,
    @JsonKey(includeToJson: false) required DateTime createdAt,
    @JsonKey(includeToJson: false) required DateTime updatedAt,
    @JsonKey(includeToJson: false) String? displayName,
    @JsonKey(includeToJson: false) String? avatarUrl,
  }) = _MomentComment;

  factory MomentComment.fromJson(Map<String, dynamic> json) =>
      _$MomentCommentFromJson(json);
}
