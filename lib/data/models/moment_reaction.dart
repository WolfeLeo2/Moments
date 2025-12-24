import 'package:equatable/equatable.dart';

/// Represents an emoji reaction on a moment
class MomentReaction extends Equatable {
  final String id;
  final String momentId;
  final String userId;
  final String emoji;
  final DateTime createdAt;

  const MomentReaction({
    required this.id,
    required this.momentId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  factory MomentReaction.fromJson(Map<String, dynamic> json) {
    return MomentReaction(
      id: json['id'] as String,
      momentId: json['moment_id'] as String,
      userId: json['user_id'] as String,
      emoji: json['emoji'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moment_id': momentId,
      'user_id': userId,
      'emoji': emoji,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MomentReaction copyWith({
    String? id,
    String? momentId,
    String? userId,
    String? emoji,
    DateTime? createdAt,
  }) {
    return MomentReaction(
      id: id ?? this.id,
      momentId: momentId ?? this.momentId,
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, momentId, userId, emoji, createdAt];
}

/// Aggregated reaction count for display
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
