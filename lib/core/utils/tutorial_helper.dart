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
  static final GlobalKey filterKey = GlobalKey();
  static final GlobalKey recipeButtonKey = GlobalKey();
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
            align: ContentAlign.top,
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
            align: ContentAlign.top,
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
            align: ContentAlign.bottom,
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
                      'zu markieren.\n\n'
                      'Es wird dann durchgestrichen\n'
                      'und in der Statistik als\n'
                      'verbraucht erfasst.',
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
            align: ContentAlign.top,
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