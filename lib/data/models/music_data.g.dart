// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MusicData _$MusicDataFromJson(Map<String, dynamic> json) => _MusicData(
  type: $enumDecode(_$MusicTypeEnumMap, json['type']),
  trackId: json['track_id'] as String?,
  url: json['url'] as String? ?? '',
  title: json['title'] as String? ?? 'Unknown',
  artist: json['artist'] as String? ?? 'Unknown',
  albumArt: json['album_art'] as String?,
);

Map<String, dynamic> _$MusicDataToJson(_MusicData instance) =>
    <String, dynamic>{
      'type': _$MusicTypeEnumMap[instance.type]!,
      'track_id': instance.trackId,
      'url': instance.url,
      'title': instance.title,
      'artist': instance.artist,
      'album_art': instance.albumArt,
    };

const _$MusicTypeEnumMap = {
  MusicType.deezer: 'deezer',
  MusicType.curated: 'curated',
};
