import 'package:equatable/equatable.dart';

/// Contributor role (simplified: owner or contributor, both can view)
enum ContributorRole {
  owner, // Created the group, can manage contributors
  contributor; // Invited and accepted, can add moments

  static ContributorRole fromString(String value) {
    return ContributorRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContributorRole.contributor,
    );
  }
}

/// Contributor to a shared moment
class MomentContributor extends Equatable {
  final String id;
  final String momentId;
  final String userId;
  final ContributorRole role;
  final DateTime invitedAt;
  final DateTime? acceptedAt;

  // Populated from join with profiles
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  // Populated for notifications
  final String? groupTitle;
  final String? inviterUsername;
  final String? inviterAvatarUrl;

  const MomentContributor({
    required this.id,
    required this.momentId,
    required this.userId,
    required this.role,
    required this.invitedAt,
    this.acceptedAt,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.groupTitle,
    this.inviterUsername,
    this.inviterAvatarUrl,
  });

  bool get hasAccepted => acceptedAt != null;
  bool get isPending => acceptedAt == null;
  bool get isOwner => role == ContributorRole.owner;

  factory MomentContributor.fromJson(Map<String, dynamic> json) {
    // Handle nested profile data if present
    final profile = json['profiles'] as Map<String, dynamic>?;
    final group = json['moment_groups'] as Map<String, dynamic>?;
    final inviter = json['inviter_profile'] as Map<String, dynamic>?;

    return MomentContributor(
      id: json['id'] as String,
      momentId: json['moment_id'] as String,
      userId: json['user_id'] as String,
      role: ContributorRole.fromString(
        json['role'] as String? ?? 'contributor',
      ),
      invitedAt: DateTime.parse(
        json['invited_at'] as String? ?? json['created_at'] as String,
      ).toLocal(),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String).toLocal()
          : null,
      username: profile?['username'] as String?,
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      groupTitle: group?['title'] as String?,
      inviterUsername: inviter?['username'] as String?,
      inviterAvatarUrl: inviter?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moment_id': momentId,
      'user_id': userId,
      'role': role.name,
      'invited_at': invitedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
    };
  }

  MomentContributor copyWith({
    String? id,
    String? momentId,
    String? userId,
    ContributorRole? role,
    DateTime? invitedAt,
    DateTime? acceptedAt,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? groupTitle,
    String? inviterUsername,
    String? inviterAvatarUrl,
  }) {
    return MomentContributor(
      id: id ?? this.id,
      momentId: momentId ?? this.momentId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      invitedAt: invitedAt ?? this.invitedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      groupTitle: groupTitle ?? this.groupTitle,
      inviterUsername: inviterUsername ?? this.inviterUsername,
      inviterAvatarUrl: inviterAvatarUrl ?? this.inviterAvatarUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    momentId,
    userId,
    role,
    invitedAt,
    acceptedAt,
    username,
    displayName,
    avatarUrl,
    groupTitle,
    inviterUsername,
    inviterAvatarUrl,
  ];
}
