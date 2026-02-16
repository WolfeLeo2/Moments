import 'dart:collection';
import 'dart:math' as math;

/// Manages a time-limited trail of location points for neon trail rendering.
/// Points older than [maxAge] are automatically pruned.
class TrailManager {
  /// Maximum time a point stays in the trail before being pruned.
  final Duration maxAge;

  /// Maximum number of points to keep (prevents unbounded memory).
  final int maxPoints;

  final List<TrailPoint> _points = [];

  TrailManager({
    this.maxAge = const Duration(minutes: 30),
    this.maxPoints = 500,
  });

  /// Unmodifiable view of all current trail points.
  UnmodifiableListView<TrailPoint> get points => UnmodifiableListView(_points);

  /// Whether there are enough points to draw a trail.
  bool get hasTrail => _points.length >= 2;

  /// Add a new point and prune old ones.
  void addPoint(double latitude, double longitude) {
    _points.add(
      TrailPoint(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
      ),
    );

    _pruneOldPoints();

    // Cap the total count
    if (_points.length > maxPoints) {
      _points.removeRange(0, _points.length - maxPoints);
    }
  }

  /// Remove points older than [maxAge].
  void _pruneOldPoints() {
    final cutoff = DateTime.now().subtract(maxAge);
    _points.removeWhere((p) => p.timestamp.isBefore(cutoff));
  }

  /// Returns trail points as a list of [lng, lat] pairs (GeoJSON order).
  List<List<double>> toCoordinates() {
    _pruneOldPoints();
    return _points.map((p) => [p.longitude, p.latitude]).toList();
  }

  /// Clear the entire trail.
  void clear() => _points.clear();

  /// Total path distance in meters (Haversine).
  double get totalDistanceMeters {
    if (_points.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < _points.length; i++) {
      total += _haversine(
        _points[i - 1].latitude,
        _points[i - 1].longitude,
        _points[i].latitude,
        _points[i].longitude,
      );
    }
    return total;
  }

  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * (math.pi / 180);
}

/// A single point in a movement trail.
class TrailPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const TrailPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  /// Age of this point relative to now.
  Duration get age => DateTime.now().difference(timestamp);

  /// Normalized opacity: 1.0 at creation, fading to 0.0 at [maxAge].
  double opacity({Duration maxAge = const Duration(minutes: 30)}) {
    final ratio = age.inMilliseconds / maxAge.inMilliseconds;
    return (1.0 - ratio).clamp(0.0, 1.0);
  }
}
