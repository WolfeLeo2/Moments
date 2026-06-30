import 'package:freezed_annotation/freezed_annotation.dart';
import '_model_converters.dart';
import 'music_data.dart';

part 'moment.freezed.dart';
part 'moment.g.dart';

@freezed
abstract class Moment with _$Moment {
  const Moment._();

  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Moment({
    required String id,
    @Default('Untitled') String title,
    @Default('Unknown') String location,
    required double latitude,
    required double longitude,
    String? imageUrl,
    String? mediaPath,
    String? caption,
    @Default('image') String mediaType,
    int? duration,
    String? thumbnailPath,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime createdAt,
    @JsonKey(fromJson: localDateTimeFromJson, toJson: dateTimeToJson)
    required DateTime timestamp,
    String? userId,
    String? description,
    required String momentGroupId,
    @JsonKey(fromJson: boolFromJson, toJson: boolToJson) @Default(false)
    bool isPrivate,
    String? audioPath,
    int? audioDuration,
    @MusicDataConverter() MusicData? musicData,
    @JsonKey(includeFromJson: false, includeToJson: false) String? localMediaPath,
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? localThumbnailPath,
  }) = _Moment;

  factory Moment.fromJson(Map<String, dynamic> json) => _$MomentFromJson(json);

  Map<String, dynamic> toInsertJson() => toJson()..remove('id');

  @override
  String toString() =>
      'Moment(id: $id, title: $title, location: $location, lat: $latitude, lng: $longitude)';
}
