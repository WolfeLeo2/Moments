import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';

/// A reusable waveform visualization widget for audio notes.
/// Can be used in:
/// - Add Moment page (recording preview)
/// - Memory Card (compact indicator)
/// - Moment Details / Relive page (full playback)
/// - Chat audio messages (future migration)
///
/// Modes:
/// - [WaveformMode.recording]: Live amplitude bars growing as recording progresses
/// - [WaveformMode.playback]: Static bars with playback progress overlay
/// - [WaveformMode.compact]: Minimal single-line indicator for cards
class AudioWaveformWidget extends StatelessWidget {
  const AudioWaveformWidget({
    super.key,
    required this.amplitudes,
    this.mode = WaveformMode.playback,
    this.progress = 0.0,
    this.activeColor,
    this.inactiveColor,
    this.height = 40,
    this.barWidth = 3.0,
    this.barSpacing = 2.0,
    this.barRadius = 2.0,
    this.maxBars,
  });

  /// Normalized amplitude values (0.0 to 1.0)
  final List<double> amplitudes;

  /// Display mode
  final WaveformMode mode;

  /// Playback progress (0.0 to 1.0), used in playback mode
  final double progress;

  /// Color for active (played) bars
  final Color? activeColor;

  /// Color for inactive (unplayed) bars
  final Color? inactiveColor;

  /// Height of the waveform widget
  final double height;

  /// Width of each bar
  final double barWidth;

  /// Spacing between bars
  final double barSpacing;

  /// Corner radius of each bar
  final double barRadius;

  /// Maximum number of bars to display (auto-calculated if null)
  final int? maxBars;

  @override
  Widget build(BuildContext context) {
    if (amplitudes.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final totalBarWidth = barWidth + barSpacing;
          final displayBars =
              maxBars ?? (availableWidth / totalBarWidth).floor().clamp(1, 200);

          // Resample amplitudes to fit the available bars
          final resampled = _resample(amplitudes, displayBars);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(resampled.length, (index) {
              final amplitude = resampled[index];
              final barHeight = (amplitude * height * 0.85).clamp(2.0, height);
              final isActive = mode == WaveformMode.playback
                  ? index / resampled.length <= progress
                  : true;

              final color = isActive
                  ? (activeColor ?? AppTheme.coralPink)
                  : (inactiveColor ??
                        AppTheme.textGray.withValues(alpha: 0.25));

              return Padding(
                padding: EdgeInsets.only(
                  right: index < resampled.length - 1 ? barSpacing : 0,
                ),
                child: AnimatedContainer(
                  duration: mode == WaveformMode.recording
                      ? const Duration(milliseconds: 100)
                      : Duration.zero,
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(barRadius),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  /// Resample amplitude data to fit the target number of bars
  List<double> _resample(List<double> data, int targetCount) {
    if (data.length == targetCount) return data;
    if (data.length < targetCount) {
      // Pad with small values for recording mode
      return [...data, ...List.filled(targetCount - data.length, 0.05)];
    }

    // Downsample by averaging chunks
    final chunkSize = data.length / targetCount;
    return List.generate(targetCount, (i) {
      final start = (i * chunkSize).floor();
      final end = ((i + 1) * chunkSize).floor().clamp(start + 1, data.length);
      final chunk = data.sublist(start, end);
      return chunk.reduce((a, b) => a + b) / chunk.length;
    });
  }
}

/// Compact audio indicator for use on memory cards
/// Shows a small waveform icon with duration
class AudioNoteIndicator extends StatelessWidget {
  const AudioNoteIndicator({
    super.key,
    required this.durationSeconds,
    this.isPlaying = false,
    this.onTap,
  });

  final int durationSeconds;
  final bool isPlaying;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying ? Icons.pause : Icons.mic,
              color: AppTheme.coralPink,
              size: 14,
            ),
            const SizedBox(width: 4),
            // Mini waveform bars
            ...List.generate(5, (i) {
              final heights = [6.0, 10.0, 14.0, 8.0, 12.0];
              return Padding(
                padding: const EdgeInsets.only(right: 1.5),
                child: Container(
                  width: 2,
                  height: heights[i],
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }),
            const SizedBox(width: 4),
            Text(
              _formatDuration(durationSeconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

enum WaveformMode {
  /// Live recording — bars animate as amplitudes arrive
  recording,

  /// Playback — static bars with progress overlay
  playback,

  /// Compact — minimal display for cards
  compact,
}
