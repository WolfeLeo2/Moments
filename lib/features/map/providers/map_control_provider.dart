import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Provider to control the map camera target from outside the MapPage.
/// When this value changes, the MapPage should animate to the new location.
final mapCameraTargetProvider =
    NotifierProvider<MapCameraTargetNotifier, LatLng?>(
      MapCameraTargetNotifier.new,
    );

class MapCameraTargetNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  // ignore: use_setters_to_change_properties
  void setTarget(LatLng? target) {
    state = target;
  }
}
