import 'package:freezed_annotation/freezed_annotation.dart';

part 'moment_comment.freezed.dart';

/// toJson emits only the insert payload (3 fields), so we keep manual
/// fromJson/toJson rather than generating them.
@freezed
abstract class MomentComment with _$MomentComment {
  const MomentComment._();

  const factory MomentComment({
    required String id,
    required String momentId,
    required String userId,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? displayName,
    String? avatarUrl,
  }) = _MomentComment;

  factory MomentComment.fromJson(Map<String, dynamic> json) {
    return MomentComment(
      id: json['id'] as String,
      momentId: json['moment_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'moment_id': momentId,
    'user_id': userId,
    'content': content,
  };
}
