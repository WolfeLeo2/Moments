import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/services/audio_note_service.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/features/chat/providers/media_cache_provider.dart';
import 'package:moments/features/chat/widgets/custom_bubble_special_three.dart';
import 'package:moments/widgets/audio_waveform_widget.dart';
import 'package:moments/core/services/app_logger.dart';


final _log = AppLogger('AudioMessage');
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
    try {
      String? filePath;

      if (widget.message.localMediaPath != null &&
          File(widget.message.localMediaPath!).existsSync()) {
        filePath = widget.message.localMediaPath;
      } else if (widget.message.mediaUrl != null) {
        final cacheService = ref.read(mediaCacheServiceProvider);
        filePath = await cacheService.getAudioFile(
          widget.message.id,
          widget.message.mediaUrl!,
        );
      }

      if (filePath == null) return;

      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setFilePath(filePath);

      // Listen to player state
      _playerStateSubscription = _audioPlayer!.playerStateStream.listen((
        state,
      ) {
        if (mounted) {
          setState(() {
            _isPlaying =
                state.playing &&
                state.processingState != ProcessingState.completed;
          });
          // Auto-reset when playback completes
          if (state.processingState == ProcessingState.completed) {
            _audioPlayer!.seek(Duration.zero);
            _audioPlayer!.pause();
          }
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
      _log.e('❌ [AudioBubble] Error initializing audio: $e');
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
      _log.e('❌ [AudioBubble] Error toggling playback: $e');
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
      color: widget.isMe ? AppTheme.primaryBlue : Colors.white,
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
                  color: color.withValues(alpha: 0.2),
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

            // Waveform visualization
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Audio waveform
                  SizedBox(
                    height: 28,
                    child: AudioWaveformWidget(
                      amplitudes: AudioNoteService.generateFakeWaveform(
                        _duration.inSeconds > 0 ? _duration.inSeconds : 10,
                      ),
                      mode: WaveformMode.playback,
                      progress: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds / _duration.inMilliseconds
                          : 0.0,
                      activeColor: color,
                      inactiveColor: color.withValues(alpha: 0.25),
                      height: 28,
                      barWidth: 2.5,
                      barSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Time display
                  Text(
                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
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
