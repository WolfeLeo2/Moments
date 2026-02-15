import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'map_state_provider.g.dart';

const _kLastMapLat = 'last_map_lat';
const _kLastMapLng = 'last_map_lng';
const _kLastMapZoom = 'last_map_zoom';

class MapCameraState {
  final double latitude;
  final double longitude;
  final double zoom;
  final double bearing;
  final double pitch;

  const MapCameraState({
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.bearing,
    required this.pitch,
  });
}

class MapUiState {
  final MapCameraState? camera;
  final int selectedGroupIndex;

  const MapUiState({this.camera, this.selectedGroupIndex = 0});

  MapUiState copyWith({MapCameraState? camera, int? selectedGroupIndex}) {
    return MapUiState(
      camera: camera ?? this.camera,
      selectedGroupIndex: selectedGroupIndex ?? this.selectedGroupIndex,
    );
  }
}

@Riverpod(keepAlive: true)
class MapUiStateNotifier extends _$MapUiStateNotifier {
  @override
  MapUiState build() {
    // Fire-and-forget: load cached camera from disk.
    _loadCachedCamera();
    return const MapUiState();
  }

  Future<void> _loadCachedCamera() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_kLastMapLat);
      final lng = prefs.getDouble(_kLastMapLng);
      final zoom = prefs.getDouble(_kLastMapZoom);
      if (lat != null && lng != null && state.camera == null) {
        state = state.copyWith(
          camera: MapCameraState(
            latitude: lat,
            longitude: lng,
            zoom: zoom ?? 14.0,
            bearing: 0,
            pitch: 0,
          ),
        );
      }
    } catch (_) {}
  }

  void setCamera(MapCameraState camera) {
    state = state.copyWith(camera: camera);
    _persistCamera(camera);
  }

  Future<void> _persistCamera(MapCameraState camera) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kLastMapLat, camera.latitude);
      await prefs.setDouble(_kLastMapLng, camera.longitude);
      await prefs.setDouble(_kLastMapZoom, camera.zoom);
    } catch (_) {}
  }

  void setSelectedGroupIndex(int index) {
    state = state.copyWith(selectedGroupIndex: index);
  }
}
