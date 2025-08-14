import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../injection_container.dart' as di;
import 'speech_recording_dialog.dart';

class VoiceInputDialog extends StatefulWidget {
  final Function(String) onResult;

  const VoiceInputDialog({super.key, required this.onResult});

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog> {
  late SpeechService _speechService;
  String? _recognizedText;
  bool _isListening = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _speechService = di.sl<SpeechService>();
    _initializeAndStartListening();
  }

  Future<void> _initializeAndStartListening() async {
    try {
      // Initialisiere Speech Service
      final initialized = await _speechService.initialize();
      if (!initialized) {
        _showError('Spracherkennung konnte nicht initialisiert werden');
        return;
      }

      // Prüfe Mikrofon-Berechtigung
      final permissionStatus = await _speechService
          .getMicrophonePermissionStatus();
      if (permissionStatus == PermissionStatus.permanentlyDenied) {
        _showPermissionDialog();
        return;
      }

      final hasPermission = await _speechService.requestMicrophonePermission();
      if (!hasPermission) {
        _showError('Mikrofon-Berechtigung erforderlich');
        return;
      }

      setState(() {
        _isInitializing = false;
      });

      // Starte automatisch die Aufnahme
      await _startListening();
    } catch (e) {
      _showError('Fehler bei der Initialisierung: $e');
    }
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _recognizedText = null;
    });

    try {
      final result = await _speechService.startListening(
        localeId: 'de_DE',
        timeout: const Duration(seconds: 30),
      );

      if (mounted) {
        setState(() {
          _isListening = false;
          _recognizedText = result;
        });

        if (result == null || result.isEmpty) {
          _showError('Keine Sprache erkannt. Versuchen Sie es erneut.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
        _showError('Fehler bei der Sprachaufnahme: $e');
      }
    }
  }

  void _showError(String message) {
    // Zeige Fehler im Dialog statt SnackBar, da Context-Probleme auftreten können
    if (mounted) {
      setState(() {
        _isListening = false;
        _recognizedText = 'Fehler: $message';
      });
    }
  }

  void _showPermissionDialog() {
    if (mounted) {
      setState(() {
        _isInitializing = false;
        _recognizedText = 'Berechtigung erforderlich';
      });
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _speechService.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Spracherkennung wird initialisiert...'),
            ],
          ),
        ),
      );
    }

    // Spezielle Behandlung für fehlende Berechtigung
    if (_recognizedText == 'Berechtigung erforderlich') {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Mikrofon-Berechtigung erforderlich',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Bitte gehen Sie zu den iPhone-Einstellungen:\n\n'
                '1. Einstellungen → Datenschutz & Sicherheit\n'
                '2. Mikrofon\n'
                '3. Essensretter aktivieren',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                      await openAppSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Einstellungen öffnen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SpeechRecordingDialog(
      isListening: _isListening,
      recognizedText: _recognizedText,
      onCancel: () async {
        if (_isListening) {
          await _speechService.cancel();
        }
        if (mounted && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      onComplete: (text) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onResult(text);
        }
      },
    );
  }
}
