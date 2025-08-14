import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialHelper {
  static const String _tutorialShownKey = 'tutorial_shown';

  // Global Keys für UI-Elemente
  static final GlobalKey addButtonKey = GlobalKey();
  static final GlobalKey foodListKey = GlobalKey();
  static final GlobalKey foodCardKey = GlobalKey();
  static final GlobalKey categoryIconKey = GlobalKey();
  static final GlobalKey expiryDateKey = GlobalKey();
  static final GlobalKey infoButtonKey = GlobalKey();
  static final GlobalKey trashButtonKey = GlobalKey();
  static final GlobalKey filterBarKey = GlobalKey();
  static final GlobalKey recipeButtonKey = GlobalKey();
  static final GlobalKey bookmarkButtonKey = GlobalKey();
  static final GlobalKey statisticsButtonKey = GlobalKey();
  static final GlobalKey settingsKey = GlobalKey();

  static Future<bool> shouldShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_tutorialShownKey) ?? false);
  }

  static Future<void> markTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialShownKey, true);
  }

  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialShownKey, false);
  }

  static void showTutorial(BuildContext context) {
    // Zuerst das Willkommen-Popup anzeigen
    _showWelcomeDialog(context);
  }

  static void _showWelcomeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Willkommen bei Food Rescue!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'In Deutschland werfen private Haushalte jährlich 6,3 Millionen Tonnen Lebensmittel weg. 🗑️',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Das sind 75 kg pro Person im Jahr - im Wert von etwa 350 € pro Kopf! 💸',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Danke, dass du mit Food Rescue aktiv gegen Lebensmittelverschwendung kämpfst! 💚',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Text(
                'Diese App hilft dir dabei:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                '• Haltbarkeitsdaten zu verfolgen\n• Lebensmittel rechtzeitig zu verbrauchen\n• Rezepte für deine Zutaten zu finden\n• Verschwendung zu reduzieren',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 12),
              Text(
                'Lass uns gemeinsam einen Unterschied machen! 🌱',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                markTutorialShown();
              },
              child: const Text('Tutorial überspringen'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _startInteractiveTutorial(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tutorial starten'),
            ),
          ],
        );
      },
    );
  }

  static void _startInteractiveTutorial(BuildContext context) async {
    // Warten bis UI vollständig aufgebaut ist
    await Future.delayed(const Duration(milliseconds: 500));

    if (context.mounted) {
      TutorialCoachMark(
        targets: _createTargets(context),
        colorShadow: Colors.black87,
        paddingFocus: 10,
        opacityShadow: 0.85,
        hideSkip: false,
        onFinish: () {
          markTutorialShown();
        },
        onSkip: () {
          markTutorialShown();
          return true;
        },
      ).show(context: context);
    }
  }

  static List<TargetFocus> _createTargets(BuildContext context) {
    return [
      // Schritt 1: Hinzufügen Button
      TargetFocus(
        identify: "add_button",
        keyTarget: addButtonKey,
        shape: ShapeLightFocus.RRect,
        radius: 5,
        contents: [
          TargetContent(
            align: ContentAlign.custom,
            customPosition: CustomTargetContentPosition(
              top: MediaQuery.of(context).size.height * 0.4,
            ),
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Lebensmittel hinzufügen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tippe hier, um neue Lebensmittel hinzuzufügen.\n'
                      'Du kannst einfach eingeben:\n'
                      '"Milch morgen, Brot 3 Tage"',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => controller.next(),
                      child: const Text('Weiter'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // Schritt 2: Lebensmittelkarte (Kategorie-Symbol)
      if (foodCardKey.currentContext != null)
        TargetFocus(
          identify: "food_card",
          keyTarget: foodCardKey,
          shape: ShapeLightFocus.RRect,
          radius: 5,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: MediaQuery.of(context).size.height * 0.4,
              ),
              builder: (context, controller) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Lebensmittel verwalten',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Hier siehst du deine Lebensmittel\n'
                        'mit verschiedenen Aktionen:\n\n'
                        '• Kategorie-Symbol (links)\n'
                        '• Ablaufdatum (Mitte)\n'
                        '• Info & Mülleimer (rechts)',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => controller.next(),
                        child: const Text('Weiter'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),

      // Schritt 3: Kategorie-Symbol
      if (categoryIconKey.currentContext != null)
        TargetFocus(
          identify: "category_icon",
          keyTarget: categoryIconKey,
          shape: ShapeLightFocus.Circle,
          radius: 5,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: MediaQuery.of(context).size.height * 0.4,
              ),
              builder: (context, controller) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Als verbraucht markieren',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tippe auf das Kategorie-Symbol,\n'
                        'um ein Lebensmittel als verbraucht\n'
                        'zu markieren.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => controller.next(),
                        child: const Text('Weiter'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),

      // Schritt 4: Ablaufdatum
      if (expiryDateKey.currentContext != null)
        TargetFocus(
          identify: "expiry_date",
          keyTarget: expiryDateKey,
          shape: ShapeLightFocus.RRect,
          radius: 5,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: MediaQuery.of(context).size.height * 0.4,
              ),
              builder: (context, controller) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Haltbarkeitsdatum bearbeiten',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Hier wird angezeigt wie lange noch haltbar.\n\n'
                        'Durch das Draufdrücken können die Zeiten\n'
                        'bearbeitet werden, wenn sich was geändert hat\n'
                        'oder ein Lebensmittel angebrochen wurde.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => controller.next(),
                        child: const Text('Weiter'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),

      // Schritt 5: Info-Button für Haltbarkeitstipps
      if (infoButtonKey.currentContext != null)
        TargetFocus(
          identify: "info_button",
          keyTarget: infoButtonKey,
          shape: ShapeLightFocus.Circle,
          radius: 5,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: MediaQuery.of(context).size.height * 0.4,
              ),
              builder: (context, controller) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Haltbarkeitstipps',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tippe auf den Info-Button,\n'
                        'um nützliche Tipps zur\n'
                        'Haltbarkeit und Lagerung\n'
                        'des Lebensmittels zu erhalten.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => controller.next(),
                        child: const Text('Weiter'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),

      // Schritt 6: Mülleimer-Button
      if (trashButtonKey.currentContext != null)
        TargetFocus(
          identify: "trash_button",
          keyTarget: trashButtonKey,
          shape: ShapeLightFocus.Circle,
          radius: 5,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: MediaQuery.of(context).size.height * 0.4,
              ),
              builder: (context, controller) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Lebensmittel wegwerfen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tippe auf den Mülleimer,\n'
                        'um weggeschmissene Lebensmittel\n'
                        'zu löschen.\n\n'
                        'Diese werden dann in der\n'
                        'Statistik als verschwendet erfasst.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => controller.next(),
                        child: const Text('Weiter'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),

      // Schritt 7: Filterbar
      if (filterBarKey.currentContext != null)
        TargetFocus(
          identify: "filter_bar",
          keyTarget: filterBarKey,
          shape: ShapeLightFocus.RRect,
          radius: 5,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: MediaQuery.of(context).size.height * 0.4,
              ),
              builder: (context, controller) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Filter- und Sortieroptionen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Hier wird der Zeitraum angezeigt\n'
                        'für den Lebensmittel gelistet werden.\n\n'
                        'Du kannst verschiedene Sortier-\n'
                        'und Filterfunktionen nutzen:\n'
                        '• Nach Haltbarkeit\n'
                        '• Nach Kategorie\n'
                        '• Nur abgelaufene anzeigen',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => controller.next(),
                        child: const Text('Weiter'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),

      // Schritt 8: Rezept-Button
      if (recipeButtonKey.currentContext != null)
        TargetFocus(
          identify: "recipe_button",
          keyTarget: recipeButtonKey,
          shape: ShapeLightFocus.RRect,
          radius: 5,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: MediaQuery.of(context).size.height * 0.4,
              ),
              builder: (context, controller) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Rezepte generieren',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Hier kannst du Rezepte basierend\n'
                        'auf deinen vorhandenen Lebensmitteln\n'
                        'generieren lassen.\n\n'
                        'Die KI schlägt dir passende Rezepte vor,\n'
                        'um deine Zutaten optimal zu verwenden.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => controller.next(),
                        child: const Text('Weiter'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),

      // Schritt 9: Bookmark-Button
      if (bookmarkButtonKey.currentContext != null)
        TargetFocus(
          identify: "bookmark_button",
          keyTarget: bookmarkButtonKey,
          shape: ShapeLightFocus.RRect,
          radius: 5,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: MediaQuery.of(context).size.height * 0.4,
              ),
              builder: (context, controller) {
                return Container(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Gespeicherte Rezepte',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Hier findest du alle Rezepte,\n'
                        'die du als Favoriten markiert hast.\n\n'
                        'So hast du deine Lieblingsrezepte\n'
                        'immer schnell zur Hand.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => controller.next(),
                        child: const Text('Fertig'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
    ];
  }
}
