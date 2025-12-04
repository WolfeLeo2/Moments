import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Manages video controllers with a sliding window approach.
/// Prewarms controllers for current ± 1 indices to enable instant playback
/// while keeping memory and power usage low.
class VideoControllerManager {
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, bool> _initializing = {};
  final Set<String> _activeIds = {};

  /// Callback when a controller becomes ready (initialized)
  final void Function()? onControllerReady;

  VideoControllerManager({this.onControllerReady});

  /// Get or create a controller for the given moment.
  /// Returns null if still initializing.
  VideoPlayerController? getController(String momentId) {
    final controller = _controllers[momentId];
    if (controller != null && controller.value.isInitialized) {
      return controller;
    }
    return null;
  }

  /// Check if a controller is ready (initialized)
  bool isReady(String momentId) {
    final controller = _controllers[momentId];
    return controller != null && controller.value.isInitialized;
  }

  /// Check if a controller is currently initializing
  bool isInitializing(String momentId) {
    return _initializing[momentId] == true;
  }

  /// Prewarm controllers for the given moment IDs.
  /// Pass video info as a map: momentId -> {url: String, isLocal: bool}
  Future<void> prewarm({
    required List<String> momentIds,
    required Map<String, VideoInfo> videoInfoMap,
  }) async {
    // Mark these as active
    _activeIds.clear();
    _activeIds.addAll(momentIds);

    // Initialize controllers for active IDs
    for (final momentId in momentIds) {
      final info = videoInfoMap[momentId];
      if (info == null) continue;

      // Skip if already initialized or initializing
      if (_controllers.containsKey(momentId) || _initializing[momentId] == true) {
        continue;
      }

      _initializeController(momentId, info);
    }

    // Dispose controllers outside the active window
    final toDispose = _controllers.keys
        .where((id) => !_activeIds.contains(id))
        .toList();

    for (final id in toDispose) {
      await _disposeController(id);
    }
  }

  Future<void> _initializeController(String momentId, VideoInfo info) async {
    _initializing[momentId] = true;
    debugPrint('VideoControllerManager: prewarming controller for $momentId (isLocal=${info.isLocal})');

    try {
      final VideoPlayerController controller;

      if (info.isLocal) {
        controller = VideoPlayerController.file(File(info.url));
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(info.url));
      }

      await controller.initialize();
      controller.setLooping(false);

      if (_activeIds.contains(momentId)) {
        _controllers[momentId] = controller;
        debugPrint('VideoControllerManager: controller ready for $momentId');
        onControllerReady?.call();
      } else {
        // Window moved, dispose immediately
        debugPrint('VideoControllerManager: disposing prewarmed controller (window moved) for $momentId');
        await controller.dispose();
      }
    } catch (e) {
      debugPrint('VideoControllerManager: failed to initialize controller for $momentId: $e');
    } finally {
      _initializing.remove(momentId);
    }
  }

  Future<void> _disposeController(String momentId) async {
    final controller = _controllers.remove(momentId);
    if (controller != null) {
      debugPrint('VideoControllerManager: disposing controller for $momentId');
      await controller.dispose();
    }
  }

  /// Pause all controllers (useful when leaving the page)
  void pauseAll() {
    for (final controller in _controllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  /// Dispose all controllers. Call when leaving the page.
  Future<void> disposeAll() async {
    debugPrint('VideoControllerManager: disposing all controllers (${_controllers.length})');
    for (final controller in _controllers.values) {
      await controller.dispose();
    }
    _controllers.clear();
    _initializing.clear();
    _activeIds.clear();
  }
}

/// Info needed to initialize a video controller
class VideoInfo {
  final String url;
  final bool isLocal;

  const VideoInfo({required this.url, required this.isLocal});
}
