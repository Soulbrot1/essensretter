# EssensRetter 🥬🍎

Eine Flutter-App zur intelligenten Reduzierung von Lebensmittelverschwendung durch KI-gestütztes Tracking der Haltbarkeit von Lebensmitteln.

## 🎯 Überblick

EssensRetter hilft dir dabei, den Überblick über deine Lebensmittel zu behalten und rechtzeitig zu verbrauchen, bevor sie ablaufen. Die App nutzt künstliche Intelligenz, um aus deinen Texteingaben automatisch Lebensmittel zu erkennen und deren Haltbarkeit zu tracken.

## ✨ Hauptfunktionen

### 🧠 Intelligente Texteingabe
- **Fließtext-Eingabe**: Gib Lebensmittel in natürlicher Sprache ein
- **Spracheingabe**: Diktiere deine Lebensmittel per Mikrofon
- **KI-gestützte Erkennung**: Automatische Extraktion von Lebensmitteln und Haltbarkeitsdaten
- **Flexible Formate**: "Milch morgen", "Honig 5 Tage", "Salami 4.08" - alles wird verstanden

### 📋 Lebensmittel-Management
- **Übersichtliche Darstellung**: Alle erfassten Lebensmittel auf einen Blick
- **Smart Cards**: Visuelle Karten mit Haltbarkeitsanzeige und Farbkodierung
- **Status-Tracking**: Markiere Lebensmittel als verbraucht oder entsorgt
- **Batch-Operations**: Lösche alle verbrauchten Lebensmittel auf einmal

### 🔍 Intelligente Filterung & Sortierung
- **Zeitbasierte Filter**: Heute, Morgen, Übermorgen, 3-7 Tage
- **Sortieroptionen**: Nach Datum, alphabetisch oder Kategorie
- **Dynamische Updates**: Filter werden in Echtzeit angewendet
- **Visuelle Indikatoren**: Farbkodierte Haltbarkeitsstatus

### 👨‍🍳 KI-Rezeptgenerator
- **Automatische Rezeptvorschläge**: Basierend auf verfügbaren Lebensmitteln
- **Priorisierung**: Bevorzugt bald ablaufende Lebensmittel
- **Vielfältige Rezepte**: Von einfach bis komplex
- **Bookmark-System**: Speichere deine Lieblingsrezepte

### 📊 Statistiken & Insights
- **Verschwendungsstatistiken**: Verfolge deine Fortschritte
- **Trends**: Analysiere dein Verhalten über Zeit
- **Kategorien-Auswertung**: Welche Lebensmittel verschwendest du am meisten?

### ⚙️ Einstellungen & Personalisierung
- **Theme-Anpassung**: Helle und dunkle Modi
- **Benachrichtigungen**: Werde rechtzeitig an ablaufende Lebensmittel erinnert
- **Sprache**: Mehrsprachige Unterstützung
- **Backup & Sync**: Sichere deine Daten

## 🏗️ Technologie-Stack

- **Framework**: Flutter 3.24+ (iOS, Android, Web)
- **Architektur**: Clean Architecture mit 3-Schichten-Trennung
- **State Management**: BLoC Pattern (flutter_bloc 8.1.6)
- **Lokale Datenbank**: SQLite (sqflite 2.3.3+1)
- **KI-Integration**: OpenAI GPT für Text-zu-Lebensmittel Parsing
- **Dependency Injection**: GetIt mit Injectable
- **Testing**: bloc_test + mocktail für umfassende Tests

## 📁 Projekt-Struktur

```
lib/
├── main.dart                      # App-Einstiegspunkt
├── injection_container.dart       # Dependency Injection Setup
├── core/                          # Gemeinsame Funktionalitäten
│   ├── constants/                # App-weite Konstanten
│   ├── error/                    # Fehlerbehandlung (Failures)
│   ├── network/                  # HTTP Client Setup
│   ├── usecases/                 # Basis Use Cases
│   └── utils/                    # Hilfsfunktionen
└── features/                     # Feature-Module (Clean Architecture)
    ├── food_tracking/            # 🥬 Hauptfeature: Lebensmittel-Tracking
    │   ├── data/                # Repositories, Data Sources, Models
    │   ├── domain/              # Entities, Use Cases, Repository Interfaces
    │   └── presentation/        # BLoC, Pages, Widgets
    ├── recipes/                 # 👨‍🍳 KI-Rezeptgenerator
    ├── statistics/              # 📊 Verschwendungsstatistiken
    ├── settings/                # ⚙️ App-Einstellungen
    └── notification/            # 🔔 Push-Benachrichtigungen
```

## 🚀 Installation & Setup

### Voraussetzungen
- Flutter SDK 3.24+
- Dart 3.8.1+
- Android Studio / VS Code
- iOS: Xcode (für iOS-Entwicklung)

### Setup-Schritte

1. **Repository klonen**
   ```bash
   git clone <repository-url>
   cd essensretter3
   ```

2. **Dependencies installieren**
   ```bash
   flutter pub get
   ```

3. **Environment-Datei erstellen**
   ```bash
   cp .env.example .env
   # Füge deinen OpenAI API Key hinzu
   ```

