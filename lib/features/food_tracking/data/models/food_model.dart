import '../../domain/entities/food.dart';

class FoodModel extends Food {
  const FoodModel({
    required super.id,
    required super.name,
    super.expiryDate,
    required super.addedDate,
    super.category,
    super.notes,
    super.isConsumed = false,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
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
      'expiryDate': expiryDate?.toIso8601String(),
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

  factory FoodModel.fromSupabase(Map<String, dynamic> data) {
    return FoodModel(
      id: data['id'] as String,
      name: data['name'] as String,
      expiryDate: data['expiry_date'] != null
          ? DateTime.parse(data['expiry_date'] as String)
          : null,
      addedDate: DateTime.parse(data['added_date'] as String),
      category: data['category'] as String?,
      notes: data['notes'] as String?,
      isConsumed: false, // Wird später aus Supabase geholt
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'name': name,
      'expiry_date': expiryDate?.toIso8601String().split('T')[0], // Nur Datum
      'added_date': addedDate.toIso8601String().split('T')[0], // Nur Datum
      'category': category,
      'notes': notes,
    };
  }
}
