import 'package:equatable/equatable.dart';

class Household extends Equatable {
  final String id;
  final String masterKey;
  final String createdAt;

  const Household({
    required this.id,
    required this.masterKey,
    required this.createdAt,
  });

  @override
  List<Object> get props => [id, masterKey, createdAt];
}
