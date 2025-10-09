import 'package:flutter/material.dart';

enum SortOption { provider, alphabetical }

/// Filter Bar für OfferedFoodsBottomSheet
///
/// Enthält:
/// - Filter Chips (Verfügbar/Reserviert) mit Badge Counts
/// - Refresh Button
/// - Sort Menu (Nach Anbieter/Alphabetisch)
class OfferedFoodsFilterBar extends StatelessWidget {
  final String selectedFilter;
  final int availableCount;
  final int reservedCount;
  final SortOption sortOption;
  final Function(String) onFilterChanged;
  final Function(SortOption) onSortChanged;
  final VoidCallback onRefresh;

  const OfferedFoodsFilterBar({
    super.key,
    required this.selectedFilter,
    required this.availableCount,
    required this.reservedCount,
    required this.sortOption,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _buildFilterChipWithBadge(
            context,
            'Verfügbar',
            'available',
            availableCount,
          ),
          const SizedBox(width: 6),
          _buildFilterChipWithBadge(
            context,
            'Reserviert',
            'reserved',
            reservedCount,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: onRefresh,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            tooltip: 'Aktualisieren',
          ),
          _buildSortMenu(context),
        ],
      ),
    );
  }

  Widget _buildFilterChipWithBadge(
    BuildContext context,
    String label,
    String value,
    int? badgeCount,
  ) {
    final isSelected = selectedFilter == value;

    return Badge(
      isLabelVisible: badgeCount != null && badgeCount > 0,
      label: Text(
        badgeCount.toString(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      backgroundColor: isSelected
          ? Colors.green.shade700
          : Colors.grey.shade500,
      offset: const Offset(4, -4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            onFilterChanged(value);
          }
        },
        showCheckmark: false,
        selectedColor: Colors.green.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.green.shade700 : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildSortMenu(BuildContext context) {
    return PopupMenuButton<SortOption>(
      icon: const Icon(Icons.sort, size: 22),
      tooltip: 'Sortieren',
      padding: const EdgeInsets.all(8),
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
