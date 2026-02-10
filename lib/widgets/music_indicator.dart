import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/services/haptic_service.dart';
import 'package:moments/core/services/deezer_service.dart';
import 'package:moments/data/models/music_data.dart';

/// Compact pill indicator for cards (overlays on MemoryCard)
class MusicNoteIndicator extends StatelessWidget {
  const MusicNoteIndicator({super.key, required this.musicData, this.onTap});

  final MusicData musicData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                musicData.title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline music player for details/relive pages
class MusicPlayerWidget extends StatefulWidget {
  const MusicPlayerWidget({
    super.key,
    required this.musicData,
    this.compact = false,
  });

  final MusicData musicData;
  final bool compact;

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final url = await _resolveUrl();
      if (url == null || !mounted) return;

      // Use LockCachingAudioSource to cache audio locally after first fetch
      final source = LockCachingAudioSource(Uri.parse(url));
      final dur = await _player.setAudioSource(source);
      if (dur != null && mounted) setState(() => _duration = dur);
    } catch (_) {}

    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(
          () => _isPlaying =
              state.playing &&
              state.processingState != ProcessingState.completed,
        );
        if (state.processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
          _player.pause();
        }
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Resolve a playable URL. Deezer preview URLs expire, so re-fetch from API.
  Future<String?> _resolveUrl() async {
    final music = widget.musicData;
    if (music.type == MusicType.deezer && music.trackId != null) {
      // Always fetch fresh preview URL — stored ones expire
      final deezer = DeezerService();
      final freshUrl = await deezer.getPreviewUrl(music.trackId!);
      deezer.dispose();
      return freshUrl ?? music.url; // fallback to stored URL
    }
    return music.url;
  }

  void _togglePlay() {
    HapticService.lightTap();
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.compact ? _buildCompact() : _buildFull();
  }

  Widget _buildCompact() {
    final music = widget.musicData;
    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGray, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Album art thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: music.albumArt != null && music.albumArt!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: music.albumArt!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _compactAlbumPlaceholder(),
                      errorWidget: (_, __, ___) => _compactAlbumPlaceholder(),
                    )
                  : _compactAlbumPlaceholder(),
            ),
            const SizedBox(width: 8),
            // Song info
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    music.title,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    music.artist,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Play/Pause icon
            Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: _isPlaying ? AppTheme.lavenderPop : AppTheme.textGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactAlbumPlaceholder() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.lavenderPop.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: AppTheme.lavenderPop,
        size: 16,
      ),
    );
  }

  Widget _buildFull() {
    final music = widget.musicData;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.lavenderPop.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lavenderPop.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Album art / icon
          GestureDetector(
            onTap: _togglePlay,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: music.albumArt != null && music.albumArt!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: music.albumArt!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _albumPlaceholder(),
                          errorWidget: (_, __, ___) => _albumPlaceholder(),
                        )
                      : _albumPlaceholder(),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  music.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  music.artist,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.lavenderPop.withValues(
                      alpha: 0.15,
                    ),
                    valueColor: AlwaysStoppedAnimation(AppTheme.lavenderPop),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Duration
          Text(
            _formatDuration(_position),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _albumPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.lavenderPop.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: AppTheme.lavenderPop,
        size: 22,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
