import 'package:freezed_annotation/freezed_annotation.dart';

part 'moment_contributor.freezed.dart';

enum ContributorRole {
  owner,
  contributor;

  static ContributorRole fromString(String value) =>
      ContributorRole.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ContributorRole.contributor,
      );
}

@freezed
abstract class MomentContributor with _$MomentContributor {
  const MomentContributor._();

  const factory MomentContributor({
    required String id,
    required String momentId,
    required String userId,
    required ContributorRole role,
    required DateTime invitedAt,
    DateTime? acceptedAt,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? groupTitle,
    String? inviterUsername,
    String? inviterAvatarUrl,
  }) = _MomentContributor;

  /// Flat row — used by PowerSync and simple Supabase queries.
  factory MomentContributor.fromJson(Map<String, dynamic> json) {
    // Also handles Supabase join responses where profiles/moment_groups
    // are nested objects (Supabase embeds them under their table alias).
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'moment_id': momentId,
    'user_id': userId,
    'role': role.name,
    'invited_at': invitedAt.toIso8601String(),
    'accepted_at': acceptedAt?.toIso8601String(),
  };

  bool get hasAccepted => acceptedAt != null;
  bool get isPending => acceptedAt == null;
  bool get isOwner => role == ContributorRole.owner;
}
