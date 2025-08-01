import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/food.dart';
import '../bloc/food_bloc.dart';
import '../bloc/food_event.dart';

class FoodCard extends StatelessWidget {
  final Food food;

  const FoodCard({
    super.key,
    required this.food,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilExpiry = food.daysUntilExpiry;
    final isExpired = food.isExpired;
    final urgencyColor = _getUrgencyColor(daysUntilExpiry, isExpired);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: urgencyColor.withValues(alpha: 0.2),
          child: Icon(
            _getCategoryIcon(food.category),
            color: urgencyColor,
          ),
        ),
        title: Text(
          food.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isExpired ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              food.expiryStatus,
              style: TextStyle(
                color: urgencyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (food.category != null)
              Text(
                food.category!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            _showDeleteConfirmation(context, food);
          },
        ),
      ),
    );
  }

  Color _getUrgencyColor(int days, bool isExpired) {
    if (isExpired) return Colors.red;
    if (days <= 0) return Colors.red;
    if (days <= 1) return Colors.orange;
    if (days <= 3) return Colors.amber;
    return Colors.green;
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Obst':
        return Icons.apple;
      case 'Gemüse':
        return Icons.eco;
      case 'Milchprodukte':
        return Icons.breakfast_dining;
      case 'Fleisch':
        return Icons.restaurant;
      case 'Brot & Backwaren':
        return Icons.bakery_dining;
      case 'Getränke':
        return Icons.local_drink;
      default:
        return Icons.fastfood;
    }
  }

  void _showDeleteConfirmation(BuildContext context, Food food) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Lebensmittel löschen'),
          content: Text('Möchten Sie "${food.name}" wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                context.read<FoodBloc>().add(DeleteFoodEvent(food.id));
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
  }
}