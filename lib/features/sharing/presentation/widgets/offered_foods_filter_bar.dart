import 'package:flutter/material.dart';

enum SortOption { provider, alphabetical }

/// Filter Bar für OfferedFoodsBottomSheet
///
/// Enthält:
/// - Filter Chips (Verfügbar/Reserviert) mit Badge Counts
/// - Sort Menu (Nach Anbieter/Alphabetisch)
class OfferedFoodsFilterBar extends StatelessWidget {
  final String selectedFilter;
  final int availableCount;
  final int reservedCount;
  final SortOption sortOption;
  final Function(String) onFilterChanged;
  final Function(SortOption) onSortChanged;

  const OfferedFoodsFilterBar({
    super.key,
    required this.selectedFilter,
    required this.availableCount,
    required this.reservedCount,
    required this.sortOption,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _buildFilterChip(context, 'Verfügbar', 'available', availableCount),
          const SizedBox(width: 8),
          _buildFilterChip(context, 'Reserviert', 'reserved', reservedCount),
          const Spacer(),
          _buildSortMenu(context),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    int? badgeCount,
  ) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (badgeCount != null && badgeCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.green.shade700
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onFilterChanged(value);
        }
      },
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildSortMenu(BuildContext context) {
    return PopupMenuButton<SortOption>(
      icon: Icon(Icons.sort, color: Colors.grey.shade600),
      tooltip: 'Sortieren',
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        PopupMenuItem<SortOption>(
          value: SortOption.provider,
          child: Row(
            children: [
              Icon(
                sortOption == SortOption.provider
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: sortOption == SortOption.provider
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Nach Anbieter'),
            ],
          ),
        ),
        PopupMenuItem<SortOption>(
          value: SortOption.alphabetical,
          child: Row(
            children: [
              Icon(
                sortOption == SortOption.alphabetical
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: sortOption == SortOption.alphabetical
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Alphabetisch'),
            ],
          ),
        ),
      ],
    );
  }
}
