import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:essensretter/features/food_tracking/presentation/widgets/food_card.dart';
import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_bloc.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_event.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_state.dart';

// Mock BLoC
class MockFoodBloc extends Mock implements FoodBloc {}

void main() {
  late MockFoodBloc mockFoodBloc;

  setUp(() {
    mockFoodBloc = MockFoodBloc();
    // Default: BLoC gibt FoodLoaded State zurück
    when(
      () => mockFoodBloc.state,
    ).thenReturn(FoodLoaded(foods: [], filteredFoods: []));
    when(
      () => mockFoodBloc.stream,
    ).thenAnswer((_) => Stream.value(FoodLoaded(foods: [], filteredFoods: [])));
  });

  // Helper: Widget mit BLoC wrapper erstellen
  Widget createWidgetUnderTest(Food food) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<FoodBloc>.value(
          value: mockFoodBloc,
          child: FoodCard(food: food),
        ),
      ),
    );
  }

  group('FoodCard Widget Tests', () {
    testWidgets('rendert ohne Crash mit normalem Food', (tester) async {
      final food = Food(
        id: '1',
        name: 'Milch',
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        addedDate: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(food));

      expect(find.byType(FoodCard), findsOneWidget);
      expect(find.text('Milch'), findsOneWidget);
    });

    testWidgets('zeigt Food-Name korrekt an', (tester) async {
      final food = Food(
        id: '1',
        name: 'Apfel',
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        addedDate: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(food));

      expect(find.text('Apfel'), findsOneWidget);
    });

    testWidgets('zeigt Tage bis Ablauf korrekt an', (tester) async {
      final food = Food(
        id: '1',
        name: 'Brot',
        expiryDate: DateTime.now().add(const Duration(days: 7)),
        addedDate: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(food));

      // Suche nach "7" im Text
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('zeigt abgelaufene Lebensmittel mit negativen Tagen', (
      tester,
    ) async {
      final food = Food(
        id: '1',
        name: 'Alte Milch',
        expiryDate: DateTime.now().subtract(const Duration(days: 2)),
        addedDate: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(food));

      // Abgelaufen = negativ
      expect(find.text('-2'), findsOneWidget);
    });

    testWidgets('Checkbox ist sichtbar und nicht markiert bei neuem Food', (
      tester,
    ) async {
      final food = Food(
        id: '1',
        name: 'Käse',
        expiryDate: DateTime.now().add(const Duration(days: 10)),
        addedDate: DateTime.now(),
        isConsumed: false,
      );

      await tester.pumpWidget(createWidgetUnderTest(food));

      // Checkbox existiert (Circle Container)
      final checkbox = find.descendant(
        of: find.byType(GestureDetector).first,
        matching: find.byType(Container),
      );
      expect(checkbox, findsWidgets);

      // Kein Checkmark Icon, da nicht consumed
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('zeigt Checkmark wenn Food consumed ist', (tester) async {
      final food = Food(
        id: '1',
        name: 'Verzehrte Pizza',
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        addedDate: DateTime.now(),
        isConsumed: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(food));

      // Checkmark Icon sollte sichtbar sein
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('triggert ToggleConsumedEvent beim Checkbox-Click', (
      tester,
    ) async {
      final food = Food(
        id: '123',
        name: 'Joghurt',
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        addedDate: DateTime.now(),
        isConsumed: false,
      );

      await tester.pumpWidget(createWidgetUnderTest(food));

      // Finde Checkbox (erstes GestureDetector)
      final checkbox = find.byType(GestureDetector).first;

      // Klick auf Checkbox
      await tester.tap(checkbox);
      await tester.pump();

      // Verify: BLoC Event wurde gefeuert
      verify(() => mockFoodBloc.add(ToggleConsumedEvent('123'))).called(1);
    });

    testWidgets('zeigt Info-Button', (tester) async {
      final food = Food(
        id: '1',
        name: 'Banane',
        expiryDate: DateTime.now().add(const Duration(days: 4)),
        addedDate: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(food));

      // Info Icon sollte sichtbar sein
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('zeigt Share-Button', (tester) async {
      final food = Food(
        id: '1',
        name: 'Tomate',
        expiryDate: DateTime.now().add(const Duration(days: 6)),
        addedDate: DateTime.now(),
        isShared: false,
      );

      await tester.pumpWidget(createWidgetUnderTest(food));

      // Share Icon (outlined) sollte sichtbar sein
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });

    testWidgets('zeigt gefülltes Share-Icon wenn Food geteilt ist', (
      tester,
    ) async {
      final food = Food(
        id: '1',
        name: 'Geteiltes Brot',
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        addedDate: DateTime.now(),
        isShared: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(food));

      // Shared Icon sollte sichtbar sein
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('zeigt Delete-Button', (tester) async {
      final food = Food(
        id: '1',
        name: 'Gurke',
        expiryDate: DateTime.now().add(const Duration(days: 8)),
        addedDate: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(food));

      // Delete Icon sollte sichtbar sein
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('Food ohne Ablaufdatum wird korrekt behandelt', (tester) async {
      final food = Food(
        id: '1',
        name: 'Honig',
        expiryDate: null, // Kein Ablaufdatum
        addedDate: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(food));

      expect(find.text('Honig'), findsOneWidget);
      expect(find.byType(FoodCard), findsOneWidget);
    });
  });
}
