import '../../../data/models/moment.dart';

/// Shared map grouping helpers for map pages and marker interactions.
class MapLogicService {
  /// Groups moments into viewport card groups.
  ///
  /// Grouping strategy:
  /// - Prefer stable `momentGroupId` when available.
  /// - Fallback to a place+rounded-coordinate key tuned by zoom level.
  static List<Map<String, dynamic>> groupMomentsByPlace(
    List<Moment> moments,
    double zoom,
  ) {
    if (moments.isEmpty) return const <Map<String, dynamic>>[];

    final grouped = <String, List<Moment>>{};

    for (final moment in moments) {
      final key = _groupKey(moment, zoom);
      grouped.putIfAbsent(key, () => <Moment>[]).add(moment);
    }

    final groups = grouped.entries
        .map((entry) {
          final groupMoments = List<Moment>.from(entry.value)
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          final first = groupMoments.first;
          final lat =
              groupMoments.map((m) => m.latitude).reduce((a, b) => a + b) /
              groupMoments.length;
          final lng =
              groupMoments.map((m) => m.longitude).reduce((a, b) => a + b) /
              groupMoments.length;

          return <String, dynamic>{
            'groupId': first.momentGroupId,
            'placeName': _placeName(first.location),
            'lat': lat,
            'lng': lng,
            'moments': groupMoments,
            'latestAt': groupMoments.first.timestamp,
          };
        })
        .toList(growable: false);

    groups.sort(
      (a, b) =>
          (b['latestAt'] as DateTime).compareTo(a['latestAt'] as DateTime),
    );

    return groups;
  }

  static String _groupKey(Moment moment, double zoom) {
    if (moment.momentGroupId.isNotEmpty) {
      return 'group:${moment.momentGroupId}';
    }

    final decimals = _decimalsForZoom(zoom);
    final lat = moment.latitude.toStringAsFixed(decimals);
    final lng = moment.longitude.toStringAsFixed(decimals);
    return 'place:${_placeName(moment.location).toLowerCase()}@$lat,$lng';
  }

  static int _decimalsForZoom(double zoom) {
    if (zoom >= 15) return 4;
    if (zoom >= 13) return 3;
    if (zoom >= 10) return 2;
    return 1;
  }

  static String _placeName(String location) {
    final trimmed = location.trim();
    if (trimmed.isEmpty) return 'Unknown';
    return trimmed.split(',').first.trim();
  }
}
