import 'package:moments/data/models/moment.dart';
import 'dart:math' as math;

class MapLogicService {
  /// Group moments by place or location proximity
  static List<Map<String, dynamic>> groupMomentsByPlace(
    List<Moment> moments,
    double currentZoom,
  ) {
    final groups = <Map<String, dynamic>>[];

    // First, group by moment_group_id for moments that have one
    final groupedMoments = <String, List<Moment>>{};
    final ungroupedMoments = <Moment>[];

    for (final moment in moments) {
      if (moment.momentGroupId != null) {
        if (groupedMoments.containsKey(moment.momentGroupId)) {
          groupedMoments[moment.momentGroupId]!.add(moment);
        } else {
          groupedMoments[moment.momentGroupId!] = [moment];
        }
      } else {
        ungroupedMoments.add(moment);
      }
    }

    // Add grouped moments
    for (final entry in groupedMoments.entries) {
      final groupMoments = entry.value;
      final firstMoment = groupMoments.first;
      final placeName = _extractPlaceName(firstMoment.location);

      groups.add({
        'placeName': placeName,
        'moments': groupMoments,
        'lat': firstMoment.latitude,
        'lng': firstMoment.longitude,
        'groupId': entry.key,
        'isCluster': false,
        'clusterCount': 1,
      });
    }

    // Add ungrouped moments - each as its own marker, but group by location for nearby ones
    final locationGroups = <String, List<Moment>>{};
    for (final moment in ungroupedMoments) {
      final locationKey =
          '${moment.latitude.toStringAsFixed(4)}_${moment.longitude.toStringAsFixed(4)}';
      if (locationGroups.containsKey(locationKey)) {
        locationGroups[locationKey]!.add(moment);
      } else {
        locationGroups[locationKey] = [moment];
      }
    }

    for (final entry in locationGroups.entries) {
      final locationMoments = entry.value;
      final firstMoment = locationMoments.first;
      final placeName = _extractPlaceName(firstMoment.location);

      groups.add({
        'placeName': placeName,
        'moments': locationMoments,
        'lat': firstMoment.latitude,
        'lng': firstMoment.longitude,
        'groupId': 'loc_${entry.key}',
        'isCluster': false,
        'clusterCount': 1,
      });
    }

    // Apply zoom-aware clustering
    return _applyZoomClustering(groups, currentZoom);
  }

  static String _extractPlaceName(String location) {
    return location.split(',').first.trim();
  }

  static List<Map<String, dynamic>> _applyZoomClustering(
    List<Map<String, dynamic>> groups,
    double zoom,
  ) {
    if (groups.length <= 1) return groups;

    final double clusterThreshold = getClusterThreshold(zoom);

    // If threshold is 0 (high zoom), we don't cluster into a single point.
    // Instead, we apply a "Spiderfy" effect to separate overlapping markers.
    if (clusterThreshold <= 0) {
      // Check if we have a massive cluster (e.g. > 9 items)
      // If so, we group them into a "Stacked Cluster" (Pill) to avoid UI chaos
      return _applyPillClustering(groups, zoom);
    }

    final clustered = <Map<String, dynamic>>[];
    final processed = <int>{};

    for (int i = 0; i < groups.length; i++) {
      if (processed.contains(i)) continue;

      final baseLat = groups[i]['lat'] as double;
      final baseLng = groups[i]['lng'] as double;
      final clusterMembers = <Map<String, dynamic>>[groups[i]];
      processed.add(i);

      for (int j = i + 1; j < groups.length; j++) {
        if (processed.contains(j)) continue;

        final otherLat = groups[j]['lat'] as double;
        final otherLng = groups[j]['lng'] as double;

        final latDiff = (baseLat - otherLat).abs();
        final lngDiff = (baseLng - otherLng).abs();

        if (latDiff < clusterThreshold && lngDiff < clusterThreshold) {
          clusterMembers.add(groups[j]);
          processed.add(j);
        }
      }

      if (clusterMembers.length > 1) {
        final allMoments = <Moment>[];
        double totalLat = 0, totalLng = 0;

        for (final member in clusterMembers) {
          allMoments.addAll(member['moments'] as List<Moment>);
          totalLat += member['lat'] as double;
          totalLng += member['lng'] as double;
        }

        final centerLat = totalLat / clusterMembers.length;
        final centerLng = totalLng / clusterMembers.length;

        clustered.add({
          'placeName': '${clusterMembers.length} locations',
          'moments': allMoments,
          'lat': centerLat,
          'lng': centerLng,
          'groupId':
              'cluster_${clusterMembers.map((m) => m['groupId']).join('_')}',
          'isCluster': true,
          'clusterCount': clusterMembers.length,
        });
      } else {
        clustered.add(groups[i]);
      }
    }

    return clustered;
  }

  static double getClusterThreshold(double zoom) {
    if (zoom >= 16) return 0;
    if (zoom >= 14) return 0.002;
    if (zoom >= 12) return 0.005;
    if (zoom >= 10) return 0.02;
    if (zoom >= 8) return 0.1;
    if (zoom >= 6) return 0.5;
    if (zoom >= 4) return 2.0;
    return 5.0;
  }

