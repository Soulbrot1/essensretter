import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/food_bloc.dart';
import '../bloc/food_event.dart';
import '../bloc/food_state.dart';
import '../../../../core/utils/tutorial_helper.dart';

class FoodFilterBar extends StatefulWidget {
  const FoodFilterBar({super.key});

  @override
  State<FoodFilterBar> createState() => _FoodFilterBarState();
}

class _FoodFilterBarState extends State<FoodFilterBar> {
  bool _isSearching = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<FoodBloc>().add(const SearchFoodsByNameEvent(''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodBloc, FoodState>(
      builder: (context, state) {
        final activeFilter = state is FoodLoaded ? state.activeFilter : null;
        final currentSort = state is FoodLoaded
            ? state.sortOption
            : SortOption.date;

        return Container(
          key: TutorialHelper.filterBarKey,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(
              0xFFE0F2E0,
            ), // Ausgewogenes helles Grün, harmonisch zur Header-Farbe
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isSearching
                ? Row(
                    key: const ValueKey('search'),
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Lebensmittel suchen...',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              context.read<FoodBloc>().add(SearchFoodsByNameEvent(value));
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _toggleSearch,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('normal'),
                    children: [
                      // Such-Button (Lupe)
                      IconButton(
                        onPressed: _toggleSearch,
                        icon: const Icon(Icons.search),
                        tooltip: 'Nach Namen suchen',
                        padding: const EdgeInsets.all(8),
                      ),

              // Active filter button (replaces both clock icon and filter indicator)
              Expanded(
                child: PopupMenuButton<int?>(
                  onSelected: (value) {
                    context.read<FoodBloc>().add(
                      FilterFoodsByExpiryEvent(value),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: activeFilter != null
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: activeFilter != null
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 16,
                            color: activeFilter != null
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              activeFilter != null
                                  ? _getFilterText(activeFilter)
                                  : 'Alle',
                              style: TextStyle(
                                fontSize: 13,
                                color: activeFilter != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: activeFilter != null
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem<int?>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(
                            activeFilter == null
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: activeFilter == null
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Alle'),
                        ],
                      ),
                    ),
                    PopupMenuItem<int?>(
                      value: 0,
                      child: Row(
                        children: [
                          Icon(
                            activeFilter == 0
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: activeFilter == 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Heute'),
                        ],
                      ),
                    ),
                    PopupMenuItem<int?>(
                      value: 1,
                      child: Row(
                        children: [
                          Icon(
                            activeFilter == 1
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: activeFilter == 1
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Morgen'),
                        ],
                      ),
                    ),
                    PopupMenuItem<int?>(
                      value: 2,
                      child: Row(
                        children: [
                          Icon(
                            activeFilter == 2
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: activeFilter == 2
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Übermorgen'),
                        ],
                      ),
                    ),
                    PopupMenuItem<int?>(
                      value: 3,
                      child: Row(
                        children: [
                          Icon(
                            activeFilter == 3
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: activeFilter == 3
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('3 Tage'),
                        ],
                      ),
                    ),
                    PopupMenuItem<int?>(
                      value: 4,
                      child: Row(
                        children: [
                          Icon(
                            activeFilter == 4
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: activeFilter == 4
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('4 Tage'),
                        ],
                      ),
                    ),
                    PopupMenuItem<int?>(
                      value: 5,
                      child: Row(
                        children: [
                          Icon(
                            activeFilter == 5
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: activeFilter == 5
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('5 Tage'),
                        ],
                      ),
                    ),
                    PopupMenuItem<int?>(
                      value: 6,
                      child: Row(
                        children: [
                          Icon(
                            activeFilter == 6
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: activeFilter == 6
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('6 Tage'),
                        ],
                      ),
                    ),
                    PopupMenuItem<int?>(
                      value: 7,
                      child: Row(
                        children: [
                          Icon(
                            activeFilter == 7
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: activeFilter == 7
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('7 Tage'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Sort Dropdown
              PopupMenuButton<SortOption>(
                onSelected: (value) {
                  context.read<FoodBloc>().add(SortFoodsEvent(value));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sort,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getSortText(currentSort),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem<SortOption>(
                    value: SortOption.date,
                    child: Row(
                      children: [
                        Icon(
                          currentSort == SortOption.date
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: currentSort == SortOption.date
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Nach Datum'),
                      ],
                    ),
                  ),
                  PopupMenuItem<SortOption>(
                    value: SortOption.alphabetical,
                    child: Row(
                      children: [
                        Icon(
                          currentSort == SortOption.alphabetical
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: currentSort == SortOption.alphabetical
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('A-Z'),
                      ],
                    ),
                  ),
                  PopupMenuItem<SortOption>(
                    value: SortOption.category,
                    child: Row(
                      children: [
                        Icon(
                          currentSort == SortOption.category
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: currentSort == SortOption.category
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Nach Kategorie'),
                      ],
                    ),
                  ),
                ],
              ),

              // Clear consumed foods button
              BlocBuilder<FoodBloc, FoodState>(
                builder: (context, state) {
                  // Check if there are any consumed foods
                  final hasConsumedFoods =
                      state is FoodLoaded &&
                      state.foods.any((food) => food.isConsumed);

                  if (!hasConsumedFoods) {
                    return const SizedBox.shrink();
                  }

                  return IconButton(
                    onPressed: () {
                      _showClearConsumedConfirmation(context);
                    },
                    icon: Icon(Icons.clear_all, color: Colors.red[600]),
                    tooltip: 'Verbrauchte Lebensmittel löschen',
                    padding: const EdgeInsets.all(8),
                  );
                },
              ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  String _getFilterText(int days) {
    switch (days) {
      case 0:
        return 'Heute';
      case 1:
        return 'Morgen';
      case 2:
        return 'Übermorgen';
      case 3:
        return '3 Tage';
      case 4:
        return '4 Tage';
      case 5:
        return '5 Tage';
      case 6:
        return '6 Tage';
      case 7:
        return '7 Tage';
      default:
        return '$days Tage';
    }
  }

  String _getSortText(SortOption sortOption) {
    switch (sortOption) {
      case SortOption.date:
        return 'Datum';
      case SortOption.alphabetical:
        return 'A-Z';
      case SortOption.category:
        return 'Kategorie';
    }
  }

  void _showClearConsumedConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Verbrauchte Lebensmittel löschen'),
          content: const Text(
            'Möchtest du alle durchgestrichenen (verbrauchten) Lebensmittel '
            'permanent aus der Liste entfernen?\n\n'
            '⚠️ Diese Aktion kann nicht rückgängig gemacht werden.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<FoodBloc>().add(const ClearConsumedFoodsEvent());
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
  }
}