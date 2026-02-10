import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_state_provider.g.dart';

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
  MapUiState build() => const MapUiState();

  void setCamera(MapCameraState camera) {
    state = state.copyWith(camera: camera);
  }

  void setSelectedGroupIndex(int index) {
    state = state.copyWith(selectedGroupIndex: index);
  }
}