  /// Applies a "Pill" clustering effect for high density
  /// All overlapping items are spiderfied (spiraled) so each can be individually tapped
  static List<Map<String, dynamic>> _applyPillClustering(
    List<Map<String, dynamic>> groups,
    double zoom,
  ) {
    if (groups.length <= 1) return groups;

    // Threshold for considering points "overlapping"
    const double overlapThreshold = 0.0005;

    final processed = <int>{};
    final result = <Map<String, dynamic>>[];

    for (int i = 0; i < groups.length; i++) {
      if (processed.contains(i)) continue;

      final baseLat = groups[i]['lat'] as double;
      final baseLng = groups[i]['lng'] as double;

      // Find all markers close to this one
      final nearbyIndices = <int>[i];
      for (int j = i + 1; j < groups.length; j++) {
        if (processed.contains(j)) continue;

        final otherLat = groups[j]['lat'] as double;
        final otherLng = groups[j]['lng'] as double;

        final latDiff = (baseLat - otherLat).abs();
        final lngDiff = (baseLng - otherLng).abs();

        if (latDiff < overlapThreshold && lngDiff < overlapThreshold) {
          nearbyIndices.add(j);
        }
      }

      // SPIDERFY (Spiral) ALL overlapping markers so each can be individually tapped
      final count = nearbyIndices.length;

      if (count == 1) {
        processed.add(i);
        result.add(groups[i]);
        continue;
      }

      // Calculate offsets - spread markers in a circle/spiral
      double degreeOffset = 0.0003 * math.sqrt(count); // Scale with count
      final zoomDiff = zoom - 16.0;
      if (zoomDiff > 0) {
        degreeOffset = degreeOffset / math.pow(2, zoomDiff);
      }

      final angleStep = (2 * math.pi) / count;

      for (int k = 0; k < count; k++) {
        final idx = nearbyIndices[k];
        processed.add(idx);

        final angle = k * angleStep;

        // Create a copy with modified coordinates
        final original = groups[idx];
        result.add({
          ...original,
          'lat': baseLat + (degreeOffset * math.sin(angle)),
          'lng': baseLng + (degreeOffset * math.cos(angle)),
        });
      }
    }

    return result;
  }

  /*
  static List<Map<String, dynamic>> _applySpiderfyEffect(
    List<Map<String, dynamic>> groups,
    double zoom,
  ) {
    if (groups.length <= 1) return groups;

    // Threshold for considering points "overlapping"
    // At zoom 16+, we want to separate anything that is visually on top of each other.
    // 0.0005 degrees is roughly 55 meters.
    const double overlapThreshold = 0.0005;

    final processed = <int>{};

    for (int i = 0; i < groups.length; i++) {
      if (processed.contains(i)) continue;

      final baseLat = groups[i]['lat'] as double;
      final baseLng = groups[i]['lng'] as double;

      // Find all markers close to this one
      final nearbyIndices = <int>[i];
      for (int j = i + 1; j < groups.length; j++) {
        if (processed.contains(j)) continue;

        final otherLat = groups[j]['lat'] as double;
        final otherLng = groups[j]['lng'] as double;

        final latDiff = (baseLat - otherLat).abs();
        final lngDiff = (baseLng - otherLng).abs();

        if (latDiff < overlapThreshold && lngDiff < overlapThreshold) {
          nearbyIndices.add(j);
        }
      }

      if (nearbyIndices.length > 1) {
        // If we have A LOT of items (e.g. > 9), spiderfy might look messy.
        // In that case, we should probably group them into a "Stacked Cluster"
        // which opens a list when tapped.
        if (nearbyIndices.length > 9) {
           // Create a single cluster item for these
           final clusterMembers = nearbyIndices.map((idx) => groups[idx]).toList();
           final allMoments = <Moment>[];
           for (final member in clusterMembers) {
             allMoments.addAll(member['moments'] as List<Moment>);
             processed.add(groups.indexOf(member));
           }
           
           // Add as a cluster
           // We use the base lat/lng
           // Note: We need to be careful not to modify the list while iterating
           // But here we are building a new list effectively via 'processed' set
           // Actually, we can't easily modify 'groups' in place to replace multiple items with one
           // without breaking the loop indices.
           // So, for now, we will just limit the spiderfy count or use a second ring.
        }

        // Distribute them in a circle
        final count = nearbyIndices.length;
        // Calculate radius based on zoom level to keep visual distance consistent
        // We want roughly 40-50 pixels of separation on screen
        // Formula: degrees = pixels * 360 / (256 * 2^zoom)
        // Using 0.0003 as a base for zoom 16, scaling down as we zoom in
        // Actually, as we zoom IN (higher zoom), degrees per pixel gets SMALLER.
        // So to keep constant pixel distance, degree offset must get SMALLER.
        
        // Base offset at zoom 16 (approx 30m)
        double degreeOffset = 0.0003; 
        
        // Adjust for current zoom:
        // If zoom is 18, we need 1/4th the degrees to cover the same screen pixels
        final zoomDiff = zoom - 16.0;
        if (zoomDiff > 0) {
          degreeOffset = degreeOffset / math.pow(2, zoomDiff);
        }

        // If too many items, might need a second ring or larger radius
        if (count > 8) degreeOffset *= 1.5;

        final angleStep = (2 * math.pi) / count;

        for (int k = 0; k < count; k++) {
          final idx = nearbyIndices[k];
          processed.add(idx);

          // Spiral effect for very large numbers (> 12)
          double currentAngle = k * angleStep;
          double currentOffset = degreeOffset;
          
          if (count > 12) {
             // Create a spiral
             // Angle increases, radius increases
             currentAngle = k * 0.5; // tighter angle steps
             currentOffset = degreeOffset + (k * 0.00005); 
          }

          final angle = currentAngle;
          
          // Apply circular offset
          // Note: Longitude needs correction for latitude (cos(lat)) but for small offsets it's negligible
          groups[idx]['lat'] = baseLat + (currentOffset * math.sin(angle));
          groups[idx]['lng'] = baseLng + (currentOffset * math.cos(angle));
        }
      } else {
        processed.add(i);
      }
    }

    return groups;
  }
  */
}
