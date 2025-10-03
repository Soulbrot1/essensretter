import 'package:flutter/material.dart';
import '../services/shared_foods_loader_service.dart';
import '../services/reservation_service.dart';
import '../../../food_tracking/domain/entities/food.dart';
import '../pages/friends_page.dart';

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
  Map<String, List<Food>> _groupedFoods = {};
  String? _error;
  String _reservationFilter = 'available'; // 'available', 'reserved'
  int _reservedCount = 0;

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

      // Count reserved foods
      final reserved = await SharedFoodsLoaderService.filterByReservationStatus(
        sharedFoods,
        'reserved',
      );

      setState(() {
        _offeredFoods = sharedFoods;
        _filteredFoods = filtered;
        _reservedCount = reserved.length;
        _groupedFoods = SharedFoodsLoaderService.groupSharedFoodsByProvider(
          filtered,
        );
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

    // Update reserved count
    final reserved = await SharedFoodsLoaderService.filterByReservationStatus(
      _offeredFoods,
      'reserved',
    );

    setState(() {
      _filteredFoods = filtered;
      _reservedCount = reserved.length;
      _groupedFoods = SharedFoodsLoaderService.groupSharedFoodsByProvider(
        filtered,
      );
      _isLoading = false;
    });
  }

  /// Reapply current filter without showing loading indicator
  Future<void> _refreshFilterSilently() async {
    final filtered = await SharedFoodsLoaderService.filterByReservationStatus(
      _offeredFoods,
      _reservationFilter,
    );

    // Update reserved count
    final reserved = await SharedFoodsLoaderService.filterByReservationStatus(
      _offeredFoods,
      'reserved',
    );

    if (mounted) {
      setState(() {
        _filteredFoods = filtered;
        _reservedCount = reserved.length;
        _groupedFoods = SharedFoodsLoaderService.groupSharedFoodsByProvider(
          filtered,
        );
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
          _buildHeader(),
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.handshake, color: Colors.blue, size: 28),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.people),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FriendsPage(),
                    ),
                  );
                },
                tooltip: 'Friends verwalten',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadOfferedFoods,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _buildFilterChip(
            'Verfügbar',
            'available',
            _filteredFoods.length - _reservedCount,
          ),
          const SizedBox(width: 8),
          _buildFilterChip('Reserviert', 'reserved', _reservedCount),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int? badgeCount) {
    final isSelected = _reservationFilter == value;
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
          _applyReservationFilter(value);
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

    // Always group by provider (no toggle anymore)
    return _buildGroupedList();
  }

  Widget _buildGroupedList() {
    return RefreshIndicator(
      onRefresh: _loadOfferedFoods,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groupedFoods.keys.length,
        itemBuilder: (context, index) {
          final friendName = _groupedFoods.keys.elementAt(index);
          final foods = _groupedFoods[friendName]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) const SizedBox(height: 24),
              _buildProviderHeader(friendName, foods.length),
              const SizedBox(height: 12),
              ...foods.map(
                (food) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OfferedFoodCard(
                    key: ValueKey(food.id),
                    food: food,
                    showProvider: false,
                    onReservationChanged: _refreshFilterSilently,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProviderHeader(String friendName, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: Text(
              friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              friendName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          Text(
            '$count ${count == 1 ? 'Artikel' : 'Artikel'}',
            style: TextStyle(fontSize: 14, color: Colors.blue.shade600),
          ),
        ],
      ),
    );
  }
}

// Widget für einzelne Food Card
class _OfferedFoodCard extends StatefulWidget {
  final Food food;
  final bool showProvider;
  final VoidCallback? onReservationChanged;

  const _OfferedFoodCard({
    super.key,
    required this.food,
    this.showProvider = true,
    this.onReservationChanged,
  });

  @override
  State<_OfferedFoodCard> createState() => _OfferedFoodCardState();
}

class _OfferedFoodCardState extends State<_OfferedFoodCard> {
  bool _isReserved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkReservationStatus();
  }

  Future<void> _checkReservationStatus() async {
    final sharedFoodId = _getSharedFoodId();

    if (sharedFoodId != null) {
      try {
        final isReserved = await ReservationService.isReservedByCurrentUser(
          sharedFoodId,
        );

        if (mounted) {
          setState(() {
            _isReserved = isReserved;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isReserved = false;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isReserved = false;
          _isLoading = false;
        });
      }
    }
  }

  String? _getSharedFoodId() {
    final foodId = widget.food.id;
    if (foodId.startsWith('shared_')) {
      final parts = foodId.split('_');
      if (parts.length >= 3) {
        return parts[1]; // The original supabase ID
      }
    }
    return null;
  }

  Future<void> _toggleReservation() async {
    if (_isLoading) {
      return;
    }

    final sharedFoodId = _getSharedFoodId();

    if (sharedFoodId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isReserved) {
        success = await ReservationService.removeReservation(sharedFoodId);
      } else {
        final providerId = SharedFoodsLoaderService.getFriendIdFromSharedFood(
          widget.food.id,
        );

        if (providerId == null) {
          throw Exception('Provider ID nicht gefunden');
        }
        success = await ReservationService.createReservation(
          sharedFoodId: sharedFoodId,
          providerId: providerId,
        );
      }

      if (success && mounted) {
        setState(() {
          _isReserved = !_isReserved;
          _isLoading = false;
        });

        // Notify parent to reload the list
        widget.onReservationChanged?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isReserved
                  ? '${widget.food.name} reserviert'
                  : 'Reservierung aufgehoben',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: _isReserved ? Colors.green : Colors.orange,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysUntilExpiry = widget.food.daysUntilExpiry;
    final isExpired = widget.food.isExpired;
    final urgencyColor = _getUrgencyColor(daysUntilExpiry, isExpired);

    // Extract provider name from notes
    String? providerName;
    if (widget.showProvider && widget.food.notes != null) {
      final notes = widget.food.notes!;
      if (notes.contains('Geteilt von: ')) {
        final startIndex =
            notes.indexOf('Geteilt von: ') + 'Geteilt von: '.length;
        final endIndex = notes.indexOf('\n', startIndex);
        providerName = notes.substring(
          startIndex,
          endIndex == -1 ? notes.length : endIndex,
        );
      }
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Reservation Checkbox
            GestureDetector(
              onTap: _isLoading ? null : _toggleReservation,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isLoading
                        ? Colors.grey.shade300
                        : _isReserved
                        ? Colors.green
                        : Colors.grey.shade400,
                    width: 1.5,
                  ),
                  color: _isLoading
                      ? Colors.grey.shade100
                      : _isReserved
                      ? Colors.green
                      : Colors.transparent,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.grey.shade600,
                        ),
                      )
                    : _isReserved
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Food name
            Expanded(
              child: Text(
                widget.food.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Provider Badge (wenn showProvider true)
            if (providerName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  providerName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Expiry date
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: urgencyColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: urgencyColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                widget.food.expiryStatus,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor(int days, bool isExpired) {
    if (days == 999) return Colors.grey;
    if (isExpired || days <= 0) return Colors.red.shade700;
    if (days <= 1) return Colors.orange;
    if (days <= 3) return Colors.amber;
    return Colors.green;
  }
}
