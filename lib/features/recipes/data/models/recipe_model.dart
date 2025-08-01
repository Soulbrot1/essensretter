import '../../domain/entities/recipe.dart';

class RecipeModel extends Recipe {
  const RecipeModel({
    required super.title,
    required super.cookingTime,
    required super.vorhanden,
    required super.ueberpruefen,
    required super.instructions,
    super.isBookmarked,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      title: json['title'] as String,
      cookingTime: json['cookingTime'] as String,
      vorhanden: List<String>.from(json['vorhanden'] as List),
      ueberpruefen: List<String>.from(json['ueberpruefen'] as List),
      instructions: json['instructions'] as String,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'cookingTime': cookingTime,
      'vorhanden': vorhanden,
      'ueberpruefen': ueberpruefen,
      'instructions': instructions,
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
      isBookmarked: recipe.isBookmarked,
    );
  }
}