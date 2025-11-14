import 'package:equatable/equatable.dart';

/// Friendship status
enum FriendshipStatus {
  pending,
  accepted,
  rejected,
  blocked;

  static FriendshipStatus fromString(String value) {
    return FriendshipStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FriendshipStatus.pending,
    );
  }
}

/// Friendship connection between users
class Friendship extends Equatable {
  final String id;
  final String userId; // User who sent the request
  final String friendId; // User who received the request
  final FriendshipStatus status;
  final DateTime requestedAt;
  final DateTime? respondedAt;

  const Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.requestedAt,
    this.respondedAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      friendId: json['friend_id'] as String,
      status: FriendshipStatus.fromString(json['status'] as String),
      requestedAt: DateTime.parse(json['requested_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'status': status.name,
      'requested_at': requestedAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  Friendship copyWith({
    String? id,
    String? userId,
    String? friendId,
    FriendshipStatus? status,
    DateTime? requestedAt,
    DateTime? respondedAt,
  }) {
    return Friendship(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    friendId,
    status,
    requestedAt,
    respondedAt,
  ];
}
