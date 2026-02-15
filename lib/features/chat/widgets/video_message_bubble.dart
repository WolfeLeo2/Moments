import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/features/chat/providers/media_cache_provider.dart';
import 'package:moments/features/chat/widgets/custom_media_bubble.dart';
import 'package:video_player/video_player.dart';
import 'package:moments/core/services/app_logger.dart';


final _log = AppLogger('VideoMessage');
class VideoMessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isMe;

  const VideoMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  ConsumerState<VideoMessageBubble> createState() => _VideoMessageBubbleState();
}

class _VideoMessageBubbleState extends ConsumerState<VideoMessageBubble> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.message.localMediaPath != null &&
        File(widget.message.localMediaPath!).existsSync()) {
      _videoPlayerController = VideoPlayerController.file(
        File(widget.message.localMediaPath!),
      );
      await _videoPlayerController!.initialize();
      _setupChewie();
      return;
    }

    if (widget.message.mediaUrl == null) return;

    try {
      final cacheService = ref.read(mediaCacheServiceProvider);

      // Get cached video file (downloads if not cached)
      final localPath = await cacheService.getVideoFile(
        widget.message.id,
        widget.message.mediaUrl!,
      );

      _videoPlayerController = VideoPlayerController.file(File(localPath));

      await _videoPlayerController!.initialize();
      _setupChewie();
    } catch (e) {
      _log.e('Error initializing video player: $e');
    }
  }

  void _setupChewie() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      autoPlay: false,
      looping: false,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppTheme.primaryBlue.withValues(alpha: 0.5),
        handleColor: AppTheme.primaryBlue,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.white,
      ),
      placeholder: Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      ),
      autoInitialize: true,
    );

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomMediaBubble(
      isSender: widget.isMe,
      color: widget.isMe ? AppTheme.primaryBlue : Colors.white,
      tail: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              )
            : Container(
                width: 200,
                height: 200,
                color: Colors.black,
                child: const Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }
}
