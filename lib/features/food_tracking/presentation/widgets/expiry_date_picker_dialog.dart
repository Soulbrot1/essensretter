import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpiryDatePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final String foodName;
  final Function(DateTime?) onDateSelected;

  const ExpiryDatePickerDialog({
    super.key,
    this.initialDate,
    required this.foodName,
    required this.onDateSelected,
  });

  @override
  State<ExpiryDatePickerDialog> createState() => _ExpiryDatePickerDialogState();
}

class _ExpiryDatePickerDialogState extends State<ExpiryDatePickerDialog> {
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Haltbarkeitsdatum für ${widget.foodName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd.MM.yyyy').format(selectedDate!),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'ohne Datum',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.maxFinite,
            child: ElevatedButton.icon(
              onPressed: _showDatePicker,
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Datum wählen'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.maxFinite,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  selectedDate = null;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Datum entfernen'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onDateSelected(selectedDate);
            Navigator.of(context).pop();
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  Future<void> _showDatePicker() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = selectedDate ?? now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? initialDate : now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('de', 'DE'),
      helpText: 'Haltbarkeitsdatum wählen',
      cancelText: 'Abbrechen',
      confirmText: 'Auswählen',
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }
}
