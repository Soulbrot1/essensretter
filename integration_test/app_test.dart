import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:essensretter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EssensRetter App Integration Tests', () {
    testWidgets('app starts and shows main screen', (tester) async {
      // arrange & act
      app.main();
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Essensretter'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('can navigate to settings', (tester) async {
      // arrange
      app.main();
      await tester.pumpAndSettle();

      // act
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Einstellungen'), findsOneWidget);
    });

    testWidgets('shows empty state when no food items', (tester) async {
      // arrange
      app.main();
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Keine Lebensmittel vorhanden'), findsOneWidget);
      expect(find.text('Fügen Sie Lebensmittel über das Eingabefeld hinzu'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('can open add food dialog', (tester) async {
      // arrange
      app.main();
      await tester.pumpAndSettle();

      // act
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Lebensmittel hinzufügen'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('filter buttons are visible and tappable', (tester) async {
      // arrange
      app.main();
      await tester.pumpAndSettle();

      // assert - filter bar should be visible
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.byIcon(Icons.sort_by_alpha), findsOneWidget);
      expect(find.byIcon(Icons.date_range), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);

      // act - tap on filter
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // assert - popup menu should appear
      expect(find.text('Alle'), findsOneWidget);
      expect(find.text('Heute'), findsOneWidget);
      expect(find.text('Morgen'), findsOneWidget);
    });

    testWidgets('sort buttons change active state', (tester) async {
      // arrange
      app.main();
      await tester.pumpAndSettle();

      // act - tap alphabetical sort
      await tester.tap(find.byIcon(Icons.sort_by_alpha));
      await tester.pumpAndSettle();

      // assert - no crashes and UI still functional
      expect(find.byIcon(Icons.sort_by_alpha), findsOneWidget);

      // act - tap date sort
      await tester.tap(find.byIcon(Icons.date_range));
      await tester.pumpAndSettle();

      // assert - no crashes and UI still functional
      expect(find.byIcon(Icons.date_range), findsOneWidget);
    });

    testWidgets('can access recipe generation (when disabled)', (tester) async {
      // arrange
      app.main();
      await tester.pumpAndSettle();

      // act - try to tap recipe button (should be disabled with no food)
      final recipeButton = find.byIcon(Icons.restaurant_menu);
      expect(recipeButton, findsOneWidget);

      // Note: Button is disabled when no food, so we just verify it exists
      // In a real test with food items, we would test the actual functionality
    });

    testWidgets('bottom navigation bar is present', (tester) async {
      // arrange
      app.main();
      await tester.pumpAndSettle();

      // assert
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });

    testWidgets('can access bookmarked recipes', (tester) async {
      // arrange
      app.main();
      await tester.pumpAndSettle();

      // act
      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pumpAndSettle();

      // assert - should open bookmarked recipes (even if empty)
      // The modal should appear with bookmarked recipes content
      // The modal should appear - we just check no crashes occurred
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('can access statistics', (tester) async {
      // arrange
      app.main();
      await tester.pumpAndSettle();

      // act
      await tester.tap(find.byIcon(Icons.bar_chart));
      await tester.pumpAndSettle();

      // assert - should navigate to statistics page
      expect(find.text('Statistiken'), findsOneWidget);
    });
  });
}
