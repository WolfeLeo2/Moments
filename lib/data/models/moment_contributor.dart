import 'package:equatable/equatable.dart';

/// Contributor role
enum ContributorRole {
  owner,
  contributor,
  viewer;

  static ContributorRole fromString(String value) {
    return ContributorRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContributorRole.viewer,
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

  const MomentContributor({
    required this.id,
    required this.momentId,
    required this.userId,
    required this.role,
    required this.invitedAt,
    this.acceptedAt,
  });

  bool get hasAccepted => acceptedAt != null;
  bool get isPending => acceptedAt == null;

  factory MomentContributor.fromJson(Map<String, dynamic> json) {
    return MomentContributor(
      id: json['id'] as String,
      momentId: json['moment_id'] as String,
      userId: json['user_id'] as String,
      role: ContributorRole.fromString(json['role'] as String),
      invitedAt: DateTime.parse(json['invited_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
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
  }) {
    return MomentContributor(
      id: id ?? this.id,
      momentId: momentId ?? this.momentId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      invitedAt: invitedAt ?? this.invitedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
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
  ];
}
