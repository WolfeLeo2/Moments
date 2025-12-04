import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_player_widget.dart';

/// Widget that plays video from local file or network
/// Prefers local file if available for offline support.
/// Can use a prewarmed controller from VideoControllerManager for instant playback.
class OfflineVideo extends StatefulWidget {
  final String? localPath;
  final String? networkUrl;
  final bool autoPlay;
  final bool looping;
  final Widget? placeholder;
  final Widget? errorWidget;

  /// Optional prewarmed controller from VideoControllerManager.
  /// If provided and initialized, uses this instead of creating a new one.
  final VideoPlayerController? prewarmedController;

  const OfflineVideo({
    super.key,
    this.localPath,
    this.networkUrl,
    this.autoPlay = false,
    this.looping = false,
    this.placeholder,
    this.errorWidget,
    this.prewarmedController,
  });

  @override
  State<OfflineVideo> createState() => _OfflineVideoState();
}

class _OfflineVideoState extends State<OfflineVideo>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // If we have a prewarmed controller that's ready, use it directly
    if (widget.prewarmedController != null &&
        widget.prewarmedController!.value.isInitialized) {
      debugPrint('OfflineVideo: using prewarmed controller');
      return _buildVideoFromController(widget.prewarmedController!);
    }

    // Prefer local file if it exists
    if (widget.localPath != null) {
      final file = File(widget.localPath!);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return widget.placeholder ?? _buildDefaultPlaceholder();
          }

          if (snapshot.hasData && snapshot.data == true) {
            // Use local file
            debugPrint('OfflineVideo: using local file: ${file.path}');
            return VideoPlayerWidget(
              videoUrl: widget.localPath!,
              isLocalFile: true,
              autoPlay: widget.autoPlay,
              looping: widget.looping,
            );
          }

          // File doesn't exist, use network
          debugPrint(
            'OfflineVideo: local file not found, using network: ${widget.networkUrl}',
          );
          return _buildNetworkVideo();
        },
      );
    }

    // No local path, use network
    debugPrint(
      'OfflineVideo: no localPath provided, using network: ${widget.networkUrl}',
    );
    return _buildNetworkVideo();
  }

  Widget _buildVideoFromController(VideoPlayerController controller) {
    return _ManagedVideoPlayer(
      controller: controller,
      autoPlay: widget.autoPlay,
    );
  }

  Widget _buildNetworkVideo() {
    if (widget.networkUrl == null || widget.networkUrl!.isEmpty) {
      return widget.errorWidget ?? _buildDefaultError();
    }

    debugPrint('OfflineVideo: playing network video: ${widget.networkUrl}');
    return VideoPlayerWidget(
      videoUrl: widget.networkUrl!,
      isLocalFile: false,
      autoPlay: widget.autoPlay,
      looping: widget.looping,
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.white54, size: 48),
            SizedBox(height: 8),
            Text('Video unavailable', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

/// Video player widget that uses an externally managed controller.
/// Does NOT dispose the controller (managed by VideoControllerManager).
class _ManagedVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final bool autoPlay;

  const _ManagedVideoPlayer({required this.controller, this.autoPlay = false});

  @override
  State<_ManagedVideoPlayer> createState() => _ManagedVideoPlayerState();
}

class _ManagedVideoPlayerState extends State<_ManagedVideoPlayer> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay && !widget.controller.value.isPlaying) {
      widget.controller.play();
    }
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    // Do NOT dispose the controller - it's managed externally
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
      } else {
        widget.controller.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video with BoxFit.cover
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),

          // Controls overlay
          if (_showControls)
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),

                  // Play/Pause button - centered
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Progress bar and duration at bottom
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          // Progress bar
                          VideoProgressIndicator(
                            controller,
                            allowScrubbing: true,
                            colors: VideoProgressColors(
                              playedColor: Colors.white,
                              bufferedColor: Colors.white.withValues(
                                alpha: 0.5,
                              ),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Duration text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(controller.value.position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(controller.value.duration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
