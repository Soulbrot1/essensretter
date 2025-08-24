# CLAUDE.md - Claude Code Projekt-Kontext

## Projekt-Übersicht

EssensRetter ist eine Flutter-App zur Reduzierung von Lebensmittelverschwendung durch intelligentes Tracking der Haltbarkeit von Lebensmitteln.

## Wichtige Befehle

```bash
# App starten (iOS Simulator)
flutter run

# Tests ausführen (PFLICHT vor jedem Commit)
flutter test

# Tests mit Coverage
flutter test --coverage

# Coverage Report generieren
./scripts/coverage-report.sh

# Spezifische Test-Suites
flutter test test/unit_test/        # Unit Tests
flutter test test/widget_test/      # Widget Tests
flutter test test/features/         # Feature Tests
flutter test integration_test/      # Integration Tests

# Pre-Commit Hook manuell ausführen
./scripts/flutter-pre-commit.sh

# Code-Analyse (PFLICHT vor jedem Commit)
flutter analyze

# Dependencies aktualisieren
flutter pub get

# Code-Formatierung
dart format lib/ test/

# iOS-spezifisch bauen
flutter build ios

# Web-Version bauen
flutter build web
```

## Architektur-Prinzipien

### Clean Architecture
Die App folgt strikt Clean Architecture mit drei Schichten:
1. **Presentation Layer**: UI, Widgets, State Management (BLoC)
2. **Domain Layer**: Business Logic, Entities, Use Cases
3. **Data Layer**: Repositories, Data Sources, Models

### Feature-basierte Struktur
Jedes Feature ist eigenständig in `/lib/features/[feature_name]/` organisiert.

## Coding-Standards

### Dart/Flutter Konventionen
- Verwende `lowerCamelCase` für Variablen und Funktionen
- Verwende `UpperCamelCase` für Klassen und Typen
- Dateien in `snake_case` benennen
- Privat Variablen/Methoden mit `_` prefix

### Import-Reihenfolge
1. Dart imports
2. Flutter imports
3. Package imports
4. Relative imports (features)
5. Relative imports (core)

## KI-Integration

Die App nutzt KI für:
1. **Text-zu-Lebensmittel Parsing**: Extrahiert Lebensmittel und Haltbarkeitsdaten aus Fließtext
2. **Rezeptvorschläge**: Generiert Rezepte basierend auf vorhandenen Lebensmitteln

## Datenbank-Schema

### Food Entity
```dart
class Food {
  final String id;
  final String name;
  final DateTime expiryDate;
  final DateTime addedDate;
  final String? category;
  final String? notes;
}
```

## State Management

Wir verwenden BLoC (Business Logic Component) für State Management:
- Jedes Feature hat eigene BLoCs
- Events triggern State-Änderungen
- UI reagiert auf State-Änderungen

## Testing-Strategie (PFLICHT)

### Test-First Development (TDD)
1. **RED**: Test schreiben (schlägt fehl)
2. **GREEN**: Minimale Implementation (Test erfolgreich)
3. **REFACTOR**: Code verbessern, Tests behalten

### Test-Kategorien (alle PFLICHT)

#### 1. Unit Tests (test/unit_test/)
- **Ziel**: Use Cases, Repositories, Utils testen
- **Framework**: mocktail für Mocking
- **Coverage**: >90% für Business Logic
- **Beispiel**: `test/unit_test/features/food_tracking/domain/usecases/get_all_foods_test.dart`

#### 2. Widget Tests (test/widget_test/)
- **Ziel**: UI-Komponenten isoliert testen
- **Framework**: flutter_test + Widgettester
- **Coverage**: Alle kritischen Widgets
- **Beispiel**: `test/widget_test/food_card_test.dart`

#### 3. BLoC Tests (test/unit_test/)
- **Ziel**: State Management testen
- **Framework**: bloc_test
- **Coverage**: Alle Events und States
- **Beispiel**: `test/unit_test/features/food_tracking/presentation/bloc/food_bloc_test.dart`

