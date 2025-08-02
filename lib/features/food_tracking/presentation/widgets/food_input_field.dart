import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../bloc/food_bloc.dart';
import '../bloc/food_event.dart';

class FoodInputField extends StatefulWidget {
  const FoodInputField({super.key});

  @override
  State<FoodInputField> createState() => _FoodInputFieldState();
}

class _FoodInputFieldState extends State<FoodInputField> {
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isExpanded = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final micPermission = await Permission.microphone.request();
      if (micPermission.isGranted) {
        _speechAvailable = await _speech.initialize(
          onError: (error) => debugPrint('Speech error: $error'),
          onStatus: (status) {
            debugPrint('Speech status: $status');
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
      debugPrint('Speech initialization error: $e');
    }
  }

  void _submitText() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      // Tastatur ausblenden
      FocusScope.of(context).unfocus();
      
      context.read<FoodBloc>().add(ShowFoodPreviewEvent(text));
      _controller.clear();
      
      // Nach dem Senden automatisch einklappen
      setState(() {
        _isExpanded = false;
      });
    }
  }

  void _startListening() async {
    if (!_speechAvailable || _isListening) return;
    
    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _controller.text = result.recognizedWords;
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
        
        // Feedback für den Benutzer
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎤 Diktierung aktiv - verwende iOS-Diktat für beste Ergebnisse'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Start listening error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Starten der Diktierung'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        
        // Nach dem Stoppen automatisch den Text senden, wenn nicht leer
        final text = _controller.text.trim();
        if (text.isNotEmpty) {
          _submitText();
        }
      }
    } catch (e) {
      debugPrint('Stop listening error: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header mit Dropdown-Button
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lebensmittel hinzufügen',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Einklappbarer Inhalt
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isExpanded ? 1.0 : 0.0,
              child: _isExpanded ? Container(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      maxLines: 3,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'z.B. "Honig 5 Tage, Salami 4.08, Milch morgen"',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.all(12),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Mikrofon Button für iOS-Diktierung
                            IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening 
                                    ? Colors.red 
                                    : (_speechAvailable ? null : Colors.grey),
                              ),
                              onPressed: _speechAvailable 
                                  ? (_isListening ? _stopListening : _startListening)
                                  : null,
                              tooltip: _speechAvailable 
                                  ? (_isListening ? 'Diktierung stoppen' : 'iOS-Diktierung verwenden')
                                  : 'Mikrofon nicht verfügbar',
                            ),
                            // Send Button
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _submitText,
                            ),
                          ],
                        ),
                      ),
                      onSubmitted: (_) => _submitText(),
                    ),
                  ],
                ),
              ) : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}