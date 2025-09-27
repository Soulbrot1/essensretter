# EssensRetter Sharing Feature - Funktionale Spezifikation

## 1. Feature Overview

**Ziel**: Nutzer können Lebensmittel zum Verschenken anbieten und über Access Keys mit anderen teilen.

**Geschäftswert**:
- Virale Nutzerakquise ohne Marketing-Budget
- Community-Building zwischen Bekannten/Kollegen
- Reduzierte Lebensmittelverschwendung durch direktes Teilen

## 2. Minimaler Funktionsumfang (MVP)

### 2.1 Core User Stories

**Als Geber:**
- Kann Lebensmittel als "zu verschenken" markieren
- Kann Access Key generieren und per QR-Code teilen
- Kann sehen welche Items reserviert wurden
- Kann Access Key widerrufen

**Als Nehmer:**
- Kann per QR-Code auf Verschenkliste zugreifen
- Kann verfügbare Items sehen
- Kann Items reservieren (24h Zeitfenster)
- Kann Reservierung stornieren

### 2.2 Was NICHT enthalten ist
- ❌ In-App Messaging
- ❌ Bewertungssystem
- ❌ Push Notifications
- ❌ Nutzerprofil-Verwaltung
- ❌ Koordinatenbasierte Umkreissuche
- ❌ Öffentlicher Marktplatz

## 3. Datenkonzept

### 3.1 Benötigte Datenstrukturen

**ShareableFood**: Verknüpfung zwischen Lebensmittel und Verschenk-Status
- Referenz zum Lebensmittel
- Besitzer-Information
- Verfügbarkeitsstatus
- Erstellungszeitpunkt

**ShareAccess**: Zugangsverwaltung für Verschenklisten
- Eindeutiger Access Key
- Zugehörigkeit zum Listenbesitzer
- Aktivitätsstatus (widerrufbar)
- Optional: Ablaufzeitpunkt

**FoodReservation**: Verwaltung von Reservierungen
- Referenz zum verschenkbaren Item
- Zuordnung über Access Key
- Reservierungszeitpunkt
- Automatisches Ablaufdatum (24h)

### 3.2 Erweiterung bestehender Daten
- Lebensmittel erhalten Flag für "zum Verschenken angeboten"

## 4. Funktionale Anforderungen

### 4.1 Access Key Management
- Generierung eindeutiger Access Keys
- Widerruf von Access Keys
- Validierung beim Zugriff
- Optional: Automatisches Ablaufdatum

### 4.2 Sharing Management
- Markieren/Demarkieren von Lebensmitteln zum Verschenken
- Anzeige der Verschenkliste per Access Key
- Statusverwaltung (verfügbar/reserviert/vergeben)

### 4.3 Reservation System
- Reservierung von Items mit 24h Gültigkeit
- Stornierung von Reservierungen
- Automatische Freigabe nach Ablauf
- Übersicht eigener Reservierungen
- Übersicht eingehender Reservierungen für Geber

## 5. UI/UX Flows

### 5.1 Geber Flow
1. **Food Details**: Toggle zum Verschenken aktivieren
2. **Verschenkliste**: Übersicht aller angebotenen Items
3. **Teilen**: QR-Code generieren und anzeigen
4. **Verwaltung**: Reservierungen einsehen, Access widerrufen

### 5.2 Nehmer Flow
1. **Zugang**: QR-Code scannen oder Link öffnen
2. **Durchstöbern**: Verfügbare Items ansehen
3. **Reservieren**: Item für 24h reservieren
4. **Verwalten**: Eigene Reservierungen einsehen/stornieren

## 6. Technische Überlegungen

### 6.1 Architektur
- Integration in bestehende Clean Architecture
- Neues Feature-Modul "sharing"
- Erweiterung der bestehenden Food-Entität

### 6.2 Benötigte Komponenten
- QR-Code Generator
- QR-Code Scanner
- Reservierungs-Timer
- Cleanup-Mechanismus für abgelaufene Reservierungen

### 6.3 Datenbankstruktur
- Neue Tabellen für Sharing-Funktionalität
- Referenzielle Integrität zu bestehenden Foods
- Performance-Indizes für häufige Abfragen

## 7. Kritische Risiken & Mitigation

### 7.1 Technische Risiken

**Missbrauch von Access Keys**
- Risiko: Unkontrollierte Weitergabe von QR-Codes
- Lösung: Widerrufbare Keys mit optionalem Ablaufdatum

**Reservierungs-Spam**
- Risiko: Massenhafte Reservierungen ohne Abholung
- Lösung: 24h Zeitlimit, automatische Freigabe

**Performance-Probleme**
- Risiko: Langsame Ladezeiten bei vielen Items
- Lösung: Optimierte Datenbankabfragen, Pagination

### 7.2 UX Risiken

**Verwirrende Navigation**
- Risiko: Nutzer verlieren Überblick zwischen eigenen/fremden Listen
- Lösung: Klare visuelle Unterscheidung in der UI

**Vergessene Reservierungen**
- Risiko: Blockierte Items durch inaktive Nutzer
- Lösung: Automatischer Ablauf nach 24h

## 8. Akzeptanzkriterien

### 8.1 Funktionale Kriterien
- Lebensmittel können zum Verschenken markiert werden
- QR-Codes werden generiert und sind scannbar
- Access Keys können widerrufen werden
- Reservierungen verfallen automatisch nach 24h
- Zugriffskontrolle verhindert unbefugten Zugang

### 8.2 Performance-Kriterien
- QR-Code Generierung unter 500ms
- Listen-Ladezeit unter 2 Sekunden bei 50 Items
- Reservierung innerhalb 1 Sekunde

### 8.3 Sicherheitskriterien
- Access Keys sind nicht vorhersagbar
- Keine Aufzählung von Keys möglich
- Widerrufene Keys sind sofort ungültig

## 9. Rollout-Strategie

**Phase 1**: Basis-Funktionalität (4-6 Wochen)
- Grundlegende Sharing-Funktion
- QR-Code Integration
- Einfaches Reservierungssystem

**Phase 2**: Verbesserungen (2-3 Wochen)
- UX-Optimierungen
- Automatische Bereinigung
- Nutzungsstatistiken

**Phase 3**: Erweiterungen (optional)
- Mehrfach-Sharing
- Erweiterte Statistiken
- Export-Möglichkeiten