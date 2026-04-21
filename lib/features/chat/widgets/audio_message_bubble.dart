import 'package:chat_bubbles/chat_bubbles.dart' as cb;
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/services/audio_note_service.dart';
import 'package:moments/data/models/message.dart';
import 'package:moments/features/chat/providers/media_cache_provider.dart';
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
  double _playbackSpeed = 1.0;
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

  Future<void> _changeSeek(double seconds) async {
    if (_audioPlayer == null) return;
    await _audioPlayer!.seek(Duration(milliseconds: (seconds * 1000).round()));
  }

  Future<void> _changePlaybackSpeed(double speed) async {
    if (_audioPlayer == null) return;
    await _audioPlayer!.setSpeed(speed);
    if (!mounted) return;
    setState(() => _playbackSpeed = speed);
  }

  String _formatTimestamp(BuildContext context) {
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(widget.message.createdAt));
  }

  _MessageStatusFlags _statusFromSendStatus() {
    switch (widget.message.sendStatus) {
      case MessageSendStatus.read:
        return const _MessageStatusFlags(
          sent: true,
          delivered: true,
          seen: true,
        );
      case MessageSendStatus.delivered:
        return const _MessageStatusFlags(
          sent: true,
          delivered: true,
          seen: false,
        );
      case MessageSendStatus.sent:
        return const _MessageStatusFlags(
          sent: true,
          delivered: false,
          seen: false,
        );
      case MessageSendStatus.pending:
      case MessageSendStatus.sending:
      case MessageSendStatus.failed:
        return const _MessageStatusFlags(
          sent: false,
          delivered: false,
          seen: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bubbleColor = widget.isMe ? AppTheme.primaryBlue : Colors.white;
    final textColor = widget.isMe ? Colors.white : Colors.black87;
    final status = _statusFromSendStatus();

    return cb.BubbleNormalAudio(
      color: bubbleColor,
      isSender: widget.isMe,
      tail: true,
      duration: _duration.inSeconds.toDouble(),
      position: _position.inSeconds.toDouble(),
      isPlaying: _isPlaying,
      isLoading: _audioPlayer == null,
      isPause: !_isPlaying && _position > Duration.zero,
      onSeekChanged: _changeSeek,
      onPlayPauseButtonClick: _togglePlayback,
      textStyle: TextStyle(
        color: textColor.withValues(alpha: 0.75),
        fontSize: 12,
      ),
      timestamp: _formatTimestamp(context),
      isEdited: widget.message.isEdited,
      sent: status.sent,
      delivered: status.delivered,
      seen: status.seen,
      waveformData: AudioNoteService.generateFakeWaveform(
        _duration.inSeconds > 0 ? _duration.inSeconds : 10,
      ),
      waveformActiveColor: widget.isMe ? Colors.white : AppTheme.primaryBlue,
      waveformInactiveColor: textColor.withValues(alpha: 0.25),
      showPlaybackSpeed: true,
      playbackSpeed: _playbackSpeed,
      onPlaybackSpeedChanged: _changePlaybackSpeed,
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

class _MessageStatusFlags {
  final bool sent;
  final bool delivered;
  final bool seen;

  const _MessageStatusFlags({
    required this.sent,
    required this.delivered,
    required this.seen,
  });
}
