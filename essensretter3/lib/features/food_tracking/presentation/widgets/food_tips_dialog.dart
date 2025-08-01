import 'package:flutter/material.dart';

class FoodTipsDialog extends StatelessWidget {
  final String foodName;

  const FoodTipsDialog({
    super.key,
    required this.foodName,
  });

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
                    'Haltbarkeitstipps für $foodName',
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
                  Text(
                    _getTipsForFood(foodName),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue.shade800,
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

  String _getTipsForFood(String foodName) {
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
}