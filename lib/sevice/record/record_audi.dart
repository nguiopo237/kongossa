import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;
  bool _isRecording = false;

  // Vérifier les permissions
  Future<bool> checkAndRequestPermissions() async {
    if (await Permission.microphone.isDenied) {
      final status = await Permission.microphone.request();
      return status.isGranted;
    }
    return true;
  }

  // Commencer l'enregistrement
  Future<bool> startRecording() async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      throw Exception('Permission microphone refusée');
    }

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _recordingPath = path;
      _isRecording = true;
      return true;
    } catch (e) {
      print("❌ Erreur enregistrement: $e");
      return false;
    }
  }

  // Arrêter l'enregistrement
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      print("❌ Erreur arrêt: $e");
      return null;
    }
  }

  // Annuler l'enregistrement
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}