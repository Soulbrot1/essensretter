import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:essensretter/features/sharing/presentation/pages/friends_page.dart';

/// Smoke Test für FriendsPage
///
/// Dieser Test prüft nur das absolute Minimum:
/// - Kann die Seite ohne Crash erstellt werden?
/// - Rendert sie grundsätzlich?
///
/// NICHT getestet (absichtlich):
/// - Konkrete UI-Details
/// - Friend-Liste laden
/// - Interaktionen
///
/// Zweck: Schutz vor Refactoring-Fehlern, die zu Crashes führen
void main() {
  group('FriendsPage Smoke Tests', () {
    testWidgets('rendert ohne Crash', (tester) async {
      // Minimal Setup - nur prüfen, ob es überhaupt rendert
      await tester.pumpWidget(const MaterialApp(home: FriendsPage()));

      // Ersten Frame warten (State initialisiert sich)
      await tester.pump();

      // Wenn wir hier ankommen, ist kein Crash passiert ✅
      expect(find.byType(FriendsPage), findsOneWidget);
    });

    testWidgets('zeigt grundlegende UI-Struktur', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FriendsPage()));

      await tester.pump();

      // Prüfe, dass grundlegende Struktur da ist (Scaffold, AppBar)
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('kann navigiert werden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FriendsPage()),
                  );
                },
                child: const Text('Open Friends'),
              ),
            ),
          ),
        ),
      );

      // Navigate zur FriendsPage
      await tester.tap(find.text('Open Friends'));
      await tester.pump(); // Start navigation
      await tester.pump(const Duration(milliseconds: 300)); // Animation

      // Prüfen, dass Navigation funktioniert hat
      expect(find.byType(FriendsPage), findsOneWidget);
    });
  });
}
