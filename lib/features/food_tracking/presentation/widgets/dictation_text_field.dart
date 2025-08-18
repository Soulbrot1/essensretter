import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class DictationTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSubmitted;
  final int maxLines;

  const DictationTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.maxLines = 3,
  });

  @override
  State<DictationTextField> createState() => _DictationTextFieldState();
}

class _DictationTextFieldState extends State<DictationTextField> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final micPermission = await Permission.microphone.request();
      if (micPermission.isGranted) {
        _speechAvailable = await _speech.initialize(
          onError: (error) => {}, // Error handled silently
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              setState(() {
                _isListening = false;
              });
            }
          },
        );
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      // Error handled silently
    }
  }

  void _startListening() async {
    if (!_speechAvailable || _isListening) return;

    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              widget.controller.text = result.recognizedWords;
            });
          }
        },
        localeId: 'de_DE',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );

      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }
    } catch (e) {
      // Error handled silently
    }
  }

  void _stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    } catch (e) {
      // Error handled silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      maxLines: widget.maxLines,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      autofocus: true,
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(16),
        suffixIcon: IconButton(
          icon: const Icon(Icons.send),
          onPressed: widget.onSubmitted,
        ),
      ),
      onSubmitted: (_) => widget.onSubmitted?.call(),
    );
  }
}
