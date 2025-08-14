import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/food.dart';

class FoodPreviewDialog extends StatefulWidget {
  final List<Food> foods;
  final Function(List<Food>) onConfirm;
  final VoidCallback onCancel;

  const FoodPreviewDialog({
    super.key,
    required this.foods,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<FoodPreviewDialog> createState() => _FoodPreviewDialogState();
}

class _FoodPreviewDialogState extends State<FoodPreviewDialog> {
  late List<Food> _foodItems;

  @override
  void initState() {
    super.initState();
    _foodItems = List.from(widget.foods);
  }

  void _removeFood(int index) {
    setState(() {
      _foodItems.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Erkannte Lebensmittel bestätigen',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: _foodItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Keine Lebensmittel mehr vorhanden',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _foodItems.length,
                      itemBuilder: (context, index) {
                        final food = _foodItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      food.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      food.expiryDate != null
                                          ? 'bis ${DateFormat('d.M.yyyy').format(food.expiryDate!)}'
                                          : 'ohne Datum',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeFood(index),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                tooltip: 'Lebensmittel entfernen',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Abbrechen',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _foodItems.isEmpty
                        ? null
                        : () => widget.onConfirm(_foodItems),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'Alle speichern',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
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
}
