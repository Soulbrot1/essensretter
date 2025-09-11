import 'package:flutter/material.dart';
import '../../data/datasources/food_tips_service.dart';
import '../../../../injection_container.dart' as di;

class FoodTipsDialog extends StatefulWidget {
  final String foodName;

  const FoodTipsDialog({super.key, required this.foodName});

  @override
  State<FoodTipsDialog> createState() => _FoodTipsDialogState();
}

class _FoodTipsDialogState extends State<FoodTipsDialog> {
  late final FoodTipsService _foodTipsService;
  String? _tips;
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
      if (mounted) {
        setState(() {
          _tips = tips;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
            // Prüfhinweise für Haltbarkeit
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ist es noch gut?',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getQualityCheckTips(widget.foodName),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Haltbarkeit nach MHD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Haltbarkeit nach MHD',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getExpiryExtensionInfo(widget.foodName),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.orange.shade800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Lagertipps
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
                      Icon(
                        Icons.kitchen,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lagertipps',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Text(
                          _tips ?? _getDefaultTips(widget.foodName),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
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

  String _getQualityCheckTips(String foodName) {
    final name = foodName.toLowerCase();

    if (name.contains('apfel') || name.contains('äpfel')) {
      return '• Aussehen: Keine Schimmelstellen, braune Stellen sind meist unbedenklich\n• Geruch: Frisch und fruchtig, nicht gärig\n• Konsistenz: Fest, nicht matschig\n• Geschmack: Süß-säuerlich, nicht vergoren';
    } else if (name.contains('brot')) {
      return '• Aussehen: Kein sichtbarer Schimmel (bei Schimmel ganzes Brot entsorgen!)\n• Geruch: Neutral bis leicht hefig, nicht muffig\n• Konsistenz: Kann hart sein, aber noch genießbar\n• Tipp: Hartes Brot kann zu Semmelbröseln verarbeitet werden';
    } else if (name.contains('milch')) {
      return '• Aussehen: Keine Klumpen oder Flocken\n• Geruch: Neutral bis leicht süßlich, nicht sauer\n• Konsistenz: Flüssig, nicht dickflüssig\n• Test: Kleine Menge probieren - säuerlicher Geschmack = entsorgen';
    } else if (name.contains('banane')) {
      return '• Aussehen: Braune Flecken sind normal und zeigen Reife\n• Geruch: Süß und fruchtig, nicht alkoholisch\n• Konsistenz: Weich ist okay, matschig vermeiden\n• Tipp: Überreife Bananen perfekt für Smoothies oder Bananenbrot';
    } else if (name.contains('tomate')) {
      return '• Aussehen: Keine Schimmelstellen, runzelige Haut ist oft noch okay\n• Geruch: Frisch und aromatisch\n• Konsistenz: Weich ist okay für Soßen, nicht matschig\n• Drucktest: Sollte auf Druck leicht nachgeben';
    } else if (name.contains('salat') || name.contains('kopfsalat')) {
      return '• Aussehen: Keine schleimigen oder schwarzen Stellen\n• Blätter: Welke Außenblätter entfernen, Innere oft noch gut\n• Konsistenz: Knackig bis leicht welk ist essbar\n• Geruch: Frisch, nicht faulig';
    } else if (name.contains('kartoffel')) {
      return '• Aussehen: Grüne Stellen und Keime entfernen\n• Konsistenz: Fest, keine weichen Stellen\n• Schale: Runzelig ist okay, schimmelig nicht\n• Wichtig: Stark gekeimte oder grüne Kartoffeln nicht verwenden';
    } else if (name.contains('fleisch') || name.contains('wurst')) {
      return '• Farbe: Keine grauen oder grünlichen Verfärbungen\n• Geruch: Neutral bis leicht fleischig, NICHT süßlich oder faulig\n• Oberfläche: Nicht schmierig oder klebrig\n• Bei Zweifeln: Lieber entsorgen - Gesundheitsrisiko!';
    } else if (name.contains('käse')) {
      return '• Schimmel: Bei Hartkäse großzügig wegschneiden möglich\n• Weichkäse: Bei Schimmel komplett entsorgen\n• Geruch: Typischer Käsegeruch, nicht ammoniakartig\n• Konsistenz: Keine untypische Schmierigkeit';
    } else if (name.contains('joghurt') || name.contains('yoghurt')) {
      return '• Deckel: Nicht gewölbt (Gärung)\n• Konsistenz: Keine Trennung von Molke normal\n• Geruch: Mild säuerlich, nicht stark sauer\n• Schimmel: Bei kleinsten Spuren komplett entsorgen';
    } else if (name.contains('ei')) {
      return '• Wassertest: Sinkt = frisch, schwimmt = alt (aber oft noch gut)\n• Aufschlagen: Eigelb gewölbt = frisch, flach = älter\n• Geruch: Neutral, faule Eier riechen stark schwefelartig\n• Eiklar: Klar und zähflüssig = frisch';
    } else {
      return '• Aussehen: Keine Schimmelbildung oder Verfärbungen\n• Geruch: Typisch für das Produkt, nicht sauer oder faulig\n• Konsistenz: Keine untypischen Veränderungen\n• Bei Zweifeln: Kleine Menge probieren oder entsorgen';
    }
  }

  String _getExpiryExtensionInfo(String foodName) {
    final name = foodName.toLowerCase();

    if (name.contains('apfel') || name.contains('äpfel')) {
      return 'Oft noch 1-2 Wochen nach MHD genießbar, wenn kühl gelagert. Schrumpelige Äpfel sind meist noch gut.';
    } else if (name.contains('brot')) {
      return 'Unverpackt: 2-3 Tage nach MHD\nVerpackt: bis zu 1 Woche nach MHD\nBei Schimmel sofort komplett entsorgen!';
    } else if (name.contains('milch')) {
      return 'Ungeöffnet: 2-3 Tage nach MHD\nH-Milch: bis zu 1 Woche nach MHD\nGeöffnet: innerhalb 3-4 Tagen verbrauchen';
    } else if (name.contains('banane')) {
      return 'Kein MHD - Reife selbst bestimmen. Braune Bananen oft noch 2-3 Tage essbar. Ideal für Backwaren wenn überreif.';
    } else if (name.contains('tomate')) {
      return 'Noch 3-5 Tage nach optimaler Reife verwendbar. Weiche Tomaten perfekt für Soßen und Suppen.';
    } else if (name.contains('salat') || name.contains('kopfsalat')) {
      return 'Nach MHD noch 1-2 Tage, wenn Blätter nicht schleimig. Äußere Blätter entfernen verlängert Haltbarkeit.';
    } else if (name.contains('kartoffel')) {
      return 'Mehrere Wochen bis Monate haltbar bei richtiger Lagerung. Keime und grüne Stellen entfernen.';
    } else if (name.contains('fleisch') || name.contains('wurst')) {
      return 'Verbrauchsdatum STRIKT einhalten!\nVerpackte Wurst: maximal 1-2 Tage nach MHD\nFrisches Fleisch: NICHT nach Verbrauchsdatum!';
    } else if (name.contains('käse')) {
      return 'Hartkäse: 2-3 Wochen nach MHD\nWeichkäse: 3-5 Tage nach MHD\nFrischkäse: maximal 2-3 Tage nach MHD';
    } else if (name.contains('joghurt') || name.contains('yoghurt')) {
      return 'Ungeöffnet: oft 1-2 Wochen nach MHD\nGeöffnet: innerhalb 3-4 Tagen\nNaturjoghurt hält länger als Fruchtjoghurt';
    } else if (name.contains('ei')) {
      return 'Noch 2-3 Wochen nach MHD verwendbar\nDurcherhitzen ab 2 Wochen nach MHD empfohlen\nWassertest zur Frischeprüfung nutzen';
    } else if (name.contains('nudel') || name.contains('pasta')) {
      return 'Trockene Nudeln: Mehrere Monate bis Jahre nach MHD\nFrische Nudeln: maximal 3-4 Tage nach MHD';
    } else if (name.contains('reis')) {
      return 'Ungekocht: Jahre nach MHD haltbar bei trockener Lagerung\nGekocht: maximal 1-2 Tage im Kühlschrank';
    } else if (name.contains('mehl')) {
      return 'Mehrere Monate nach MHD verwendbar\nVollkornmehl: kürzer haltbar (3-6 Monate)\nAuf Schädlinge und ranzigen Geruch achten';
    } else {
      return 'MHD ist kein Verfallsdatum!\nViele Produkte sind Tage bis Wochen darüber hinaus genießbar.\nVertrauen Sie Ihren Sinnen: Sehen, Riechen, Schmecken.';
    }
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
}
