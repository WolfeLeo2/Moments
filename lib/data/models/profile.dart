import 'package:freezed_annotation/freezed_annotation.dart';
import '_model_converters.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
abstract class Profile with _$Profile {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Profile({
    required String id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? phoneNumber,
    @Default('') String inviteCode,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime createdAt,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
