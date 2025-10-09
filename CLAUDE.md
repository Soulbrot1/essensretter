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

### Aktueller Entwicklungsstand (Stand: Januar 2025)

**Test Coverage (Testabdeckung - wie viel Code durch Tests geprüft wird):**
- Aktuell: 22.5% (901 von 4,001 Zeilen getestet)
- Ziel: 22-25% (pragmatisch - Fokus auf wichtige Komponenten)
- Langfristziel: 30-35% (wenn alle kritischen Use Cases getestet)
- Fokus: Kernfunktion Food-Tracking (Lebensmittel verwalten) wird priorisiert
- Tests gesamt: 222 Tests (Use Cases, Repositories, Helper, Models, Entities)

**Abgeschlossene Refactorings (Code-Umstrukturierungen für bessere Lesbarkeit):**
- offered_foods_bottom_sheet.dart: 761 → 265 Zeilen (-65%)
- food_bloc.dart: 738 → 595 Zeilen (-19%)
- friends_page.dart: 729 → 386 Zeilen (-47%)
- Extrahiert: 4 Helper-Klassen (Hilfsklassen für wiederverwendbare Logik), 6 Widget-Komponenten (UI-Bausteine)

**Dependencies (externe Bibliotheken):**
- Letzte große Updates: Januar 2025 (33 Pakete aktualisiert)
- flutter_bloc: 8.1.6 → 9.1.1
- flutter_local_notifications: 17.2.1 → 19.4.2
- get_it: 7.7.0 → 8.2.0

## Coding-Standards

### Verständliche Dokumentation
- **Fachbegriffe erklären**: Immer in einfacher Sprache in Klammern dahinter
- **Beispiel**: "Dependency Injection (automatisches Bereitstellen von Abhängigkeiten)" statt nur "Dependency Injection"
- **Zielgruppe**: Auch Laien sollen MD-Dateien verstehen können

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

Wir verwenden BLoC (Business Logic Component - Trennung von Anzeige und Logik) für State Management:
- Jedes Feature hat eigene BLoCs
- Events (Ereignisse) triggern State-Änderungen (Zustandsänderungen)
- UI reagiert auf State-Änderungen

## Architektur-Erkenntnisse & Best Practices

### Was funktioniert gut:
- **Helper-Klassen extrahieren**: Reduziert Code-Duplizierung (denselben Code mehrfach schreiben)
  - Beispiele: food_filter_helper.dart, food_sorting_helper.dart
- **Widget-Komposition (UI-Bausteine zusammensetzen)**: Große Widgets in kleinere aufteilen erhöht Wartbarkeit
  - Beispiel: friends_page.dart von 729 auf 386 Zeilen durch Extraktion von 6 Widgets
- **BLoC Pattern**: Klare Trennung von UI und Business-Logik

### Was schwer testbar ist:
- **Statische Service-Klassen (fest verdrahtete Dienste)**: Schwer durch Test-Doubles (Attrappen) zu ersetzen
  - Beispiel: FriendService mit statischem SupabaseClient
- **Verschachtelte Fluent APIs (verkettete Methoden-Aufrufe)**: Brauchen komplexes Mock-Setup (Testaufbau mit Attrappen)
  - Beispiel: `client.from('table').select().eq('id', value).maybeSingle()`
- **Mehrfach-Dependencies (viele Abhängigkeiten)**: Services die viele andere statische Services aufrufen

### Refactoring-Entscheidungen (wann Code umstrukturieren):
- **Dateigröße >600 Zeilen**: Sollte aufgeteilt werden (schlechte Wartbarkeit)
- **Dateigröße 400-600 Zeilen**: Einzelfall-Entscheidung (kann legitim komplex sein)
- **Code-Duplikation >3x**: Helper-Klasse extrahieren
- **Beispiele für legitime Komplexität**: food_local_data_source.dart (561 Zeilen) - viele ähnliche CRUD-Operationen (Create, Read, Update, Delete)

### Bessere Alternativen für neue Services:
**Vermeiden (schwer testbar):**
```dart
class FriendService {
  static SupabaseClient get client => ...
  static Future<bool> addFriend(...) async { ... }
}
```

