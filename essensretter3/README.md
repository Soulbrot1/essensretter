# EssensRetter

Eine Flutter-App zum Tracking von Lebensmitteln und deren Haltbarkeit, um Lebensmittelverschwendung zu reduzieren.

## Überblick

EssensRetter hilft dir dabei, den Überblick über deine Lebensmittel zu behalten und rechtzeitig zu verbrauchen, bevor sie ablaufen. Die App nutzt KI, um aus deinen Texteingaben automatisch Lebensmittel zu erkennen und deren Haltbarkeit zu tracken.

## Hauptfunktionen (MVP)

### 1. Intelligente Texteingabe
- Eingabe von Lebensmitteln im Fließtext (Tastatur oder Sprache)
- KI-gestützte Erkennung und Extraktion von Lebensmitteln
- Automatische Erfassung der Haltbarkeitsdauer aus der Eingabe

### 2. Lebensmittel-Übersicht
- Übersichtliche Darstellung aller erfassten Lebensmittel
- Anzeige der verbleibenden Haltbarkeit (z.B. "in 3 Tagen")
- Visuelle Karten für jedes Lebensmittel

### 3. Intelligente Filterung
- Zeitbasierte Filter: 7 Tage, 6 Tage, 5 Tage, 4 Tage, 3 Tage
- Spezialfilter: "übermorgen", "morgen"
- Schneller Überblick über bald ablaufende Lebensmittel

## Geplante Erweiterungen

- **Haltbarkeitstipps**: Info-Symbole auf den Lebensmittelkarten mit Tipps zur optimalen Lagerung
- **Rezeptgenerator**: KI-basierte Rezeptvorschläge aus vorhandenen Lebensmitteln
- **Lebensmittel teilen**: Community-Feature zum Verschenken von Lebensmitteln

## Technologie-Stack

- **Framework**: Flutter (iOS, Android, Web)
- **Architektur**: Clean Architecture
- **State Management**: [Wird noch festgelegt]
- **Lokale Datenbank**: [Wird noch festgelegt]
- **KI-Integration**: [Wird noch festgelegt]

## Projekt-Struktur

```
lib/
├── core/                    # Gemeinsame Funktionalitäten
│   ├── constants/          # App-weite Konstanten
│   ├── error/              # Fehlerbehandlung
│   ├── usecases/           # Basis Use Cases
│   ├── utils/              # Hilfsfunktionen
│   └── widgets/            # Wiederverwendbare Widgets
├── features/               # Feature-Module
│   ├── food_tracking/      # Hauptfeature: Lebensmittel-Tracking
│   │   ├── data/          # Datenebene
│   │   ├── domain/        # Geschäftslogik
│   │   └── presentation/  # UI-Ebene
│   └── settings/          # Einstellungen
└── main.dart              # App-Einstiegspunkt
```

## Installation & Setup

1. Flutter installieren (https://flutter.dev/docs/get-started/install)
2. Repository klonen
3. Dependencies installieren: `flutter pub get`
4. App starten: `flutter run`

## Entwicklung

Diese App folgt Clean Architecture Prinzipien für bessere Wartbarkeit und Testbarkeit. Jedes Feature ist in drei Schichten unterteilt:

- **Presentation**: UI und State Management
- **Domain**: Geschäftslogik und Entitäten
- **Data**: Datenzugriff und externe APIs

## Mitwirkende

- David Rumpf - Projektinitiator

## Lizenz

[Noch festzulegen]
