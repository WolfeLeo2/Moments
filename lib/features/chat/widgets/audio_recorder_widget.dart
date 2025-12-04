import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moments/core/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

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

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Timer? _timer;
  int _durationSeconds = 0;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      widget.onCancel();
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _recordingPath!,
    );

    setState(() {
      _isRecording = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _durationSeconds++;
      });
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _audioRecorder.stop();

    if (_recordingPath != null) {
      widget.onRecordingComplete(_recordingPath!, _durationSeconds * 1000);
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await _audioRecorder.stop();
    widget.onCancel();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Cancel button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _cancelRecording,
            color: Colors.red,
          ),

          const SizedBox(width: 8),

          // Recording indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: _isRecording
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // Duration
          Text(
            _formatDuration(_durationSeconds),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),

          const Spacer(),

          // Send button
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _stopRecording,
            color: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
