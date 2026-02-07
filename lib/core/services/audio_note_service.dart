import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moments/core/services/app_logger.dart';

final _log = AppLogger('AudioNoteService');

/// Reusable audio service for recording, playback, and storage.
/// Designed to be shared between moments audio notes and chat voice messages.
///
/// Features:
/// - Recording with AAC-LC codec (m4a)
/// - Playback with position/duration streams
/// - Supabase storage upload/download
/// - Waveform amplitude sampling during recording
/// - Singleton per-screen via Riverpod or manual lifecycle
///
/// Future: Spotify/curated audio integration placeholder
/// TODO: Add ambient music suggestions based on era/mood
/// TODO: Add curated soundscapes (rain, ocean, cafe) for relive experience
class AudioNoteService {
  AudioRecorder? _recorder;
  AudioPlayer? _player;

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  Timer? _amplitudeTimer;
  int _recordingDurationSeconds = 0;

  /// Sampled amplitudes during recording for waveform visualization
  final List<double> _amplitudeSamples = [];

  /// Maximum recording duration (3 minutes for audio notes)
  static const int maxDurationSeconds = 180;

  // Streams for UI binding
  final _isRecordingController = StreamController<bool>.broadcast();
  final _isPlayingController = StreamController<bool>.broadcast();
  final _durationController = StreamController<int>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _totalDurationController = StreamController<Duration>.broadcast();
  final _amplitudeController = StreamController<List<double>>.broadcast();

  Stream<bool> get isRecordingStream => _isRecordingController.stream;
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<int> get recordingDurationStream => _durationController.stream;
  Stream<Duration> get playbackPositionStream => _positionController.stream;
  Stream<Duration> get playbackDurationStream =>
      _totalDurationController.stream;
  Stream<List<double>> get amplitudeStream => _amplitudeController.stream;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  int get recordingDuration => _recordingDurationSeconds;
  List<double> get amplitudeSamples => List.unmodifiable(_amplitudeSamples);
  String? get currentRecordingPath => _currentRecordingPath;

  // ============================================
  // RECORDING
  // ============================================

