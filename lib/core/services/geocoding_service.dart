import 'package:geocoding/geocoding.dart';

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

        // Debug: Print all available fields
        print('🗺️ Geocoding Debug:');
        print('  Locality: ${placemark.locality}');
        print('  SubLocality: ${placemark.subLocality}');
        print('  SubAdministrativeArea: ${placemark.subAdministrativeArea}');
        print('  AdministrativeArea: ${placemark.administrativeArea}');
        print('  Country: ${placemark.country}');
        print('  PostalCode: ${placemark.postalCode}');
        print('  Thoroughfare: ${placemark.thoroughfare}');

        // Try to get city name in order of preference
        // For Kenya, locality usually contains the town/area name
        String? cityName =
            placemark.locality ??
            placemark.subLocality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea;

        print('✅ Selected city name: $cityName');

        if (cityName != null && cityName.isNotEmpty) {
          return cityName;
        }

        return 'Unknown Location';
      }

      return 'Unknown Location';
    } catch (e) {
      print('❌ Error getting city name: $e');
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
      print('Error getting location name: $e');
      return 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    }
  }
}
