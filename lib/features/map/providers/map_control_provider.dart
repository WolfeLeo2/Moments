import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Provider to control the map camera target from outside the MapPage.
/// When this value changes, the MapPage should animate to the new location.
final mapCameraTargetProvider =
    NotifierProvider<MapCameraTargetNotifier, LatLng?>(
      MapCameraTargetNotifier.new,
    );

class MapCameraTargetNotifier extends Notifier<LatLng?> {
  /// When true, the MapPage should skip the next auto-location update.
  /// This prevents the map from resetting to user location after notification navigation.
  bool skipNextLocationUpdate = false;

  @override
  LatLng? build() => null;

  /// Set target location and skip the next auto-location update.
  void setTarget(LatLng? target) {
    if (target != null) {
      skipNextLocationUpdate = true;
    }
    state = target;
  }

  /// Called by MapPage after checking the flag.
  void clearSkipFlag() {
    skipNextLocationUpdate = false;
  }
}
