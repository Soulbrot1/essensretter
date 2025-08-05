import '../entities/recipe.dart';
import '../entities/ingredient.dart';

/// Service für Rezept-Berechnungen und -Umrechnungen
class RecipeCalculator {
  
  /// Skaliert ein Rezept für eine neue Personenanzahl
  static Recipe scaleRecipe(Recipe recipe, int newServings) {
    return recipe.scaleForServings(newServings);
  }

  /// Berechnet den Skalierungsfaktor zwischen zwei Personenanzahlen
  static double calculateScalingFactor(int originalServings, int newServings) {
    if (originalServings <= 0) return 1.0;
    return newServings / originalServings;
  }

  /// Prüft ob eine Skalierung sinnvoll ist
  static bool canScale(Recipe recipe, int newServings) {
    // Minimum 1 Person, Maximum 20 Personen
    if (newServings < 1 || newServings > 20) return false;
    
    // Kann nicht skaliert werden wenn Original-Portionen unbekannt
    if (recipe.servings <= 0) return false;
    
    return true;
  }

  /// Gibt empfohlene Personenanzahlen zurück (für UI Slider/Dropdown)
  static List<int> getRecommendedServings() {
    return [1, 2, 3, 4, 5, 6, 8, 10, 12];
  }

  /// Formatiert die Personenanzahl für die Anzeige
  static String formatServings(int servings) {
    switch (servings) {
      case 1:
        return '1 Person';
      default:
        return '$servings Personen';
    }
  }

  /// Analysiert ein Rezept und gibt Statistiken zurück
  static RecipeStats analyzeRecipe(Recipe recipe) {
    int scalableIngredients = 0;
    int nonScalableIngredients = 0;
    
    for (final ingredient in [...recipe.vorhanden, ...recipe.ueberpruefen]) {
      if (ingredient.amount != null && !ingredient._isNonScalableUnit()) {
        scalableIngredients++;
      } else {
        nonScalableIngredients++;
      }
    }
    
    return RecipeStats(
      totalIngredients: recipe.vorhanden.length + recipe.ueberpruefen.length,
      scalableIngredients: scalableIngredients,
      nonScalableIngredients: nonScalableIngredients,
      scalingAccuracy: scalableIngredients / (scalableIngredients + nonScalableIngredients),
    );
  }

  /// Erstellt eine Zutatenliste für den Einkauf (kombiniert vorhanden + überprüfen)
  static List<Ingredient> createShoppingList(Recipe recipe) {
    final shoppingList = <Ingredient>[];
    
    // Nur "überprüfen" Zutaten kommen auf die Einkaufsliste
    shoppingList.addAll(recipe.ueberpruefen);
    
    return shoppingList;
  }

  /// Konvertiert alte String-basierte Rezepte zu neuen Ingredient-basierten
  static Recipe migrateFromStringLists({
    required String title,
    required String cookingTime,
    required List<String> vorhanden,
    required List<String> ueberpruefen,
    required String instructions,
    int servings = 2,
    bool isBookmarked = false,
  }) {
    return Recipe.fromStringLists(
      title: title,
      cookingTime: cookingTime,
      vorhanden: vorhanden,
      ueberpruefen: ueberpruefen,
      instructions: instructions,
      servings: servings,
      isBookmarked: isBookmarked,
    );
  }
}

/// Statistiken über ein Rezept
class RecipeStats {
  final int totalIngredients;
  final int scalableIngredients;
  final int nonScalableIngredients;
  final double scalingAccuracy;  // 0.0 - 1.0

  const RecipeStats({
    required this.totalIngredients,
    required this.scalableIngredients,
    required this.nonScalableIngredients,
    required this.scalingAccuracy,
  });

  /// Gibt eine textuelle Bewertung der Skalierbarkeit zurück
  String get scalingQuality {
    if (scalingAccuracy >= 0.9) return 'Excellent';
    if (scalingAccuracy >= 0.7) return 'Good';
    if (scalingAccuracy >= 0.5) return 'Fair';
    return 'Limited';
  }
}

/// Extension für private Methoden der Ingredient Klasse
extension IngredientPrivate on Ingredient {
  bool _isNonScalableUnit() {
    if (unit == null) return false;
    
    final nonScalableUnits = [
      'prise', 'prisen',
      'geschmack', 
      'belieben',
      'etwas',
    ];
    
    return nonScalableUnits.any((u) => 
      unit!.toLowerCase().contains(u) || 
      originalText.toLowerCase().contains(u)
    );
  }
}