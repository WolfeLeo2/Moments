import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:moments/core/services/audio_note_service.dart';
import 'package:moments/widgets/audio_waveform_widget.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(String path, int durationMs) onRecordingComplete;
  final VoidCallback onCancel;

  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
  });

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  final AudioNoteService _audioService = AudioNoteService();
  int _durationSeconds = 0;
  List<double> _amplitudes = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isStopped = false;

  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Handle auto-stop at max duration (service stops internally at 180s)
    _subscriptions.add(
      _audioService.isRecordingStream.listen((recording) {
        if (!recording && !_isStopped && mounted) {
          // Recording stopped by the service (max duration reached)
          _handleAutoStop();
        }
      }),
    );
    _subscriptions.add(
      _audioService.recordingDurationStream.listen((seconds) {
        if (mounted && !_isStopped) setState(() => _durationSeconds = seconds);
      }),
    );
    _subscriptions.add(
      _audioService.amplitudeStream.listen((amps) {
        if (mounted && !_isStopped) setState(() => _amplitudes = amps);
      }),
    );

    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      final started = await _audioService.startRecording();
      if (!started && mounted) {
        widget.onCancel();
      }
    } catch (e) {
      if (mounted) widget.onCancel();
    }
  }

  Future<void> _handleAutoStop() async {
    if (_isStopped) return;
    _isStopped = true;

    // Cancel subscriptions to prevent further setState calls
    for (final sub in _subscriptions) {
      sub.cancel();
    }

    final result = await _audioService.stopRecording();
    if (result != null && mounted) {
      widget.onRecordingComplete(result.path, result.durationSeconds * 1000);
    } else if (mounted) {
      widget.onCancel();
    }
  }

  Future<void> _stopRecording() async {
    if (_isStopped) return;
    _isStopped = true;

    // Cancel subscriptions to prevent further setState calls
    for (final sub in _subscriptions) {
      sub.cancel();
    }

    final result = await _audioService.stopRecording();
    if (result != null && mounted) {
      widget.onRecordingComplete(result.path, result.durationSeconds * 1000);
    } else if (mounted) {
      widget.onCancel();
    }
  }

  Future<void> _cancelRecording() async {
    if (_isStopped) return;
    _isStopped = true;

    // Cancel subscriptions to prevent further setState calls
    for (final sub in _subscriptions) {
      sub.cancel();
    }

    await _audioService.cancelRecording();
    if (mounted) widget.onCancel();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live waveform
          SizedBox(
            height: 36,
            child: AudioWaveformWidget(
              amplitudes: _amplitudes,
              mode: WaveformMode.recording,
              activeColor: AppTheme.primaryBlue,
              inactiveColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
              barWidth: 2.5,
              barSpacing: 1.5,
              height: 36,
            ),
          ),
          const SizedBox(height: 8),
          // Controls row
          Row(
            children: [
              // Cancel button
              GestureDetector(
                onTap: _cancelRecording,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.emergencyRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.emergencyRed,
                    size: 18,
                  ),
                ),
              ),
              const Spacer(),
              // Pulse dot + duration
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.emergencyRed.withValues(
                            alpha: _pulseAnimation.value,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_durationSeconds),
                        style: GoogleFonts.spaceMono(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              // Send button
              GestureDetector(
                onTap: _stopRecording,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _pulseController.dispose();
    _audioService.dispose();
    super.dispose();
  }
}
