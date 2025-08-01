import 'package:equatable/equatable.dart';

class Food extends Equatable {
  final String id;
  final String name;
  final DateTime expiryDate;
  final DateTime addedDate;
  final String? category;
  final String? notes;

  const Food({
    required this.id,
    required this.name,
    required this.expiryDate,
    required this.addedDate,
    this.category,
    this.notes,
  });

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  bool get isExpired => daysUntilExpiry < 0;

  bool expiresInDays(int days) => daysUntilExpiry <= days && !isExpired;

  String get expiryStatus {
    final days = daysUntilExpiry;
    if (isExpired) {
      return 'Abgelaufen vor ${-days} Tag${days == -1 ? '' : 'en'}';
    } else if (days == 0) {
      return 'Läuft heute ab';
    } else if (days == 1) {
      return 'Morgen';
    } else if (days == 2) {
      return 'Übermorgen';
    } else {
      return 'In $days Tagen';
    }
  }

  @override
  List<Object?> get props => [id, name, expiryDate, addedDate, category, notes];
}