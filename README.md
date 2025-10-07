# EssensRetter 🥬🍎

Eine Flutter-App zur intelligenten Reduzierung von Lebensmittelverschwendung durch KI-gestütztes Tracking der Haltbarkeit von Lebensmitteln.

## 🎯 Überblick

EssensRetter hilft dir dabei, den Überblick über deine Lebensmittel zu behalten und rechtzeitig zu verbrauchen, bevor sie ablaufen. Die App nutzt künstliche Intelligenz, um aus deinen Texteingaben automatisch Lebensmittel zu erkennen und deren Haltbarkeit zu tracken.

## ✨ Hauptfunktionen

### 🥬 Lebensmittel-Tracking (Kernfunktion)
> **Das ist die Hauptfunktion der App**: Eigene Lebensmittel verwalten und Haltbarkeit tracken

- **Übersichtliche Darstellung**: Alle erfassten Lebensmittel auf einen Blick
- **Smart Cards**: Visuelle Karten mit Haltbarkeitsanzeige und Farbkodierung
- **Status-Tracking**: Markiere Lebensmittel als verbraucht oder entsorgt
- **Batch-Operations**: Lösche alle verbrauchten Lebensmittel auf einmal

### 🧠 Intelligente Texteingabe
- **Fließtext-Eingabe**: Gib Lebensmittel in natürlicher Sprache ein
- **Spracheingabe**: Diktiere deine Lebensmittel per Mikrofon
- **KI-gestützte Erkennung**: Automatische Extraktion von Lebensmitteln und Haltbarkeitsdaten
- **Flexible Formate**: "Milch morgen", "Honig 5 Tage", "Salami 4.08" - alles wird verstanden

### 🔍 Intelligente Filterung & Sortierung
- **Zeitbasierte Filter**: Heute, Morgen, Übermorgen, 3-7 Tage
- **Sortieroptionen**: Nach Datum, alphabetisch oder Kategorie
- **Dynamische Updates**: Filter werden in Echtzeit angewendet
- **Visuelle Indikatoren**: Farbkodierte Haltbarkeitsstatus

### 👥 Freunde & Sharing (Sekundärfunktion)
- **Freunde hinzufügen**: Via QR-Code oder User-ID
- **Lebensmittel teilen**: Biete überschüssige Lebensmittel deinen Freunden an
- **Messenger-Integration**: Schnell Kontakt aufnehmen über WhatsApp, Telegram, Signal

### 👨‍🍳 KI-Rezeptgenerator (Sekundärfunktion)
- **Automatische Rezeptvorschläge**: Basierend auf verfügbaren Lebensmitteln
- **Priorisierung**: Bevorzugt bald ablaufende Lebensmittel
- **Vielfältige Rezepte**: Von einfach bis komplex
- **Bookmark-System**: Speichere deine Lieblingsrezepte

### 📊 Statistiken & Insights (Sekundärfunktion)
- **Verschwendungsstatistiken**: Verfolge deine Fortschritte
- **Trends**: Analysiere dein Verhalten über Zeit
- **Kategorien-Auswertung**: Welche Lebensmittel verschwendest du am meisten?

### ⚙️ Einstellungen & Personalisierung
- **Theme-Anpassung**: Helle und dunkle Modi
- **Benachrichtigungen**: Werde rechtzeitig an ablaufende Lebensmittel erinnert
- **Backup & Sync**: Sichere deine Daten

## 🏗️ Technologie-Stack

- **Framework**: Flutter 3.24+ (iOS, Android, Web)
- **Architektur**: Clean Architecture mit 3-Schichten-Trennung (Presentation, Domain, Data)
- **State Management**: BLoC Pattern (flutter_bloc 9.1.1) - Trennung von UI und Logik
- **Lokale Datenbank**: SQLite (sqflite 2.3.3+1) - Daten auf dem Gerät speichern
- **Backend**: Supabase (supabase_flutter 2.7.3) - für Freunde-Feature und Sharing
- **KI-Integration**: OpenAI GPT für Text-zu-Lebensmittel Parsing (automatische Erkennung)
- **Dependency Injection**: GetIt 8.2.0 - automatisches Bereitstellen von Abhängigkeiten
- **Testing**: bloc_test + mocktail für umfassende Tests (aktuell 21.3% Coverage, Ziel: 50%)

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

### Test-Status (Stand: Januar 2025)
- **Coverage (Testabdeckung)**: 21.3% (850 von 3,995 Zeilen getestet)
- **Ziel**: 50% Coverage (Langfristziel: 80%)
- **Tests gesamt**: 137 Tests
- **Priorität**: Food-Tracking (Kernfunktion) vor Sekundärfunktionen

### Test-Befehle
```bash
# Alle Tests ausführen (PFLICHT vor jedem Commit)
flutter test

# Tests mit Coverage (zeigt welcher Code getestet wurde)
flutter test --coverage

# Coverage Report generieren (mit HTML-Ausgabe)
./scripts/coverage-report.sh

# Widget Tests (UI-Tests)
flutter test test/widget_test/

# Unit Tests (Logik-Tests)
flutter test test/unit_test/

# Integration Tests (Ende-zu-Ende Tests)
flutter test integration_test/
```