**Bevorzugen (leicht testbar durch Dependency Injection):**
```dart
class FriendService {
  final SupabaseClient client;
  final UserIdentityService userService;

  FriendService({required this.client, required this.userService});
  Future<bool> addFriend(...) async { ... }
}
```

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
- **Jede neue Funktion**: Braucht Tests vor Implementation (wenn testbar und sinnvoll)
- **Jeder Bug-Fix**: Braucht Test, der den Bug reproduziert
- **Code Coverage**: Ziel 22-25% (aktuell 22.5%), Langfristziel 30-35%
- **Pragmatischer Ansatz**: Fokus auf kritische Business-Logik (Use Cases, Repositories, Helper), nicht auf schwer testbare Services oder UI-Code
- **Priorität**: Kernfunktion Food-Tracking (Lebensmittel verwalten) vor Sekundärfunktionen (Sharing, Rezepte, Statistiken)
- **Tests laufen**: Bei jedem Commit (automatisch via Pre-Commit Hook)
- **CI/CD Pipeline**: GitHub Actions führt Tests bei jedem Push aus

### Test-Integration im Entwicklungsprozess

#### Test-Strategie nach Komponenten-Typ:
- **Helper-Klassen & Utils**: Unit Tests (einfach, hoher ROI - Return on Investment/Nutzen)
  - Beispiele: food_filter_helper, food_sorting_helper
- **Repositories**: Unit Tests mit Mocks (Attrappen) - mittlerer Aufwand
  - Beispiel: food_repository_impl
- **Services mit externen Dependencies**: Integration Tests bevorzugen (Unit Tests zu aufwändig)
  - Beispiel: FriendService mit Supabase - besser via Integration Tests
- **BLoCs**: bloc_test Framework (bereits gute Coverage vorhanden)
- **Widgets**: Widget Tests für kritische UI-Komponenten

#### Automatische Checks (Pre-Commit)
Der Pre-Commit Hook führt automatisch folgende Checks aus:
1. Code-Formatierung (`dart format`)
2. Static Analysis (statische Code-Analyse mit `flutter analyze`)
3. Alle Tests (`flutter test`)
4. Coverage-Check (Testabdeckungs-Prüfung)
5. Print-Statement Check (keine Debug-Ausgaben im Production Code)

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

## Wichtige Dependencies (externe Bibliotheken)

```yaml
dependencies:
  flutter_bloc: ^9.1.1      # State Management (Zustandsverwaltung - trennt UI von Logik)
  get_it: ^8.2.0           # Dependency Injection (automatisches Bereitstellen von Abhängigkeiten)
  sqflite: ^2.3.0          # Lokale Datenbank (SQLite auf dem Gerät)
  speech_to_text: ^6.3.0   # Spracheingabe (Spracherkennung für Text-Input)
  intl: ^0.18.0            # Datum-Formatierung (internationale Datums-/Zahlenformate)
  supabase_flutter: ^2.7.3 # Backend-Dienst (für Freunde-Feature und Sharing)
  qr_flutter: ^4.1.0       # QR-Code Generierung (für User-ID teilen)
  mobile_scanner: ^3.5.5   # QR-Code Scanner (zum Scannen von Freunde-IDs)
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

### Quality Gates (Qualitätskriterien vor Merge):
- **Tests**: Kritische Business-Logik getestet (Coverage 22-25%, aktuell 22.5%)
- **Linting (Code-Prüfung)**: Keine flutter_lints Violations (Regelverstöße)
- **Architektur**: Clean Architecture befolgt (Drei-Schichten-Trennung)
- **Performance**: Keine Memory Leaks (Speicherlecks)
- **Error Tracking**: Crashlytics für Absturzberichte eingerichtet

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

- **Lazy Loading** (verzögertes Laden): Lebensmittel-Listen werden nach Bedarf nachgeladen
- **Caching** (Zwischenspeicherung): Häufig genutzte Daten werden im Speicher gehalten
- **Debouncing** (Verzögerung): Bei Texteingabe wird erst nach Pause gesucht (spart Ressourcen)