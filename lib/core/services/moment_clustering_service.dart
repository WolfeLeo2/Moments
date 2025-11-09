import 'dart:math';
import '../../data/models/moment.dart';
import '../../data/models/moment_group.dart';

class MomentClusteringService {
  /// Group moments by proximity (within radius meters)
  static List<MomentGroup> clusterMoments(
    List<Moment> moments, {
    double radiusMeters = 100,
  }) {
    final groups = <MomentGroup>[];
    final processed = <String>{};

    for (final moment in moments) {
      if (processed.contains(moment.id)) continue;

      // Find all moments within radius
      final nearbyMoments = <Moment>[moment];
      processed.add(moment.id);

      for (final other in moments) {
        if (processed.contains(other.id)) continue;

        final distance = _calculateDistance(
          moment.latitude,
          moment.longitude,
          other.latitude,
          other.longitude,
        );

        if (distance <= radiusMeters) {
          nearbyMoments.add(other);
          processed.add(other.id);
        }
      }

      // Create group
      final centerLat =
          nearbyMoments.map((m) => m.latitude).reduce((a, b) => a + b) /
          nearbyMoments.length;
      final centerLng =
          nearbyMoments.map((m) => m.longitude).reduce((a, b) => a + b) /
          nearbyMoments.length;

      groups.add(
        MomentGroup(
          id: 'group_${groups.length}',
          title: nearbyMoments.first.title,
          moments: nearbyMoments,
          centerLatitude: centerLat,
          centerLongitude: centerLng,
          createdAt: nearbyMoments
              .map((m) => m.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b),
          updatedAt: nearbyMoments
              .map((m) => m.createdAt)
              .reduce((a, b) => a.isAfter(b) ? a : b),
        ),
      );
    }

    return groups;
  }

  /// Calculate distance between two coordinates in meters (Haversine formula)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // Earth's radius in meters

    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a =
        sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }
}
