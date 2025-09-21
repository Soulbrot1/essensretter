import '../../domain/entities/household.dart';

class HouseholdModel extends Household {
  const HouseholdModel({
    required super.id,
    required super.masterKey,
    required super.createdAt,
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> json) {
    return HouseholdModel(
      id: json['id'] as String,
      masterKey: json['master_key'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'master_key': masterKey, 'created_at': createdAt};
  }
}
