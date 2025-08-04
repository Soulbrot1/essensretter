import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_bloc.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_event.dart';
import 'package:essensretter/features/food_tracking/presentation/bloc/food_state.dart';
import 'package:essensretter/features/food_tracking/presentation/widgets/food_card.dart';

class MockFoodBloc extends MockBloc<FoodEvent, FoodState> implements FoodBloc {}

void main() {
  late MockFoodBloc mockFoodBloc;

  setUp(() {
    mockFoodBloc = MockFoodBloc();
    registerFallbackValue(LoadFoodsEvent());
  });

  Widget makeTestableWidget(Widget child) {
    return MaterialApp(
      home: BlocProvider<FoodBloc>.value(
        value: mockFoodBloc,
        child: Scaffold(body: child),
      ),
    );
  }

  group('FoodCard Basic Tests', () {
    final testFood = Food(
      id: 'test-id',
      name: 'Test Milch',
      expiryDate: DateTime.now().add(const Duration(days: 2)),
      addedDate: DateTime.now().subtract(const Duration(days: 1)),
    );

    testWidgets('should render without crashing', (tester) async {
      // arrange
      when(() => mockFoodBloc.state).thenReturn(FoodInitial());

      // act
      await tester.pumpWidget(makeTestableWidget(FoodCard(food: testFood)));

      // assert
      expect(find.byType(FoodCard), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should display food name', (tester) async {
      // arrange
      when(() => mockFoodBloc.state).thenReturn(FoodInitial());

      // act
      await tester.pumpWidget(makeTestableWidget(FoodCard(food: testFood)));

      // assert
      expect(find.text('Test Milch'), findsOneWidget);
    });

    testWidgets('should be tappable', (tester) async {
      // arrange
      when(() => mockFoodBloc.state).thenReturn(FoodInitial());

      // act
      await tester.pumpWidget(makeTestableWidget(FoodCard(food: testFood)));
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      // assert - just ensure no exception was thrown
      expect(find.byType(FoodCard), findsOneWidget);
    });
  });

  group('Food Entity Tests', () {
    test('should calculate days until expiry correctly', () {
      // arrange
      final food = Food(
        id: 'test',
        name: 'Test Food',
        expiryDate: DateTime.now().add(const Duration(days: 3)),
        addedDate: DateTime.now(),
      );

      // act & assert
      expect(food.daysUntilExpiry, 3);
    });

    test('should return correct expiry status for today', () {
      // arrange
      final food = Food(
        id: 'test',
        name: 'Test Food',
        expiryDate: DateTime.now(),
        addedDate: DateTime.now(),
      );

      // act & assert
      expect(food.expiryStatus, 'heute');
    });

    test('should return correct expiry status for tomorrow', () {
      // arrange
      final food = Food(
        id: 'test',
        name: 'Test Food',
        expiryDate: DateTime.now().add(const Duration(days: 1)),
        addedDate: DateTime.now(),
      );

      // act & assert
      expect(food.expiryStatus, 'Morgen');
    });

    test('should return correct expiry status for multiple days', () {
      // arrange
      final food = Food(
        id: 'test',
        name: 'Test Food',
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        addedDate: DateTime.now(),
      );

      // act & assert
      expect(food.expiryStatus, '5 Tage');
    });

    test('should detect expired food correctly', () {
      // arrange
      final food = Food(
        id: 'test',
        name: 'Test Food',
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
        addedDate: DateTime.now(),
      );

      // act & assert
      expect(food.isExpired, true);
      expect(food.expiryStatus, 'vor 1 Tag');
    });
  });
}