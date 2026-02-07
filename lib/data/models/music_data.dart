import 'package:equatable/equatable.dart';

/// Type of music attached to a moment
enum MusicType {
  /// Track from Deezer's 30-second preview API
  deezer,

  /// Custom audio file from the curated-audio bucket
  curated,
}

/// Metadata for music attached to a moment.
///
/// For Deezer tracks, the [url] is the 30-second preview URL.
/// For curated tracks, [url] is the Supabase public storage URL.
///
/// Stored as JSONB in the `music_data` column on the moments table.
class MusicData extends Equatable {
  final MusicType type;
  final String? trackId; // Deezer track ID or curated filename
  final String url; // Preview URL (Deezer) or storage URL (curated)
  final String title;
  final String artist;
  final String? albumArt; // Cover image URL

  const MusicData({
    required this.type,
    this.trackId,
    required this.url,
    required this.title,
    required this.artist,
    this.albumArt,
  });

  factory MusicData.fromJson(Map<String, dynamic> json) {
    return MusicData(
      type: json['type'] == 'curated' ? MusicType.curated : MusicType.deezer,
      trackId: json['track_id'] as String?,
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown',
      artist: json['artist'] as String? ?? 'Unknown',
      albumArt: json['album_art'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type == MusicType.curated ? 'curated' : 'deezer',
      'track_id': trackId,
      'url': url,
      'title': title,
      'artist': artist,
      'album_art': albumArt,
    };
  }

  /// Preview duration is always 30s for Deezer, variable for curated
  int get previewDuration => type == MusicType.deezer ? 30 : 30;

  @override
  List<Object?> get props => [type, trackId, url, title, artist, albumArt];

  @override
  String toString() => 'MusicData($artist - $title)';
}