### Code-Qualität
```bash
# Statische Code-Analyse (prüft auf Fehler und Best Practices)
flutter analyze

# Code-Formatierung (einheitlicher Stil)
dart format lib/ test/

# Abhängigkeiten prüfen (welche Pakete werden verwendet)
flutter pub deps
```

### Test-Struktur
```
test/
├── unit_test/                    # Unit Tests für Business-Logik
│   ├── features/
│   │   ├── food_tracking/       # Kernfunktion (hohe Priorität)
│   │   ├── sharing/             # Freunde & Sharing (mittlere Priorität)
│   │   └── recipes/             # Rezepte (niedrige Priorität)
├── widget_test/                  # Widget Tests für UI-Komponenten
│   ├── pages/
│   └── widgets/
└── integration_test/             # End-to-End Tests (gesamte App)
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

## 📦 Dependencies (externe Bibliotheken)

### Haupt-Dependencies
```yaml
# State Management (Zustandsverwaltung)
flutter_bloc: ^9.1.1           # BLoC Pattern - trennt UI von Logik
equatable: ^2.0.5              # Value Equality - vereinfacht Objektvergleiche

# Dependency Injection (automatisches Bereitstellen von Abhängigkeiten)
get_it: ^8.2.0                 # Service Locator - zentrale Stelle für Services
injectable: ^2.4.4              # Code Generation - automatisch Services registrieren

# Database (Datenbank)
sqflite: ^2.3.3+1              # SQLite für Flutter - lokale Datenbank auf dem Gerät
shared_preferences: ^2.3.2      # Key-Value Storage - einfache Einstellungen speichern

# Backend & Networking (Netzwerk-Kommunikation)
supabase_flutter: ^2.7.3       # Supabase - Backend für Freunde & Sharing
dio: ^5.7.0                    # HTTP Client - Netzwerk-Anfragen
http: ^1.2.2                   # Alternative HTTP - Backup HTTP-Library

# Utilities (Hilfsbibliotheken)
intl: ^0.20.2                  # Internationalization - mehrsprachige Unterstützung
uuid: ^4.5.0                   # UUID Generation - eindeutige IDs erstellen
dartz: ^0.10.1                 # Functional Programming - Either/Option Pattern

# Speech & Input (Eingabe)
speech_to_text: ^6.6.2         # Spracheingabe - Mikrofon-zu-Text
permission_handler: ^11.3.1     # Berechtigungen - App-Zugriffe verwalten

# QR-Code & Scanning (für Freunde-Feature)
qr_flutter: ^4.1.0             # QR-Code Generierung - User-IDs als QR-Code
mobile_scanner: ^3.5.5         # QR-Code Scanner - Freunde-IDs scannen

# Notifications (Benachrichtigungen)
flutter_local_notifications: ^19.4.2  # Push Notifications - Erinnerungen bei Ablauf
timezone: ^0.9.4                      # Timezone Support - Zeitzonen-Unterstützung
```

### Dev-Dependencies (nur für Entwicklung)
```yaml
# Testing (Tests schreiben)
flutter_test: sdk: flutter     # Flutter Test Framework - Basis für Tests
bloc_test: ^9.1.7              # BLoC Testing Utilities - BLoC-spezifische Tests
mocktail: ^1.0.4               # Mocking Framework - Fake-Objekte für Tests

# Code Generation (automatische Code-Erstellung)
build_runner: ^2.4.12          # Code Generation Runner - führt Generatoren aus
injectable_generator: ^2.6.2    # DI Code Generation - generiert Dependency Injection Code

# Linting (Code-Qualitätsprüfung)
flutter_lints: ^5.0.0          # Dart/Flutter Lints - Best Practice Regeln
```

## 🔮 Roadmap

### V1.1 - Qualitätssicherung (Aktueller Fokus)
- [x] Code-Refactoring großer Dateien (offered_foods_bottom_sheet, food_bloc, friends_page)
- [ ] Test Coverage auf 50% erhöhen (aktuell 21.3%)
- [ ] Error Tracking Setup (Sentry oder Firebase Crashlytics)
- [ ] Push-Benachrichtigungen für ablaufende Lebensmittel
- [ ] Performance-Optimierung der Food-Tracking Liste

### V1.2 - Feature-Erweiterungen
- [ ] Barcode-Scanner für automatische Produkterkennung
- [ ] Export/Import von Lebensmittellisten (JSON/CSV)
- [ ] Erweiterte Statistiken mit Diagrammen (Charts)
- [ ] Offline-Modus verbessern (besseres Caching)
- [ ] Widget für Home Screen (iOS & Android)

### V2.0 - Community Features (Vision)
- [ ] Familie/WG-Features: Geteilte Lebensmittel-Listen
- [ ] Smart Home Integration (Google Assistant, Alexa)
- [ ] Erweiterte KI-Features: Haltbarkeitsprognosen basierend auf Lagerung
- [ ] Desktop-App (Windows, macOS, Linux)
- [ ] Restaurant-Modus: Professionelle Küchen

**Hinweis**: Roadmap fokussiert sich primär auf Kernfunktion (Food-Tracking), Sekundärfunktionen werden nachrangig behandelt.

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