import 'package:equatable/equatable.dart';

class Recipe extends Equatable {
  final String title;
  final String cookingTime;
  final List<String> vorhanden;
  final List<String> ueberpruefen;
  final String instructions;
  final bool isBookmarked;

  const Recipe({
    required this.title,
    required this.cookingTime,
    required this.vorhanden,
    required this.ueberpruefen,
    required this.instructions,
    this.isBookmarked = false,
  });

  Recipe copyWith({
    String? title,
    String? cookingTime,
    List<String>? vorhanden,
    List<String>? ueberpruefen,
    String? instructions,
    bool? isBookmarked,
  }) {
    return Recipe(
      title: title ?? this.title,
      cookingTime: cookingTime ?? this.cookingTime,
      vorhanden: vorhanden ?? this.vorhanden,
      ueberpruefen: ueberpruefen ?? this.ueberpruefen,
      instructions: instructions ?? this.instructions,
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
        isBookmarked,
      ];
}