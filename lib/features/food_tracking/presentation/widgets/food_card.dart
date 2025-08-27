import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/food.dart';
import '../bloc/food_bloc.dart';
import '../bloc/food_event.dart';
import 'food_tips_dialog.dart';

class FoodCard extends StatefulWidget {
  final Food food;
  const FoodCard({super.key, required this.food});

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  @override
  Widget build(BuildContext context) {
    final daysUntilExpiry = widget.food.daysUntilExpiry;
    final isExpired = widget.food.isExpired;
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
                context.read<FoodBloc>().add(
                  ToggleConsumedEvent(widget.food.id),
                );
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.food.isConsumed
                        ? Colors.green
                        : Colors.grey.shade400,
                    width: 1.5,
                  ),
                  color: widget.food.isConsumed
                      ? Colors.green
                      : Colors.transparent,
                ),
                child: widget.food.isConsumed
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Berechne die optimale Schriftgröße basierend auf der Textlänge
                      double fontSize = 16.0; // Maximale Größe
                      final textPainter = TextPainter(
                        text: TextSpan(
                          text: widget.food.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                        maxLines: 1,
                        textDirection: TextDirection.ltr,
                      )..layout(maxWidth: double.infinity);

                      // Wenn der Text zu breit ist, verkleinere die Schriftgröße
                      while (textPainter.width > constraints.maxWidth &&
                          fontSize > 10) {
                        fontSize -= 0.5;
                        textPainter.text = TextSpan(
                          text: widget.food.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        );
                        textPainter.layout(maxWidth: double.infinity);
                      }

                      return Text(
                        widget.food.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                          color: widget.food.isConsumed ? Colors.grey : null,
                        ),
                      );
                    },
                  ),
                  if (widget.food.isConsumed)
                    Positioned.fill(
                      child: Center(
                        child: Container(height: 1.5, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
            Stack(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showExpiryDatePicker(context, widget.food),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: urgencyColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: urgencyColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.food.expiryStatus,
                              style: TextStyle(
                                color: widget.food.isConsumed
                                    ? Colors.grey
                                    : Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              color: widget.food.isConsumed
                                  ? Colors.grey
                                  : urgencyColor,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              FoodTipsDialog(foodName: widget.food.name),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.food.isConsumed
                              ? Colors.grey.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: widget.food.isConsumed
                              ? Colors.grey
                              : Colors.blue,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _showDeleteConfirmation(context, widget.food);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.food.isConsumed
                              ? Colors.grey.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: widget.food.isConsumed
                              ? Colors.grey
                              : Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.food.isConsumed)
                  Positioned.fill(
                    child: Center(
                      child: Container(height: 1.5, color: Colors.grey),
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
    // Handle foods without expiry date
    if (days == 999) return Colors.grey;
    if (isExpired) return Colors.red.shade700;
    if (days <= 0) return Colors.red.shade700;
    if (days <= 1) return Colors.orange;
    if (days <= 3) return Colors.amber;
    return Colors.green;
  }

  void _showExpiryDatePicker(BuildContext context, Food food) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = food.expiryDate ?? now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? initialDate : now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('de', 'DE'),
      helpText: 'Haltbarkeitsdatum für ${food.name}',
      cancelText: 'Abbrechen',
      confirmText: 'Speichern',
    );

    if (pickedDate != null && context.mounted) {
      final updatedFood = food.copyWith(expiryDate: pickedDate);
      context.read<FoodBloc>().add(UpdateFoodEvent(updatedFood));
    }
  }

  void _showDeleteConfirmation(BuildContext context, Food food) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Lebensmittel wegwerfen?'),
          content: Text('Wurde "${food.name}" weggeworfen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                // Als weggeworfen markieren (wasDisposed = true)
                context.read<FoodBloc>().add(
                  DeleteFoodEvent(food.id, wasDisposed: true),
                );
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${food.name} wurde als weggeworfen markiert',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Ja, weggeworfen'),
            ),
          ],
        );
      },
    );
  }
}
