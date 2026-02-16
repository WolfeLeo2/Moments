/// Data model for a moment comment.
class MomentComment {
  final String id;
  final String momentId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields (filled from profiles)
  final String? displayName;
  final String? avatarUrl;

  const MomentComment({
    required this.id,
    required this.momentId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.avatarUrl,
  });

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
