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
      context.read<FoodBloc>().add(AddFoodFromTextEvent(text));
      _controller.clear();
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lebensmittel hinzufügen',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'z.B. "Honig 5 Tage, Salami 4.08, Milch morgen"',
              border: const OutlineInputBorder(),
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
    );
  }
}