# CLAUDE.md - Claude Code Projekt-Kontext

## Projekt-Übersicht

EssensRetter ist eine Flutter-App zur Reduzierung von Lebensmittelverschwendung durch intelligentes Tracking der Haltbarkeit von Lebensmitteln.

## Wichtige Befehle

```bash
# App starten (iOS Simulator)
flutter run

# Tests ausführen
flutter test

# Code-Analyse
flutter analyze

# Dependencies aktualisieren
flutter pub get

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

## Testing-Strategie

1. **Unit Tests**: Für Use Cases und Repositories
2. **Widget Tests**: Für UI-Komponenten
3. **Integration Tests**: Für komplette User Flows

## Wichtige Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.0      # State Management
  get_it: ^7.6.0           # Dependency Injection
  sqflite: ^2.3.0          # Lokale Datenbank
  speech_to_text: ^6.3.0   # Spracheingabe
  intl: ^0.18.0            # Datum-Formatierung
```

## Entwicklungs-Workflow

1. Neue Features immer in eigenem Branch entwickeln
2. Clean Architecture befolgen
3. Tests für neue Funktionalität schreiben
4. Code mit `flutter analyze` prüfen
5. README.md bei größeren Änderungen aktualisieren

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