4. **App starten**
   ```bash
   # iOS Simulator
   flutter run

   # Android Emulator
   flutter run

   # Web (experimentell)
   flutter run -d web
   ```

## 🧪 Testing & Qualitätssicherung

### Test-Befehle
```bash
# Alle Tests ausführen
flutter test

# Tests mit Coverage
flutter test --coverage

# Widget Tests
flutter test test/widget_test/

# Unit Tests
flutter test test/unit_test/

# Integration Tests
flutter test integration_test/
```

### Code-Qualität
```bash
# Statische Code-Analyse
flutter analyze

# Code-Formatierung
dart format lib/ test/

# Abhängigkeiten prüfen
flutter pub deps
```

### Test-Struktur
```
test/
├── unit_test/                    # Unit Tests für Use Cases
│   ├── features/
│   │   ├── food_tracking/
│   │   └── recipes/
├── widget_test/                  # Widget Tests für UI
│   ├── pages/
│   └── widgets/
└── integration_test/             # End-to-End Tests
    └── app_test.dart
```

## 🔧 Entwicklung

### Clean Architecture Prinzipien
Diese App folgt strikt Clean Architecture für bessere Wartbarkeit und Testbarkeit:

- **Presentation Layer**: UI (Pages, Widgets) + State Management (BLoC)
- **Domain Layer**: Business Logic (Use Cases, Entities, Repository Interfaces)
- **Data Layer**: Datenzugriff (Repository Implementations, Data Sources, Models)

### Entwicklungs-Workflow
1. **Branch erstellen**: `git checkout -b feature/neue-funktion`
2. **Tests schreiben**: Erst Tests, dann Implementation (TDD)
3. **Code implementieren**: Clean Architecture befolgen
4. **Tests ausführen**: `flutter test`
5. **Code-Analyse**: `flutter analyze`
6. **Pull Request**: Mit Tests und Dokumentation

### Coding Standards
- **Dart Style Guide**: [Offizielle Dart Guidelines](https://dart.dev/guides/language/effective-dart/style)
- **Naming**: `snake_case` für Dateien, `lowerCamelCase` für Variablen
- **Imports**: Geordnet nach CLAUDE.md Vorgaben
- **Tests**: Jede neue Funktion braucht Tests
- **Dokumentation**: README bei größeren Änderungen aktualisieren

## 📦 Dependencies

### Haupt-Dependencies
```yaml
# State Management
flutter_bloc: ^8.1.6           # BLoC Pattern
equatable: ^2.0.5              # Value Equality

# Dependency Injection  
get_it: ^7.7.0                 # Service Locator
injectable: ^2.4.4              # Code Generation

# Database
sqflite: ^2.3.3+1              # SQLite für Flutter
shared_preferences: ^2.3.2      # Key-Value Storage

# Networking
dio: ^5.7.0                    # HTTP Client
http: ^1.2.2                   # Alternative HTTP

# Utilities
intl: ^0.20.2                  # Internationalization
uuid: ^4.5.0                   # UUID Generation
dartz: ^0.10.1                 # Functional Programming

# Speech & Input
speech_to_text: ^6.6.2         # Spracheingabe
permission_handler: ^11.3.1     # Berechtigungen

# Notifications
flutter_local_notifications: ^17.2.1  # Push Notifications
timezone: ^0.9.4                      # Timezone Support
```

### Dev-Dependencies
```yaml
# Testing
flutter_test: sdk: flutter     # Flutter Test Framework
bloc_test: ^9.1.7              # BLoC Testing Utilities
mocktail: ^1.0.4               # Mocking Framework

# Code Generation
build_runner: ^2.4.12          # Code Generation Runner
injectable_generator: ^2.6.2    # DI Code Generation

# Linting
flutter_lints: ^5.0.0          # Dart/Flutter Lints
```

## 🔮 Roadmap

### V1.1 (Next Release)
- [ ] Push-Benachrichtigungen für ablaufende Lebensmittel
- [ ] Erweiterte Statistiken mit Diagrammen
- [ ] Barcode-Scanner für automatische Produkterkennung
- [ ] Export/Import von Lebensmittellisten

### V1.2 (Future)
- [ ] Community-Features: Lebensmittel teilen
- [ ] Smart Home Integration (Google Assistant, Alexa)
- [ ] Erweiterte KI-Features: Haltbarkeitsprognosen
- [ ] Desktop-App (Windows, macOS, Linux)

### V2.0 (Vision)
- [ ] Multiplayer: Familie/WG-Features
- [ ] Marketplace: Überschüssige Lebensmittel verkaufen
- [ ] Restaurant-Modus: Professionelle Küchen
- [ ] IoT-Integration: Smart Kühlschrank

## 🤝 Mitwirkende

- **David Rumpf** - Projektinitiator & Hauptentwickler
- **Claude Code** - KI-Entwicklungsassistent

## 📝 Lizenz

Dieses Projekt ist privat und nicht für die Veröffentlichung vorgesehen.

## 🆘 Support & Feedback

Bei Fragen oder Problemen:
1. Erst die [Issues](issues) durchsuchen
2. Neues Issue erstellen mit detaillierter Beschreibung
3. Bei kritischen Bugs: Label "bug" + "high priority"

---

**Entwickelt mit ❤️ und Flutter**