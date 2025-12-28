import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      inviteCode: json['invite_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'invite_code': inviteCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayNameOrUsername => displayName ?? username ?? 'Unknown User';

  @override
  List<Object?> get props => [
    id,
    username,
    displayName,
    avatarUrl,
    bio,
    inviteCode,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'UserProfile(id: $id, displayName: $displayNameOrUsername, avatarUrl: $avatarUrl)';
  }
}
