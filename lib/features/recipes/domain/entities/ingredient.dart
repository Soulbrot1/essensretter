import 'package:equatable/equatable.dart';

class Ingredient extends Equatable {
  final String name; // "Mehl", "Zwiebel", "Salz"
  final double? amount; // 200, 1, null (für "Prise Salz")
  final String? unit; // "g", "EL", "Stück", null
  final String originalText; // "200g Mehl" - Original für Fallback

  const Ingredient({
    required this.name,
    this.amount,
    this.unit,
    required this.originalText,
  });

  /// Skaliert die Zutat basierend auf einem Faktor
  Ingredient scale(double factor) {
    // Wenn keine Menge angegeben, Original zurückgeben
    if (amount == null) {
      return this;
    }

    // Spezielle Behandlung für nicht-skalierbare Einheiten
    if (_isNonScalableUnit()) {
      return this;
    }

    final scaledAmount = amount! * factor;
    return copyWith(amount: _roundAmount(scaledAmount));
  }

  /// Prüft ob die Einheit nicht skalierbar ist (z.B. Prise, nach Geschmack)
  bool _isNonScalableUnit() {
    if (unit == null) return false;

    final nonScalableUnits = [
      'prise', 'prisen',
      'geschmack',
      'belieben',
      'etwas',
      'große', 'großer', 'großes', // Adjektive
      'kleine', 'kleiner', 'kleines',
      'mittelgroße', 'mittlere',
    ];

    return nonScalableUnits.any(
      (u) =>
          unit!.toLowerCase().contains(u) ||
          originalText.toLowerCase().contains(u),
    );
  }

  /// Rundet Mengen sinnvoll (z.B. 1.33 → 1.3, 250.5 → 250)
  double _roundAmount(double amount) {
    if (amount < 1) {
      return double.parse(amount.toStringAsFixed(2));
    } else if (amount < 10) {
      return double.parse(amount.toStringAsFixed(1));
    } else {
      return amount.round().toDouble();
    }
  }

  /// Formatiert die Zutat für die Anzeige
  String get displayText {
    if (amount == null || unit == null) {
      return originalText;
    }

    // Spezielle Formatierung für ganze Zahlen
    final amountText = amount! % 1 == 0
        ? amount!.toInt().toString()
        : amount!.toString();

    // Leerzeichen zwischen Menge und Einheit hinzufügen
    return '$amountText $unit $name';
  }

  /// Erstellt eine Kopie mit geänderten Werten
  Ingredient copyWith({
    String? name,
    double? amount,
    String? unit,
    String? originalText,
  }) {
    return Ingredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      originalText: originalText ?? this.originalText,
    );
  }

  /// Erstellt eine Ingredient aus String (z.B. "200g Mehl")
  factory Ingredient.fromString(String text) {
    // Regex für Mengenangaben: Zahl + optionale Einheit + Rest
    final regex = RegExp(r'^(\d+(?:[,.]?\d+)?)\s*([a-zA-ZäöüÄÖÜß]*)\s*(.+)$');
    final match = regex.firstMatch(text.trim());

    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '.');
      final unit = match.group(2)?.trim();
      final name = match.group(3)?.trim();

      final amount = double.tryParse(amountStr ?? '');

      return Ingredient(
        name: name ?? text,
        amount: amount,
        unit: unit?.isEmpty == true ? null : unit,
        originalText: text,
      );
    }

    // Fallback: Kein Parse möglich, als Text speichern
    return Ingredient(name: text, amount: null, unit: null, originalText: text);
  }

  @override
  List<Object?> get props => [name, amount, unit, originalText];
}
