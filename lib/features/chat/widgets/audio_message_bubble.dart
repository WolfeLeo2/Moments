import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/features/chat/providers/media_cache_provider.dart';
import 'package:moments/features/chat/widgets/custom_bubble_special_three.dart';

class AudioMessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isMe;

  const AudioMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  ConsumerState<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends ConsumerState<AudioMessageBubble>
    with AutomaticKeepAliveClientMixin {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (widget.message.mediaUrl == null) return;

    try {
      final cacheService = ref.read(mediaCacheServiceProvider);
      final localPath = await cacheService.getAudioFile(
        widget.message.id,
        widget.message.mediaUrl!,
      );

      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setFilePath(localPath);

      // Listen to player state
      _playerStateSubscription = _audioPlayer!.playerStateStream.listen((
        state,
      ) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      // Listen to duration
      _durationSubscription = _audioPlayer!.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Listen to position
      _positionSubscription = _audioPlayer!.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
    } catch (e) {
      debugPrint('❌ [AudioBubble] Error initializing audio: $e');
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioPlayer == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        // If at end, restart from beginning
        if (_position >= _duration && _duration > Duration.zero) {
          await _audioPlayer!.seek(Duration.zero);
        }
        await _audioPlayer!.play();
      }
    } catch (e) {
      debugPrint('❌ [AudioBubble] Error toggling playback: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final color = widget.isMe ? Colors.white : Colors.black87;

    return CustomBubbleSpecialThree(
      isSender: widget.isMe,
      color: widget.isMe ? AppTheme.electricPurple : Colors.white,
      tail: true,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play/Pause button
            GestureDetector(
              onTap: _togglePlayback,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Progress and duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds / _duration.inMilliseconds
                          : 0,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Time display
                  Text(
                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }
}
