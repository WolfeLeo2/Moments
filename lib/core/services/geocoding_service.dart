import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moments/core/services/app_logger.dart';

final _log = AppLogger('GeocodingService');

/// Reverse geocoding using Mapbox's Geocoding API v5.
/// Replaces the `geocoding` package to avoid a redundant geocoding layer
/// since the app already uses Mapbox Maps GL.
class GeocodingService {
  // Same token used by the map
  static const _accessToken =
      'pk.eyJ1Ijoid29sZmVsZW8iLCJhIjoiY21oYXRxMW82MW5nNjJqcGc4aDA0YndoeSJ9.gvLhQFM-46KlcUdAKFGMYg';

  /// Call Mapbox Reverse Geocoding v5 and return the parsed features list.
  static Future<List<dynamic>> _reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/'
      '$longitude,$latitude.json'
      '?access_token=$_accessToken'
      '&types=place,locality,neighborhood,address'
      '&limit=1',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('Mapbox geocoding failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['features'] as List<dynamic>? ?? [];
  }

  /// Extract a specific place type from the feature context array.
  static String? _extractContext(
    Map<String, dynamic> feature,
    String placeType,
  ) {
    // Check the top-level feature first
    final types = (feature['place_type'] as List?)?.cast<String>() ?? [];
    if (types.contains(placeType)) {
      return feature['text'] as String?;
    }
    // Check the context array
    final context = feature['context'] as List?;
    if (context == null) return null;
    for (final ctx in context) {
      final id = (ctx as Map<String, dynamic>)['id'] as String? ?? '';
      if (id.startsWith(placeType)) {
        return ctx['text'] as String?;
      }
    }
    return null;
  }

  /// Get city name from coordinates.
  static Future<String> getCityFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final features = await _reverseGeocode(latitude, longitude);
      if (features.isEmpty) return 'Unknown Location';

      final feature = features.first as Map<String, dynamic>;

      // Try place types in preference order
      final place = _extractContext(feature, 'place');
      final locality = _extractContext(feature, 'locality');
      final neighborhood = _extractContext(feature, 'neighborhood');
      final region = _extractContext(feature, 'region');

      final cityName = neighborhood ?? locality ?? place ?? region;

      _log.d(
        'Mapbox geocoding: neighborhood=$neighborhood, '
        'locality=$locality, place=$place, region=$region',
      );

      if (cityName != null && cityName.isNotEmpty) return cityName;
      return 'Unknown Location';
    } catch (e) {
      _log.e('Error getting city name: $e');
      return 'Unknown Location';
    }
  }

  /// Get full location name from coordinates.
  static Future<String> getLocationName(
    double latitude,
    double longitude,
  ) async {
    try {
      final features = await _reverseGeocode(latitude, longitude);
      if (features.isEmpty) return 'Unknown Location';

      final feature = features.first as Map<String, dynamic>;

      final neighborhood = _extractContext(feature, 'neighborhood');
      final place = _extractContext(feature, 'place');
      final region = _extractContext(feature, 'region');

      final parts = <String>[
        if (neighborhood != null && neighborhood.isNotEmpty) neighborhood,
        if (place != null && place.isNotEmpty) place,
        if (region != null && region.isNotEmpty) region,
      ];

      return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
    } catch (e) {
      _log.e('Error getting location name: $e');
      return 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    }
  }
}
