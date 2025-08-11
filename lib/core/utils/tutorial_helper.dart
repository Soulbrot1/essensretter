import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialHelper {
  static const String _tutorialShownKey = 'tutorial_shown';
  
  // Global Keys für UI-Elemente
  static final GlobalKey addButtonKey = GlobalKey();
  static final GlobalKey foodListKey = GlobalKey();
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
      
      // Schritt 2: Filter
      if (filterKey.currentContext != null)
      TargetFocus(
        identify: "filter",
        keyTarget: filterKey,
        shape: ShapeLightFocus.RRect,
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
                      'Filter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Filtere deine Lebensmittel nach Ablaufdatum:\n'
                      '🔴 Abgelaufen\n'
                      '🟡 Diese Woche\n'
                      '🟢 Später',
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
      
      // Schritt 3: Rezepte
      TargetFocus(
        identify: "recipes",
        keyTarget: recipeButtonKey,
        shape: ShapeLightFocus.Circle,
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
                      'KI-Rezeptvorschläge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Lass dir von der KI Rezepte vorschlagen,\n'
                      'basierend auf deinen Lebensmitteln!',
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