import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:essensretter/features/sharing/presentation/widgets/offered_foods_bottom_sheet.dart';

/// Smoke Test für OfferedFoodsBottomSheet
///
/// Dieser Test prüft nur das absolute Minimum:
/// - Kann das Widget ohne Crash erstellt werden?
/// - Rendert es grundsätzlich?
///
/// NICHT getestet (absichtlich):
/// - Konkrete UI-Details
/// - Interaktionen
/// - Business Logic
///
/// Zweck: Schutz vor Refactoring-Fehlern, die zu Crashes führen
void main() {
  group('OfferedFoodsBottomSheet Smoke Tests', () {
    testWidgets('rendert ohne Crash', (tester) async {
      // Minimal Setup - nur prüfen, ob es überhaupt rendert
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OfferedFoodsBottomSheet())),
      );

      // Wenn wir hier ankommen, ist kein Crash passiert ✅
      expect(find.byType(OfferedFoodsBottomSheet), findsOneWidget);
    });

    testWidgets('kann geöffnet werden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => const OfferedFoodsBottomSheet(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Bottom Sheet öffnen
      await tester.tap(find.text('Open'));
      await tester.pump(); // Nur ein Frame, kein pumpAndSettle
      await tester.pump(const Duration(milliseconds: 300)); // Animation Frame

      // Prüfen, dass es geöffnet wurde
      expect(find.byType(OfferedFoodsBottomSheet), findsOneWidget);
    });
  });
}
