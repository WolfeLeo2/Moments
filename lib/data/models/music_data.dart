import 'package:freezed_annotation/freezed_annotation.dart';

part 'music_data.freezed.dart';
part 'music_data.g.dart';

@JsonEnum()
enum MusicType {
  @JsonValue('deezer')
  deezer,
  @JsonValue('curated')
  curated,
}

@freezed
abstract class MusicData with _$MusicData {
  const MusicData._();

  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MusicData({
    required MusicType type,
    String? trackId,
    @Default('') String url,
    @Default('Unknown') String title,
    @Default('Unknown') String artist,
    String? albumArt,
  }) = _MusicData;

  factory MusicData.fromJson(Map<String, dynamic> json) =>
      _$MusicDataFromJson(json);

  int get previewDuration => 30;

  @override
  String toString() => 'MusicData($artist - $title)';
}
