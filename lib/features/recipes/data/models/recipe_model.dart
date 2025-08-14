import '../../domain/entities/recipe.dart';
import '../../domain/entities/ingredient.dart';

class RecipeModel extends Recipe {
  const RecipeModel({
    required super.title,
    required super.cookingTime,
    required super.vorhanden,
    required super.ueberpruefen,
    required super.instructions,
    super.servings,
    super.isBookmarked,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility: convert String lists to Ingredient lists
    final vorhandenList = List<String>.from(json['vorhanden'] as List);
    final ueberprufenList = List<String>.from(json['ueberpruefen'] as List);

    return RecipeModel(
      title: json['title'] as String,
      cookingTime: json['cookingTime'] as String,
      vorhanden: vorhandenList.map((s) => Ingredient.fromString(s)).toList(),
      ueberpruefen: ueberprufenList
          .map((s) => Ingredient.fromString(s))
          .toList(),
      instructions: json['instructions'] as String,
      servings: json['servings'] as int? ?? 2,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'cookingTime': cookingTime,
      'vorhanden': vorhandenAsStrings, // Convert back to strings for storage
      'ueberpruefen':
          ueberprufenAsStrings, // Convert back to strings for storage
      'instructions': instructions,
      'servings': servings,
      'isBookmarked': isBookmarked,
    };
  }

  factory RecipeModel.fromEntity(Recipe recipe) {
    return RecipeModel(
      title: recipe.title,
      cookingTime: recipe.cookingTime,
      vorhanden: recipe.vorhanden,
      ueberpruefen: recipe.ueberpruefen,
      instructions: recipe.instructions,
      servings: recipe.servings,
      isBookmarked: recipe.isBookmarked,
    );
  }
}
