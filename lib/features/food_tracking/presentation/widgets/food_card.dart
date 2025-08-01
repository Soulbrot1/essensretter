import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/food.dart';
import '../bloc/food_bloc.dart';
import '../bloc/food_event.dart';
import 'food_tips_dialog.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                context.read<FoodBloc>().add(ToggleConsumedEvent(food.id));
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: food.isConsumed ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                  color: food.isConsumed ? Colors.green : Colors.transparent,
                ),
                child: food.isConsumed
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: urgencyColor.withValues(alpha: 0.2),
              child: Icon(
                _getCategoryIcon(food.category),
                color: urgencyColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                food.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: food.isConsumed || isExpired 
                      ? TextDecoration.lineThrough 
                      : null,
                  color: food.isConsumed ? Colors.grey : null,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    food.expiryStatus,
                    style: TextStyle(
                      color: urgencyColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => FoodTipsDialog(foodName: food.name),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _showDeleteConfirmation(context, food);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor(int days, bool isExpired) {
    if (isExpired) return Colors.red.shade700;
    if (days <= 0) return Colors.red.shade700;
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