  /// Request microphone permission and start recording
  /// Returns true if recording started successfully
  Future<bool> startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _log.w('Microphone permission denied');
        return false;
      }

      _recorder ??= AudioRecorder();

      final dir = await getTemporaryDirectory();
      _currentRecordingPath =
          '${dir.path}/audio_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingDurationSeconds = 0;
      _amplitudeSamples.clear();
      _isRecordingController.add(true);

      // Duration timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _recordingDurationSeconds++;
        _durationController.add(_recordingDurationSeconds);

        // Auto-stop at max duration
        if (_recordingDurationSeconds >= maxDurationSeconds) {
          stopRecording();
        }
      });

      // Amplitude sampling for waveform (10 samples/sec)
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (
        _,
      ) async {
        try {
          final amp = await _recorder?.getAmplitude();
          if (amp != null) {
            // Normalize amplitude from dBFS (-160 to 0) to 0.0-1.0
            final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
            _amplitudeSamples.add(normalized);
            _amplitudeController.add(List.from(_amplitudeSamples));
          }
        } catch (_) {}
      });

      _log.i('Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      _log.e('Failed to start recording: $e');
      _isRecording = false;
      _isRecordingController.add(false);
      return false;
    }
  }

  /// Stop recording and return the file path + duration
  Future<({String path, int durationSeconds})?> stopRecording() async {
    if (!_isRecording) return null;

    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();

    try {
      await _recorder?.stop();
    } catch (e) {
      _log.e('Error stopping recorder: $e');
    }

    _isRecording = false;
    _isRecordingController.add(false);

    if (_currentRecordingPath == null) return null;

    final result = (
      path: _currentRecordingPath!,
      durationSeconds: _recordingDurationSeconds,
    );
    _log.i(
      'Recording complete: ${_recordingDurationSeconds}s, ${_amplitudeSamples.length} samples',
    );
    return result;
  }

  /// Cancel recording and delete the temp file
  Future<void> cancelRecording() async {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();

    try {
      await _recorder?.stop();
    } catch (_) {}

    _isRecording = false;
    _isRecordingController.add(false);

    // Delete temp file
    if (_currentRecordingPath != null) {
      try {
        await File(_currentRecordingPath!).delete();
      } catch (_) {}
      _currentRecordingPath = null;
    }

    _amplitudeSamples.clear();
    _recordingDurationSeconds = 0;
  }

  // ============================================
  // PLAYBACK
  // ============================================

  /// Play audio from a file path or URL
  Future<void> play(String source, {bool isUrl = false}) async {
    try {
      _player ??= AudioPlayer();

      // Stop any existing playback
      await _player!.stop();

      if (isUrl) {
        await _player!.setUrl(source);
      } else {
        await _player!.setFilePath(source);
      }

      // Listen to streams
      _player!.positionStream.listen((pos) {
        _positionController.add(pos);
      });

      _player!.durationStream.listen((dur) {
        if (dur != null) _totalDurationController.add(dur);
      });

      _player!.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        _isPlayingController.add(state.playing);

        // Auto-reset when complete
        if (state.processingState == ProcessingState.completed) {
          _player!.seek(Duration.zero);
          _player!.pause();
        }
      });

      await _player!.play();
      _log.i('Playback started: $source');
    } catch (e) {
      _log.e('Playback error: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    await _player?.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _player?.play();
  }

  /// Toggle play/pause
  Future<void> togglePlayback() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player?.seek(position);
  }

  /// Stop playback
  Future<void> stop() async {
    await _player?.stop();
    _isPlaying = false;
    _isPlayingController.add(false);
  }

  // ============================================
  // STORAGE (Supabase)
  // ============================================

  /// Upload audio file to Supabase storage
  /// Returns the storage path (not full URL)
  static Future<String?> uploadAudio(String localPath) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _log.e('Cannot upload audio: not authenticated');
        return null;
      }

      final file = File(localPath);
      if (!await file.exists()) {
        _log.e('Audio file not found: $localPath');
        return null;
      }

      final storagePath =
          '$userId/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await Supabase.instance.client.storage
          .from('moment-audio')
          .upload(storagePath, file);

      _log.i('Audio uploaded: $storagePath');
      return storagePath;
    } catch (e) {
      _log.e('Failed to upload audio: $e');
      return null;
    }
  }

  /// Get a signed URL for an audio storage path
  static Future<String?> getAudioUrl(String storagePath) async {
    try {
      final url = await Supabase.instance.client.storage
          .from('moment-audio')
          .createSignedUrl(storagePath, 60 * 60 * 24); // 24h
      return url;
    } catch (e) {
      _log.e('Failed to get audio URL: $e');
      return null;
    }
  }

  // ============================================
  // WAVEFORM HELPERS
  // ============================================

  /// Generate fake waveform data for audio files that don't have
  /// recorded amplitude data (e.g., downloaded from server)
  static List<double> generateFakeWaveform(int durationSeconds) {
    final random = Random(durationSeconds.hashCode);
    final sampleCount = durationSeconds * 10; // 10 samples per second
    return List.generate(sampleCount, (i) {
      // Natural-looking waveform with some variation
      final base = 0.3 + random.nextDouble() * 0.5;
      final variation = sin(i * 0.1) * 0.15;
      return (base + variation).clamp(0.1, 1.0);
    });
  }

  // ============================================
  // LIFECYCLE
  // ============================================

  /// Clean up all resources
  void dispose() {
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    _recorder?.dispose();
    _player?.dispose();
    _isRecordingController.close();
    _isPlayingController.close();
    _durationController.close();
    _positionController.close();
    _totalDurationController.close();
    _amplitudeController.close();
  }
}
