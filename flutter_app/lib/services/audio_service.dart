import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final Record _audioRecorder = Record();
  bool _isRecording = false;

  Future<bool> hasPermission() async {
    var status = await Permission.microphone.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.microphone.request();
    }
    return status == PermissionStatus.granted;
  }

  Future<void> startRecording() async {
    if (await hasPermission()) {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/voice_message.wav';
        
        await _audioRecorder.start(
          path: path,
          encoder: AudioEncoder.wav,
        );
        _isRecording = true;
      }
    }
  }

  Future<String?> stopRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      return path;
    }
    return null;
  }

  bool get isRecording => _isRecording;
}
