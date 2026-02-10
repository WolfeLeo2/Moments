import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/services/audio_note_service.dart';
import 'package:moments/core/services/haptic_service.dart';
import 'package:moments/data/models/moment.dart';
import 'package:moments/widgets/audio_waveform_widget.dart';

/// Audio entry for a single contributor's audio note
class _AudioEntry {
  final String momentId;
  final String audioPath;
  final int duration;
  final String? userId;
  final String? username;
  final String? avatarUrl;

  _AudioEntry({
    required this.momentId,
    required this.audioPath,
    required this.duration,
    this.userId,
    this.username,
    this.avatarUrl,
  });
}

/// Shows all audio notes from a collaborative moment group.
/// Used on the details page when multiple moments have audio.
class CollaborativeAudioList extends StatefulWidget {
  const CollaborativeAudioList({
    super.key,
    required this.moments,
    this.userAvatars = const {},
    this.userNames = const {},
  });

  final List<Moment> moments;

  /// userId → avatar URL map (resolved from contributors)
  final Map<String, String> userAvatars;

  /// userId → display name map
  final Map<String, String> userNames;

  @override
  State<CollaborativeAudioList> createState() => _CollaborativeAudioListState();
}

class _CollaborativeAudioListState extends State<CollaborativeAudioList> {
  final AudioNoteService _audioService = AudioNoteService();
  String? _playingMomentId;
  bool _isLoading = false;
  double _playbackProgress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  late List<_AudioEntry> _entries;

  @override
  void initState() {
    super.initState();
    _buildEntries();

    _playingSubscription = _audioService.isPlayingStream.listen((playing) {
      if (!playing && mounted) {
        setState(() {
          _playingMomentId = null;
          _playbackProgress = 0.0;
          _currentPosition = Duration.zero;
          _totalDuration = Duration.zero;
        });
      }
    });

    _positionSubscription =
        _audioService.playbackPositionStream.listen((pos) {
      if (mounted && _playingMomentId != null) {
        _currentPosition = pos;
        _updateProgress();
      }
    });

    _durationSubscription =
        _audioService.playbackDurationStream.listen((dur) {
      if (mounted && _playingMomentId != null) {
        _totalDuration = dur;
        _updateProgress();
      }
    });
  }

  void _updateProgress() {
    if (_totalDuration.inMilliseconds > 0) {
      final progress = (_currentPosition.inMilliseconds /
              _totalDuration.inMilliseconds)
          .clamp(0.0, 1.0);
      if ((progress - _playbackProgress).abs() > 0.005) {
        setState(() => _playbackProgress = progress);
      }
    }
  }

  void _buildEntries() {
    _entries = widget.moments
        .where((m) => m.audioPath != null)
        .map(
          (m) => _AudioEntry(
            momentId: m.id,
            audioPath: m.audioPath!,
            duration: m.audioDuration ?? 0,
            userId: m.userId,
            username: widget.userNames[m.userId] ?? 'Unknown',
            avatarUrl: widget.userAvatars[m.userId],
          ),
        )
        .toList();
  }

  @override
  void didUpdateWidget(CollaborativeAudioList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _buildEntries();
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(_AudioEntry entry) async {
    HapticService.lightTap();

    if (_playingMomentId == entry.momentId) {
      _audioService.stop();
      setState(() {
        _playingMomentId = null;
        _playbackProgress = 0.0;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _playingMomentId = entry.momentId;
      _playbackProgress = 0.0;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });

    final url = await AudioNoteService.getAudioUrl(entry.audioPath);
    if (url != null && mounted) {
      await _audioService.play(url, isUrl: true);
      if (mounted) setState(() => _isLoading = false);
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _playingMomentId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_rounded, size: 16, color: AppTheme.coralPink),
            const SizedBox(width: 6),
            Text(
              'AUDIO NOTES',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.coralPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_entries.length}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.coralPink,
                ),
              ),
            ),
          ],

        ),
        const SizedBox(height: 10),

        // Audio entries — centered, scrolls when overflow
        SizedBox(
          height: 64,
          child: Center(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _entries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return _buildAudioTag(_entries[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioTag(_AudioEntry entry) {
    final isPlaying = _playingMomentId == entry.momentId;
    final duration = entry.duration;
    // Show elapsed time during playback, total duration when idle
    final displaySeconds = isPlaying && _currentPosition.inMilliseconds > 0
        ? _currentPosition.inSeconds
        : duration;
    final minutes = displaySeconds ~/ 60;
    final seconds = displaySeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _togglePlay(entry),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPlaying
              ? AppTheme.coralPink.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaying ? AppTheme.coralPink : AppTheme.borderGray,
            width: isPlaying ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            _buildAvatar(entry),
            const SizedBox(width: 8),

            // Name + waveform column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.username ?? 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 16,
                      child: AudioWaveformWidget(
                        amplitudes: AudioNoteService.generateFakeWaveform(
                          duration,
                        ),
                        mode: isPlaying
                            ? WaveformMode.playback
                            : WaveformMode.compact,
                        progress: isPlaying ? _playbackProgress : 0.0,
                        activeColor: isPlaying
                            ? AppTheme.coralPink
                            : AppTheme.textGray,
                        inactiveColor: AppTheme.borderGray,
                        height: 16,
                        barWidth: 2,
                        barSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isPlaying
                            ? AppTheme.coralPink
                            : AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Play/Stop icon or loading indicator
            if (_isLoading && isPlaying)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.coralPink,
                ),
              )
            else
              Icon(
                isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: isPlaying ? AppTheme.coralPink : AppTheme.textGray,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(_AudioEntry entry) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.coralPink, width: 1.5),
      ),
      child: ClipOval(
        child: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: entry.avatarUrl!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _avatarFallback(entry),
              )
            : _avatarFallback(entry),
      ),
    );
  }

  Widget _avatarFallback(_AudioEntry entry) {
    return Container(
      width: 32,
      height: 32,
      color: AppTheme.coralPink.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          (entry.username ?? '?')[0].toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.coralPink,
          ),
        ),
      ),
    );
  }
}
