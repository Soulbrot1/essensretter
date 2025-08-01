import 'package:flutter/material.dart';
import '../../data/datasources/food_tips_service.dart';
import '../../../../injection_container.dart' as di;

class FoodTipsDialog extends StatefulWidget {
  final String foodName;

  const FoodTipsDialog({
    super.key,
    required this.foodName,
  });

  @override
  State<FoodTipsDialog> createState() => _FoodTipsDialogState();
}

class _FoodTipsDialogState extends State<FoodTipsDialog> {
  late final FoodTipsService _foodTipsService;
  String? _tips;
  String? _spoilageIndicators;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _foodTipsService = di.sl<FoodTipsService>();
    _loadTips();
  }

  Future<void> _loadTips() async {
    try {
      final tips = await _foodTipsService.getFoodStorageTips(widget.foodName);
      final spoilage = await _foodTipsService.getSpoilageIndicators(widget.foodName);
      if (mounted) {
        setState(() {
          _tips = tips;
          _spoilageIndicators = spoilage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Haltbarkeitstipps für ${widget.foodName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tipps zur längeren Haltbarkeit:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Text(
                          _tips ?? _getDefaultTips(widget.foodName),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.blue.shade800,
                            height: 1.4,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Verderbnis-Hinweise
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_outlined,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Wann ist ${widget.foodName} verdorben?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Text(
                          _spoilageIndicators ?? _getDefaultSpoilageIndicators(widget.foodName),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red.shade800,
                            height: 1.4,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Schließen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDefaultTips(String foodName) {
    final name = foodName.toLowerCase();
    
    if (name.contains('apfel') || name.contains('äpfel')) {
      return '• Im Kühlschrank aufbewahren\n• Getrennt von anderen Früchten lagern\n• Ethylen-Gas lässt andere Früchte schneller reifen\n• Druckstellen vermeiden';
    } else if (name.contains('brot')) {
      return '• Bei Raumtemperatur in Brotkasten aufbewahren\n• Nicht im Kühlschrank lagern\n• In Papiertüte oder Brotbeutel\n• Angeschnittene Seite nach unten legen';
    } else if (name.contains('milch')) {
      return '• Immer im Kühlschrank aufbewahren (4°C)\n• Original-Verpackung verwenden\n• Nicht in der Kühlschranktür lagern\n• Nach dem Öffnen schnell verbrauchen';
    } else if (name.contains('banane')) {
      return '• Bei Raumtemperatur lagern\n• Nicht im Kühlschrank aufbewahren\n• Getrennt von anderen Früchten\n• Grüne Bananen reifen bei Wärme schneller';
    } else if (name.contains('tomate')) {
      return '• Bei Raumtemperatur lagern\n• Nicht im Kühlschrank aufbewahren\n• Stielansatz nach unten\n• Getrennt von anderen Gemüsesorten';
    } else if (name.contains('salat') || name.contains('kopfsalat')) {
      return '• Im Kühlschrank im Gemüsefach\n• In perforierter Plastiktüte\n• Nicht waschen vor der Lagerung\n• Welke Blätter entfernen';
    } else if (name.contains('kartoffel')) {
      return '• Kühl, dunkel und trocken lagern\n• Nicht im Kühlschrank\n• Getrennt von Zwiebeln\n• Grüne Stellen entfernen';
    } else if (name.contains('fleisch') || name.contains('wurst')) {
      return '• Im kältesten Teil des Kühlschranks\n• Original-Verpackung verwenden\n• Bei 0-4°C lagern\n• Getrennt von anderen Lebensmitteln';
    } else if (name.contains('käse')) {
      return '• Im Kühlschrank aufbewahren\n• In Käsepapier oder Pergament\n• Nicht in Plastik einwickeln\n• Hart- und Weichkäse getrennt lagern';
    } else {
      return '• An einem kühlen, trockenen Ort lagern\n• Original-Verpackung beachten\n• Mindesthaltbarkeitsdatum prüfen\n• Bei Zweifeln an Geruch und Aussehen orientieren';
    }
  }
  
  String _getDefaultSpoilageIndicators(String foodName) {
    final name = foodName.toLowerCase();
    
    if (name.contains('apfel') || name.contains('äpfel')) {
      return '• Braune, weiche Stellen\n• Fauliger Geruch\n• Runzelige Haut\n• Schimmelbildung am Stiel';
    } else if (name.contains('brot')) {
      return '• Grüner oder weißer Schimmel\n• Säuerlicher Geruch\n• Harte, trockene Konsistenz\n• Verfärbungen sichtbar';
    } else if (name.contains('milch')) {
      return '• Säuerlicher Geruch\n• Klumpige Konsistenz\n• Gelbliche Verfärbung\n• Säuerlicher Geschmack';
    } else if (name.contains('banane')) {
      return '• Schwarze, matschige Stellen\n• Alkoholischer Geruch\n• Flüssigkeit tritt aus\n• Schimmel am Stielansatz';
    } else if (name.contains('tomate')) {
      return '• Weiche, matschige Stellen\n• Schimmelbildung\n• Säuerlicher Geruch\n• Runzelige Haut';
    } else if (name.contains('salat') || name.contains('kopfsalat')) {
      return '• Braune, schleimige Blätter\n• Fauliger Geruch\n• Welke Konsistenz\n• Dunkle Verfärbungen';
    } else if (name.contains('kartoffel')) {
      return '• Grüne Verfärbung\n• Weiche, faulige Stellen\n• Süßlicher Geruch\n• Austriebe vorhanden';
    } else if (name.contains('fleisch') || name.contains('wurst')) {
      return '• Grau-grüne Verfärbung\n• Säuerlicher Geruch\n• Schmierige Oberfläche\n• Unangenehmer Geschmack';
    } else if (name.contains('käse')) {
      return '• Ungewöhnlicher Schimmel\n• Ammoniakgeruch\n• Schmierige Konsistenz\n• Bitterer Geschmack';
    } else {
      return '• Ungewöhnlicher Geruch\n• Verfärbungen sichtbar\n• Schimmelbildung\n• Veränderte Konsistenz';
    }
  }
}