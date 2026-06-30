import 'package:freezed_annotation/freezed_annotation.dart';
import '_model_converters.dart';

part 'friendship.freezed.dart';
part 'friendship.g.dart';

@JsonEnum()
enum FriendshipStatus { pending, accepted, rejected, blocked }

@freezed
abstract class Friendship with _$Friendship {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Friendship({
    required String id,
    required String userId,
    required String friendId,
    @JsonKey(unknownEnumValue: FriendshipStatus.pending)
    required FriendshipStatus status,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime requestedAt,
    @JsonKey(
      fromJson: nullableLocalDateTimeFromJson,
      toJson: nullableDateTimeToJson,
    )
    DateTime? respondedAt,
  }) = _Friendship;

  factory Friendship.fromJson(Map<String, dynamic> json) =>
      _$FriendshipFromJson(json);
}
