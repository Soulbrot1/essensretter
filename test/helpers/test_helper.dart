import 'package:essensretter/features/food_tracking/domain/entities/food.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

/// Test Helper für EssensRetter App Tests
/// Enthält häufig genutzte Test-Utilities und Helper-Funktionen

// Registriere GetIt für Tests
final testGetIt = GetIt.instance;

/// Setup für Tests - sollte in setUpAll() aufgerufen werden
void setupTestDependencies() {
  if (!testGetIt.isRegistered<GetIt>()) {
    // Registriere Test-Dependencies hier
  }
}

/// Cleanup für Tests - sollte in tearDownAll() aufgerufen werden
void cleanupTestDependencies() {
  testGetIt.reset();
}

/// Widget Wrapper für Tests mit allen notwendigen Providern
class TestWidgetWrapper extends StatelessWidget {
  final Widget child;
  final List<BlocProvider> providers;
  final ThemeData? theme;

  const TestWidgetWrapper({
    Key? key,
    required this.child,
    this.providers = const [],
    this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget app = MaterialApp(
      theme: theme ?? ThemeData(),
      home: Scaffold(body: child),
    );

    if (providers.isNotEmpty) {
      app = MultiBlocProvider(providers: providers, child: app);
    }

    return app;
  }
}

/// Helper zum Pumpen von Widgets in Tests
extension WidgetTesterExtension on WidgetTester {
  /// Pumpt ein Widget mit allen notwendigen Wrappern
  Future<void> pumpTestWidget(
    Widget widget, {
    List<BlocProvider> providers = const [],
    ThemeData? theme,
  }) async {
    await pumpWidget(
      TestWidgetWrapper(child: widget, providers: providers, theme: theme),
    );
  }

  /// Pumpt und settled (wartet auf Animationen)
  Future<void> pumpAndSettleTestWidget(
    Widget widget, {
    List<BlocProvider> providers = const [],
    ThemeData? theme,
  }) async {
    await pumpTestWidget(widget, providers: providers, theme: theme);
    await pumpAndSettle();
  }
}

/// Test Matcher für Custom Assertions
class FoodMatcher extends Matcher {
  final String? name;
  final DateTime? expiryDate;

  FoodMatcher({this.name, this.expiryDate});

  @override
  bool matches(item, Map matchState) {
    if (item is! Food) return false;

    if (name != null && item.name != name) return false;
    if (expiryDate != null && item.expiryDate != expiryDate) return false;

    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('Food with name=$name, expiryDate=$expiryDate');
  }
}

/// Factory für Food Matcher
Matcher isFood({String? name, DateTime? expiryDate}) {
  return FoodMatcher(name: name, expiryDate: expiryDate);
}

/// Helper zum Finden von Widgets nach Key
Finder findByKey(String key) => find.byKey(Key(key));

/// Helper zum Finden von Text
Finder findText(String text) => find.text(text);

/// Helper zum Simulieren von Swipe-Gesten
Future<void> swipeToDelete(WidgetTester tester, Finder finder) async {
  await tester.drag(finder, const Offset(-500.0, 0.0));
  await tester.pumpAndSettle();
}

/// Helper zum Simulieren von Tap-Gesten
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
