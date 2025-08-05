import 'package:equatable/equatable.dart';
import 'ingredient.dart';

class Recipe extends Equatable {
  final String title;
  final String cookingTime;
  final List<Ingredient> vorhanden;
  final List<Ingredient> ueberpruefen;
  final String instructions;
  final int servings;            // Für wie viele Personen das Rezept ist
  final bool isBookmarked;

  const Recipe({
    required this.title,
    required this.cookingTime,
    required this.vorhanden,
    required this.ueberpruefen,
    required this.instructions,
    this.servings = 2,           // Standard: 2 Personen
    this.isBookmarked = false,
  });

  /// Skaliert das Rezept für eine neue Personenanzahl
  Recipe scaleForServings(int newServings) {
    if (newServings == servings) return this;
    
    final factor = newServings / servings;
    
    return copyWith(
      servings: newServings,
      vorhanden: vorhanden.map((ingredient) => ingredient.scale(factor)).toList(),
      ueberpruefen: ueberpruefen.map((ingredient) => ingredient.scale(factor)).toList(),
    );
  }

  /// Backward compatibility: Erstellt Recipe aus String-Listen
  factory Recipe.fromStringLists({
    required String title,
    required String cookingTime,
    required List<String> vorhanden,
    required List<String> ueberpruefen,
    required String instructions,
    int servings = 2,
    bool isBookmarked = false,
  }) {
    return Recipe(
      title: title,
      cookingTime: cookingTime,
      vorhanden: vorhanden.map((s) => Ingredient.fromString(s)).toList(),
      ueberpruefen: ueberpruefen.map((s) => Ingredient.fromString(s)).toList(),
      instructions: instructions,
      servings: servings,
      isBookmarked: isBookmarked,
    );
  }

  /// Backward compatibility: Konvertiert zu String-Listen
  List<String> get vorhandenAsStrings => vorhanden.map((i) => i.displayText).toList();
  List<String> get ueberprufenAsStrings => ueberpruefen.map((i) => i.displayText).toList();

  Recipe copyWith({
    String? title,
    String? cookingTime,
    List<Ingredient>? vorhanden,
    List<Ingredient>? ueberpruefen,
    String? instructions,
    int? servings,
    bool? isBookmarked,
  }) {
    return Recipe(
      title: title ?? this.title,
      cookingTime: cookingTime ?? this.cookingTime,
      vorhanden: vorhanden ?? this.vorhanden,
      ueberpruefen: ueberpruefen ?? this.ueberpruefen,
      instructions: instructions ?? this.instructions,
      servings: servings ?? this.servings,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  @override
  List<Object?> get props => [
        title,
        cookingTime,
        vorhanden,
        ueberpruefen,
        instructions,
        servings,
        isBookmarked,
      ];
}