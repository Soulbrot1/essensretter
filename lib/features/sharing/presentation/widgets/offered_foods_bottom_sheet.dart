import 'package:flutter/material.dart';
import '../services/shared_foods_loader_service.dart';
import '../../../food_tracking/domain/entities/food.dart';
import 'offered_foods_header.dart';
import 'user_management_bar.dart';
import 'offered_foods_filter_bar.dart';
import 'offered_food_card.dart';
import 'provider_header_widget.dart';

class OfferedFoodsBottomSheet extends StatefulWidget {
  const OfferedFoodsBottomSheet({super.key});

  @override
  State<OfferedFoodsBottomSheet> createState() =>
      _OfferedFoodsBottomSheetState();
}

class _OfferedFoodsBottomSheetState extends State<OfferedFoodsBottomSheet> {
  bool _isLoading = true;
  List<Food> _offeredFoods = [];
  List<Food> _filteredFoods = [];
  String? _error;
  String _reservationFilter = 'available'; // 'available', 'reserved'
  int _reservedCount = 0;
  int _availableCount = 0;
  SortOption _sortOption = SortOption.provider;
  int _rebuildCounter = 0; // Counter to force rebuild of provider headers

  @override
  void initState() {
    super.initState();
    _loadOfferedFoods();
  }

  Future<void> _loadOfferedFoods() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sharedFoods =
          await SharedFoodsLoaderService.loadSharedFoodsFromFriends();

      // Apply reservation filter
      final filtered = await SharedFoodsLoaderService.filterByReservationStatus(
        sharedFoods,
        _reservationFilter,
      );

      // Count reserved and available foods
      final reserved = await SharedFoodsLoaderService.filterByReservationStatus(
        sharedFoods,
        'reserved',
      );

      final available =
          await SharedFoodsLoaderService.filterByReservationStatus(
            sharedFoods,
            'available',
          );

      setState(() {
        _offeredFoods = sharedFoods;
        _filteredFoods = _sortFoods(filtered);
        _reservedCount = reserved.length;
        _availableCount = available.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _applyReservationFilter(String filter) async {
    setState(() {
      _reservationFilter = filter;
      _isLoading = true;
    });

    final filtered = await SharedFoodsLoaderService.filterByReservationStatus(
      _offeredFoods,
      filter,
    );

    // Update reserved and available count
    final reserved = await SharedFoodsLoaderService.filterByReservationStatus(
      _offeredFoods,
      'reserved',
    );

    final available = await SharedFoodsLoaderService.filterByReservationStatus(
      _offeredFoods,
      'available',
    );

    setState(() {
      _filteredFoods = _sortFoods(filtered);
      _reservedCount = reserved.length;
      _availableCount = available.length;
      _isLoading = false;
    });
  }

  List<Food> _sortFoods(List<Food> foods) {
    final sorted = List<Food>.from(foods);

    switch (_sortOption) {
      case SortOption.provider:
        // Sort by provider name (extracted from notes)
        sorted.sort((a, b) {
          final providerA = _extractProviderName(a);
          final providerB = _extractProviderName(b);
          return providerA.compareTo(providerB);
        });
        break;
      case SortOption.alphabetical:
        // Sort alphabetically by food name
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return sorted;
  }

  String _extractProviderName(Food food) {
    if (food.notes != null && food.notes!.contains('Geteilt von: ')) {
      final startIndex =
          food.notes!.indexOf('Geteilt von: ') + 'Geteilt von: '.length;
      final endIndex = food.notes!.indexOf('\n', startIndex);
      return food.notes!.substring(
        startIndex,
        endIndex == -1 ? food.notes!.length : endIndex,
      );
    }
    return '';
  }

  /// Reapply current filter without showing loading indicator
  Future<void> _refreshFilterSilently() async {
    final filtered = await SharedFoodsLoaderService.filterByReservationStatus(
      _offeredFoods,
      _reservationFilter,
    );

    // Update reserved and available count
    final reserved = await SharedFoodsLoaderService.filterByReservationStatus(
      _offeredFoods,
      'reserved',
    );

    final available = await SharedFoodsLoaderService.filterByReservationStatus(
      _offeredFoods,
      'available',
    );

    if (mounted) {
      setState(() {
        _filteredFoods = _sortFoods(filtered);
        _reservedCount = reserved.length;
        _availableCount = available.length;
      });
    }
  }

  /// Trigger rebuild of provider headers (e.g., after messenger change)
  void _rebuildProviderHeaders() {
    if (mounted) {
      setState(() {
        _rebuildCounter++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.93,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const OfferedFoodsHeader(),
          OfferedFoodsFilterBar(
            selectedFilter: _reservationFilter,
            availableCount: _availableCount,
            reservedCount: _reservedCount,
            sortOption: _sortOption,
            onFilterChanged: _applyReservationFilter,
            onSortChanged: (option) {
              setState(() {
                _sortOption = option;
                _filteredFoods = _sortFoods(_filteredFoods);
              });
            },
            onRefresh: _loadOfferedFoods,
          ),
          Expanded(child: _buildBody()),
          UserManagementBar(onFriendsChanged: _rebuildProviderHeaders),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOfferedFoods,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_offeredFoods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Keine angebotenen Lebensmittel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Deine Friends haben noch nichts geteilt',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Show all foods in a flat list (no grouping)
    return _buildFlatList();
  }

  Widget _buildFlatList() {
    // In "Reserviert"-Ansicht: Nach Provider gruppieren
    if (_reservationFilter == 'reserved') {
      return _buildGroupedByProviderList();
    }

    // In "Verfügbar"-Ansicht: Normale Liste
    return RefreshIndicator(
      onRefresh: _loadOfferedFoods,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredFoods.length,
        itemBuilder: (context, index) {
          final food = _filteredFoods[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OfferedFoodCard(
              key: ValueKey(food.id),
              food: food,
              showProvider: true, // Show provider in "Verfügbar"
              isReservedView: false,
              onReservationChanged: _refreshFilterSilently,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupedByProviderList() {
    // Gruppiere Foods nach Provider
    final groupedFoods = <String, List<Food>>{};
    for (final food in _filteredFoods) {
      final providerName = _extractProviderName(food);
      groupedFoods.putIfAbsent(providerName, () => []).add(food);
    }

    // Sortiere Provider alphabetisch
    final sortedProviders = groupedFoods.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadOfferedFoods,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedProviders.length,
        itemBuilder: (context, providerIndex) {
          final providerName = sortedProviders[providerIndex];
          final providerFoods = groupedFoods[providerName]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider Header mit Messenger-Icon
                ProviderHeaderWidget(
                  key: ValueKey('${providerName}_$_rebuildCounter'),
                  providerName: providerName,
                  foods: providerFoods,
                ),
                const SizedBox(height: 8),
                // Lebensmittel-Liste ohne Provider-Namen
                ...providerFoods.map(
                  (food) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OfferedFoodCard(
                      key: ValueKey(food.id),
                      food: food,
                      showProvider: false, // Kein Provider in Reserviert
                      isReservedView: true,
                      onReservationChanged: _refreshFilterSilently,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
