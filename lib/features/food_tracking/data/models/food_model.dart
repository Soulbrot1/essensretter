import '../../domain/entities/food.dart';

class FoodModel extends Food {
  const FoodModel({
    required super.id,
    required super.name,
    required super.expiryDate,
    required super.addedDate,
    super.category,
    super.notes,
    super.isConsumed = false,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      addedDate: DateTime.parse(json['addedDate'] as String),
      category: json['category'] as String?,
      notes: json['notes'] as String?,
      isConsumed: (json['isConsumed'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expiryDate': expiryDate.toIso8601String(),
      'addedDate': addedDate.toIso8601String(),
      'category': category,
      'notes': notes,
      'isConsumed': isConsumed ? 1 : 0,
    };
  }

  factory FoodModel.fromEntity(Food food) {
    return FoodModel(
      id: food.id,
      name: food.name,
      expiryDate: food.expiryDate,
      addedDate: food.addedDate,
      category: food.category,
      notes: food.notes,
      isConsumed: food.isConsumed,
    );
  }
}