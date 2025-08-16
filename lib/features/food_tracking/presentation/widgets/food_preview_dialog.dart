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
  int? _editingNameIndex;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _foodItems = List.from(widget.foods);
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _removeFood(int index) {
    setState(() {
      _foodItems.removeAt(index);
    });
  }

  void _startEditingName(int index) {
    setState(() {
      _editingNameIndex = index;
      _nameController.text = _foodItems[index].name;
    });
  }

  void _saveEditedName(int index) {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        final oldFood = _foodItems[index];
        _foodItems[index] = Food(
          id: oldFood.id,
          name: _nameController.text.trim(),
          expiryDate: oldFood.expiryDate,
          addedDate: oldFood.addedDate,
          category: oldFood.category,
          notes: oldFood.notes,
        );
        _editingNameIndex = null;
      });
    }
  }

  void _cancelEditingName() {
    setState(() {
      _editingNameIndex = null;
    });
  }

  Future<void> _selectDate(int index) async {
    final currentFood = _foodItems[index];
    final initialDate = currentFood.expiryDate ?? DateTime.now().add(const Duration(days: 7));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('de', 'DE'),
    );
    
    if (picked != null) {
      setState(() {
        final oldFood = _foodItems[index];
        _foodItems[index] = Food(
          id: oldFood.id,
          name: oldFood.name,
          expiryDate: picked,
          addedDate: oldFood.addedDate,
          category: oldFood.category,
          notes: oldFood.notes,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenWidth - 24,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(20),
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
                        final isEditingName = _editingNameIndex == index;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: isEditingName
                                          ? Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _nameController,
                                                    autofocus: true,
                                                    decoration: const InputDecoration(
                                                      isDense: true,
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                      border: OutlineInputBorder(),
                                                    ),
                                                    onSubmitted: (_) => _saveEditedName(index),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                InkWell(
                                                  onTap: () => _saveEditedName(index),
                                                  child: const Icon(Icons.check, color: Colors.green, size: 20),
                                                ),
                                                const SizedBox(width: 4),
                                                InkWell(
                                                  onTap: _cancelEditingName,
                                                  child: const Icon(Icons.close, color: Colors.grey, size: 20),
                                                ),
                                              ],
                                            )
                                          : InkWell(
                                              onTap: () => _startEditingName(index),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      food.name,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.edit, size: 14, color: Colors.grey),
                                                ],
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    InkWell(
                                      onTap: () => _selectDate(index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: food.expiryDate != null ? Colors.grey.shade100 : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today, 
                                              size: 14, 
                                              color: food.expiryDate != null ? Colors.grey[700] : Colors.blue[700],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              food.expiryDate != null
                                                  ? DateFormat('dd.MM.yy').format(food.expiryDate!)
                                                  : '+ Datum',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: food.expiryDate != null ? Colors.grey[700] : Colors.blue[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _removeFood(index),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 22,
                                ),
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