#### 4. Integration Tests (integration_test/)
- **Ziel**: Komplette User Flows Ende-zu-Ende
- **Framework**: integration_test
- **Coverage**: Kritische Workflows
- **Beispiel**: Lebensmittel hinzufügen → Anzeigen → Löschen

### Test-Regeln (ZWINGEND)
- **Jede neue Funktion**: Braucht Tests vor Implementation
- **Jeder Bug-Fix**: Braucht Test, der den Bug reproduziert
- **Code Coverage**: Minimum 80% Overall, 90% für Domain Layer
- **Tests laufen**: Bei jedem Commit (automatisch via Pre-Commit Hook)
- **CI/CD Pipeline**: GitHub Actions führt Tests bei jedem Push aus

### Test-Integration im Entwicklungsprozess

#### Automatische Checks (Pre-Commit)
Der Pre-Commit Hook führt automatisch folgende Checks aus:
1. Code-Formatierung (`dart format`)
2. Static Analysis (`flutter analyze`)
3. Alle Tests (`flutter test`)
4. Coverage-Check (minimum 80%)
5. Print-Statement Check

#### Test-Helper und Utilities
- **Test Helper**: `test/helpers/test_helper.dart` - Widget-Wrapper, Custom Matchers
- **Mock Factory**: `test/helpers/mock_factory.dart` - Zentrale Mock-Erstellung
- **Fixtures**: `test/fixtures/` - Vordefinierte Test-Daten

#### Coverage Monitoring
```bash
# Coverage Report mit Details generieren
./scripts/coverage-report.sh

# Coverage Badge für README
# Automatisch generiert bei CI/CD Runs
```

#### GitHub Actions CI/CD
- **Trigger**: Bei Push auf main/develop und Pull Requests
- **Jobs**: Test, Analyze, Coverage Report, Build (iOS/Android)
- **Coverage Upload**: Automatisch zu Codecov

## Wichtige Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.0      # State Management
  get_it: ^7.6.0           # Dependency Injection
  sqflite: ^2.3.0          # Lokale Datenbank
  speech_to_text: ^6.3.0   # Spracheingabe
  intl: ^0.18.0            # Datum-Formatierung
```

## Entwicklungs-Workflow (ZWINGEND)

### Für jede neue Funktion:
1. **Branch erstellen**: `git checkout -b feature/neue-funktion`
2. **Tests schreiben**: TDD befolgen - Tests zuerst!
3. **Implementation**: Clean Architecture befolgen
4. **Tests ausführen**: `flutter test` (muss erfolgreich sein)
5. **Code-Analyse**: `flutter analyze` (keine Warnings)
6. **Formatierung**: `dart format lib/ test/`
7. **Dokumentation**: README.md bei größeren Änderungen aktualisieren
8. **Commit**: Mit aussagekräftiger Commit-Message
9. **Pull Request**: Mit Tests und Beschreibung

### Pre-Commit Checklist (PFLICHT):
- [ ] `flutter test` erfolgreich
- [ ] `flutter analyze` ohne Warnings  
- [ ] Code formatiert (`dart format`)
- [ ] Neue Tests geschrieben
- [ ] Dokumentation aktualisiert (wenn nötig)

### Quality Gates:
- **Tests**: Minimum 80% Coverage
- **Linting**: Keine flutter_lints Violations
- **Architektur**: Clean Architecture befolgt
- **Performance**: Keine Memory Leaks

## Häufige Aufgaben

### Neues Feature hinzufügen
1. Feature-Ordner unter `/lib/features/` erstellen
2. Domain Layer zuerst (Entities, Use Cases)
3. Data Layer implementieren
4. Presentation Layer mit BLoC aufbauen

### Neues Lebensmittel-Attribut
1. Food Entity erweitern
2. Datenbank-Migration schreiben
3. UI anpassen

## Debugging-Tipps

- Flutter Inspector für UI-Debugging nutzen
- `print()` statements in Development, entfernen vor Release
- BLoC Observer für State-Debugging implementieren

## Performance-Optimierung

- Lazy Loading für Lebensmittel-Listen
- Caching für häufig genutzte Daten
- Debouncing bei Texteingabe