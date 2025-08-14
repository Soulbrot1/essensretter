import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          // Error handled silently
        },
        onStatus: (status) {
          _isListening = status == 'listening';
        },
      );
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;

      if (status == PermissionStatus.granted) {
        return true;
      }

      if (status == PermissionStatus.permanentlyDenied) {
        return false;
      }

      final newStatus = await Permission.microphone.request();
      return newStatus == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  Future<PermissionStatus> getMicrophonePermissionStatus() async {
    return await Permission.microphone.status;
  }

  Future<String?> startListening({
    String localeId = 'de_DE',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      return null;
    }

    try {
      String recognizedText = '';

      await _speech.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
        },
        localeId: localeId,
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        onSoundLevelChange: (level) {
          // Optional: Sound level feedback
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );

      // Warte bis die Aufnahme beendet ist
      while (_speech.isListening) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return recognizedText.trim().isNotEmpty ? recognizedText.trim() : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  Future<void> cancel() async {
    if (_speech.isListening) {
      await _speech.cancel();
      _isListening = false;
    }
  }

  Future<List<stt.LocaleName>> get availableLocales => _speech.locales();

  Future<bool> get hasPermission => _speech.hasPermission;

  void dispose() {
    // Speech-to-Text hat keine dispose Methode
    _isInitialized = false;
    _isListening = false;
  }
}
