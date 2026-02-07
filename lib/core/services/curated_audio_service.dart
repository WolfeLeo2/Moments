import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moments/core/services/app_logger.dart';
import 'package:moments/data/models/music_data.dart';

final _log = AppLogger('CuratedAudioService');

/// Service for listing and retrieving curated audio tracks
/// from the public `curated-audio` Supabase storage bucket.
///
/// Upload curated tracks via Supabase dashboard or admin tools.
/// Expected file naming: `artist - title.mp3`
class CuratedAudioService {
  static const _bucket = 'curated-audio';

  /// List all curated audio tracks in the bucket.
  /// Returns [MusicData] items with public URLs.
  static Future<List<MusicData>> listTracks() async {
    try {
      final files = await Supabase.instance.client.storage.from(_bucket).list();

      final tracks = <MusicData>[];

      for (final file in files) {
        if (!file.name.endsWith('.mp3') && !file.name.endsWith('.m4a')) {
          continue;
        }

        // Parse "artist - title.mp3" format
        final nameWithoutExt = file.name.replaceAll(
          RegExp(r'\.(mp3|m4a)$'),
          '',
        );
        String artist = 'Unknown';
        String title = nameWithoutExt;

        if (nameWithoutExt.contains(' - ')) {
          final parts = nameWithoutExt.split(' - ');
          artist = parts[0].trim();
          title = parts.sublist(1).join(' - ').trim();
        }

        final publicUrl = Supabase.instance.client.storage
            .from(_bucket)
            .getPublicUrl(file.name);

        tracks.add(
          MusicData(
            type: MusicType.curated,
            trackId: file.name,
            url: publicUrl,
            title: title,
            artist: artist,
            albumArt: null, // Curated tracks don't have album art by default
          ),
        );
      }

      return tracks;
    } catch (e) {
      _log.e('Failed to list curated tracks: $e');
      return [];
    }
  }
}
