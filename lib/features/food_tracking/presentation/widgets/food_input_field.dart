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
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isExpanded = false;

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
    final micPermission = await Permission.microphone.request();
    if (micPermission.isGranted) {
      _speechAvailable = await _speech.initialize(
        onError: (error) => debugPrint('Speech error: $error'),
        onStatus: (status) => debugPrint('Speech status: $status'),
      );
      setState(() {});
    }
  }

  void _startListening() async {
    if (!_speechAvailable) return;
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
      localeId: 'de_DE',
    );
    
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
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

  void _showSpeechNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Spracheingabe ist nur auf echten Geräten verfügbar'),
        duration: Duration(seconds: 2),
      ),
    );
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
                      decoration: InputDecoration(
                        hintText: 'z.B. "Honig 5 Tage, Salami 4.08, Milch morgen"',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.all(12),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening ? Colors.red : (_speechAvailable ? null : Colors.grey),
                              ),
                              onPressed: _speechAvailable 
                                  ? (_isListening ? _stopListening : _startListening)
                                  : _showSpeechNotAvailable,
                              tooltip: _speechAvailable 
                                  ? (_isListening ? 'Aufnahme stoppen' : 'Spracheingabe starten')
                                  : 'Spracheingabe nicht verfügbar',
                            ),
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