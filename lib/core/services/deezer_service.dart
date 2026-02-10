import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moments/core/services/app_logger.dart';
import 'package:moments/data/models/music_data.dart';

final _log = AppLogger('DeezerService');

/// Service for searching Deezer's public API and getting 30-second previews.
///
/// Uses the free Deezer search API — no auth required.
/// Only stores the preview URL (30s MP3) and metadata, never full tracks.
class DeezerService {
  static const _baseUrl = 'https://api.deezer.com';
  static const _searchLimit = 25;

  final http.Client _client;

  DeezerService({http.Client? client}) : _client = client ?? http.Client();

  /// Search for tracks by query string.
  /// Returns a list of [DeezerTrack] results.
  Future<List<DeezerTrack>> search(
    String query, {
    int limit = _searchLimit,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'q': query,
          'limit': limit.toString(),
          'order': 'RANKING',
        },
      );

      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        _log.e('Deezer search failed: ${response.statusCode}');
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];

      return data
          .map((item) => DeezerTrack.fromJson(item as Map<String, dynamic>))
          .where((track) => track.previewUrl.isNotEmpty)
          .toList();
    } catch (e) {
      _log.e('Deezer search error: $e');
      return [];
    }
  }

  /// Get chart/popular tracks (defaults to top tracks).
  Future<List<DeezerTrack>> getChart({int limit = _searchLimit}) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/chart/0/tracks',
      ).replace(queryParameters: {'limit': limit.toString()});

      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        _log.e('Deezer chart failed: ${response.statusCode}');
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];

      return data
          .map((item) => DeezerTrack.fromJson(item as Map<String, dynamic>))
          .where((track) => track.previewUrl.isNotEmpty)
          .toList();
    } catch (e) {
      _log.e('Deezer chart error: $e');
      return [];
    }
  }

  /// Get a fresh preview URL for a track by ID.
  /// Deezer preview URLs are time-limited signed URLs that expire.
  /// Call this before playback to get a valid URL.
  Future<String?> getPreviewUrl(String trackId) async {
    try {
      final uri = Uri.parse('$_baseUrl/track/$trackId');
      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        _log.e('Deezer track fetch failed: ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final preview = json['preview'] as String?;
      if (preview == null || preview.isEmpty) {
        _log.w('No preview URL for track $trackId');
        return null;
      }

      return preview;
    } catch (e) {
      _log.e('Deezer preview fetch error: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// A Deezer track result with preview URL.
class DeezerTrack {
  final String id;
  final String title;
  final String artistName;
  final String albumArt; // Cover URL (250x250)
  final String previewUrl; // 30-second MP3 preview
  final int durationSeconds; // Full track duration (not preview)

  const DeezerTrack({
    required this.id,
    required this.title,
    required this.artistName,
    required this.albumArt,
    required this.previewUrl,
    this.durationSeconds = 30,
  });

  factory DeezerTrack.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as Map<String, dynamic>? ?? {};
    final album = json['album'] as Map<String, dynamic>? ?? {};

    return DeezerTrack(
      id: (json['id'] ?? 0).toString(),
      title: json['title'] as String? ?? 'Unknown',
      artistName: artist['name'] as String? ?? 'Unknown',
      albumArt:
          album['cover_medium'] as String? ?? album['cover'] as String? ?? '',
      previewUrl: json['preview'] as String? ?? '',
      durationSeconds: json['duration'] as int? ?? 30,
    );
  }

  /// Convert to [MusicData] for storing on a moment.
  MusicData toMusicData() {
    return MusicData(
      type: MusicType.deezer,
      trackId: id,
      url: previewUrl,
      title: title,
      artist: artistName,
      albumArt: albumArt,
    );
  }
}
