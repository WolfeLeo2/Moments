import 'package:moments/core/services/app_logger.dart';
import 'package:geocoding/geocoding.dart';

final _log = AppLogger('GeocodingService');

class GeocodingService {
  /// Get city name from coordinates
  static Future<String> getCityFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        // Debug: Log all available fields
        _log.d(
          'Geocoding result: locality=${placemark.locality}, '
          'subLocality=${placemark.subLocality}, '
          'subAdmin=${placemark.subAdministrativeArea}, '
          'admin=${placemark.administrativeArea}',
        );

        // Try to get city name in order of preference
        // For Kenya, locality usually contains the town/area name
        String? cityName =
            placemark.locality ??
            placemark.subLocality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea;

        _log.d('Selected city name: $cityName');

        if (cityName != null && cityName.isNotEmpty) {
          return cityName;
        }

        return 'Unknown Location';
      }

      return 'Unknown Location';
    } catch (e) {
      _log.e('Error getting city name: $e');
      return 'Unknown Location';
    }
  }

  /// Get full location name from coordinates
  static Future<String> getLocationName(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        // Build comprehensive location string
        final parts = <String>[];

        if (placemark.subLocality != null &&
            placemark.subLocality!.isNotEmpty) {
          parts.add(placemark.subLocality!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          parts.add(placemark.locality!);
        }
        if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          parts.add(placemark.administrativeArea!);
        }

        return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
      }

      return 'Unknown Location';
    } catch (e) {
      _log.e('Error getting location name: $e');
      return 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    }
  }
}
