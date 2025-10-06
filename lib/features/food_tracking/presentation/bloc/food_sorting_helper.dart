import '../../domain/entities/food.dart';
import 'food_event.dart';

/// Helper-Klasse für Sortier-Operationen im FoodBloc
///
/// Enthält alle Sortier-Logik für Lebensmittel-Listen
class FoodSortingHelper {
  /// Sortiert eine Liste von Foods nach dem angegebenen SortOption
  static List<Food> sortFoods(List<Food> foods, SortOption sortOption) {
    final sorted = List<Food>.from(foods);

    switch (sortOption) {
      case SortOption.alphabetical:
        _sortAlphabetically(sorted);
        break;
      case SortOption.date:
        _sortByDate(sorted);
        break;
      case SortOption.category:
        _sortByCategory(sorted);
        break;
      case SortOption.shared:
        _sortByShared(sorted);
        break;
    }

    return sorted;
  }

  /// Sortiert alphabetisch nach Name (case-insensitive)
  static void _sortAlphabetically(List<Food> foods) {
    foods.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Sortiert nach Ablaufdatum (früheste zuerst)
  /// Lebensmittel ohne Datum kommen ans Ende
  static void _sortByDate(List<Food> foods) {
    foods.sort((a, b) {
      // Foods without expiry date go to the end
      if (a.expiryDate == null && b.expiryDate == null) return 0;
      if (a.expiryDate == null) return 1;
      if (b.expiryDate == null) return -1;
      return a.expiryDate!.compareTo(b.expiryDate!);
    });
  }

  /// Sortiert nach Kategorie, dann alphabetisch innerhalb der Kategorie
  static void _sortByCategory(List<Food> foods) {
    foods.sort((a, b) {
      final categoryA = a.category ?? 'Sonstiges';
      final categoryB = b.category ?? 'Sonstiges';
      final categoryCompare = categoryA.compareTo(categoryB);
      if (categoryCompare != 0) return categoryCompare;
      // If same category, sort by name
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  /// Sortiert mit Shared Foods zuerst, dann nach Ablaufdatum
  static void _sortByShared(List<Food> foods) {
    foods.sort((a, b) {
      // Shared foods first
      if (a.isShared && !b.isShared) return -1;
      if (!a.isShared && b.isShared) return 1;

      // If both shared or both not shared, sort by expiry date
      if (a.expiryDate == null && b.expiryDate == null) return 0;
      if (a.expiryDate == null) return 1;
      if (b.expiryDate == null) return -1;
      return a.expiryDate!.compareTo(b.expiryDate!);
    });
  }
}
