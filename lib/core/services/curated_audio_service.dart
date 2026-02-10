import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moments/core/services/app_logger.dart';
import 'package:moments/data/models/music_data.dart';

final _log = AppLogger('CuratedAudioService');

/// Service for searching and retrieving curated audio tracks
/// from the `curated_tracks` Postgres table.
///
/// Audio files live in the public `curated-audio` Supabase storage bucket.
/// Metadata (title, artist, genre, mood, tags) is in the curated_tracks table.
///
/// Manage tracks via the `manage-curated-tracks` edge function or the
/// `curated-tracks/` scripts in the project root.
class CuratedAudioService {
  static const _bucket = 'curated-audio';

  static SupabaseClient get _client => Supabase.instance.client;

  /// List all curated tracks (paginated).
  static Future<List<MusicData>> listTracks({
    int page = 0,
    int limit = 25,
  }) async {
    try {
      final response = await _client
          .from('curated_tracks')
          .select()
          .eq('is_active', true)
          .order('title')
          .range(page * limit, (page + 1) * limit - 1);

      return _parseRows(response as List);
    } catch (e) {
      _log.e('Failed to list curated tracks: $e');
      return [];
    }
  }

  /// Search curated tracks by query string (title, artist, genre, mood).
  static Future<List<MusicData>> search(
    String query, {
    String? genre,
    String? mood,
    int limit = 25,
  }) async {
    try {
      final response = await _client.rpc(
        'search_curated_tracks',
        params: {
          'p_query': query.isEmpty ? null : query,
          'p_genre': genre,
          'p_mood': mood,
          'p_limit': limit,
          'p_offset': 0,
        },
      );

      return _parseRows(response as List);
    } catch (e) {
      _log.e('Failed to search curated tracks: $e');
      return [];
    }
  }

  /// Get tracks filtered by mood.
  static Future<List<MusicData>> byMood(String mood, {int limit = 15}) async {
    return search('', mood: mood, limit: limit);
  }

  /// Get tracks filtered by genre.
  static Future<List<MusicData>> byGenre(String genre, {int limit = 15}) async {
    return search('', genre: genre, limit: limit);
  }

  /// Convert database rows to MusicData list.
  static List<MusicData> _parseRows(List rows) {
    return rows.map((row) {
      final storagePath = row['storage_path'] as String;
      final publicUrl = _client.storage.from(_bucket).getPublicUrl(storagePath);

      return MusicData(
        type: MusicType.curated,
        trackId: row['id'] as String?,
        url: publicUrl,
        title: row['title'] as String? ?? 'Unknown',
        artist: row['artist'] as String? ?? 'Unknown',
        albumArt: row['album_art'] as String?,
      );
    }).toList();
  }
}
