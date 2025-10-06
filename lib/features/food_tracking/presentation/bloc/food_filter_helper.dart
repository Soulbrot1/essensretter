import '../../domain/entities/food.dart';

/// Helper-Klasse für Filter-Operationen im FoodBloc
///
/// Enthält alle Filter-Logik um Code-Duplizierung zu vermeiden
class FoodFilterHelper {
  /// Wendet alle aktiven Filter auf eine Liste von Foods an
  ///
  /// Parameter:
  /// - [foods]: Basis-Liste zum Filtern
  /// - [searchText]: Optionaler Suchtext für Namen-Filter
  /// - [activeFilter]: Optionale Tage bis Ablauf (z.B. 7 für "läuft in 7 Tagen ab")
  /// - [showOnlyShared]: Nur geteilte Lebensmittel anzeigen
  static List<Food> applyAllFilters(
    List<Food> foods, {
    String? searchText,
    int? activeFilter,
    bool showOnlyShared = false,
  }) {
    List<Food> filtered = foods;

    // 1. Search filter (by name)
    if (searchText != null && searchText.isNotEmpty) {
      filtered = applySearchFilter(filtered, searchText);
    }

    // 2. Expiry filter (by days until expiry)
    if (activeFilter != null) {
      filtered = applyExpiryFilter(filtered, activeFilter);
    }

    // 3. Shared filter
    if (showOnlyShared) {
      filtered = applySharedFilter(filtered);
    }

    return filtered;
  }

  /// Filtert nach Namen (case-insensitive)
  static List<Food> applySearchFilter(List<Food> foods, String searchText) {
    return foods
        .where(
          (food) => food.name.toLowerCase().contains(searchText.toLowerCase()),
        )
        .toList();
  }

  /// Filtert nach Ablaufdatum (läuft in X Tagen ab)
  static List<Food> applyExpiryFilter(List<Food> foods, int daysUntilExpiry) {
    return foods.where((food) => food.expiresInDays(daysUntilExpiry)).toList();
  }

  /// Filtert nur geteilte Lebensmittel
  static List<Food> applySharedFilter(List<Food> foods) {
    return foods.where((food) => food.isShared).toList();
  }
}
