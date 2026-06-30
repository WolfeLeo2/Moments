import 'package:freezed_annotation/freezed_annotation.dart';
import '_model_converters.dart';

part 'moment_image.freezed.dart';
part 'moment_image.g.dart';

@freezed
abstract class MomentImage with _$MomentImage {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MomentImage({
    required String id,
    required String momentId,
    String? imageUrl,
    required String mediaPath,
    String? caption,
    @Default(0) int displayOrder,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime createdAt,
  }) = _MomentImage;

  factory MomentImage.fromJson(Map<String, dynamic> json) =>
      _$MomentImageFromJson(json);
}
