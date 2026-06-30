import 'package:freezed_annotation/freezed_annotation.dart';
import '_model_converters.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory UserProfile({
    required String id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? inviteCode,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime createdAt,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  String get displayNameOrUsername => displayName ?? username ?? 'Unknown User';

  @override
  String toString() =>
      'UserProfile(id: $id, displayName: $displayNameOrUsername, avatarUrl: $avatarUrl)';
}
