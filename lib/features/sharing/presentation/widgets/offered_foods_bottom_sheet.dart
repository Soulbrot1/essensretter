import 'package:flutter/material.dart';
import '../services/shared_foods_loader_service.dart';
import '../services/reservation_service.dart';
import '../services/friend_service.dart';
import '../services/messenger_service.dart';
import '../../../food_tracking/domain/entities/food.dart';
import '../pages/friends_page.dart';
import '../../../../core/utils/app_logger.dart';

class OfferedFoodsBottomSheet extends StatefulWidget {
  const OfferedFoodsBottomSheet({super.key});

  @override
  State<OfferedFoodsBottomSheet> createState() =>
      _OfferedFoodsBottomSheetState();
}

enum SortOption { provider, alphabetical }

class _OfferedFoodsBottomSheetState extends State<OfferedFoodsBottomSheet> {
  bool _isLoading = true;
  List<Food> _offeredFoods = [];
  List<Food> _filteredFoods = [];
  String? _error;
  String _reservationFilter = 'available'; // 'available', 'reserved'
  int _reservedCount = 0;
  int _availableCount = 0;
  SortOption _sortOption = SortOption.provider;

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
          _buildFilterChip('Verfügbar', 'available', _availableCount),
          const SizedBox(width: 8),
          _buildFilterChip('Reserviert', 'reserved', _reservedCount),
          const Spacer(),
          // Sort menu
          PopupMenuButton<SortOption>(
            icon: Icon(Icons.sort, color: Colors.grey.shade600),
            tooltip: 'Sortieren',
            onSelected: (option) {
              setState(() {
                _sortOption = option;
                _filteredFoods = _sortFoods(_filteredFoods);
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem<SortOption>(
                value: SortOption.provider,
                child: Row(
                  children: [
                    Icon(
                      _sortOption == SortOption.provider
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _sortOption == SortOption.provider
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
                      _sortOption == SortOption.alphabetical
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _sortOption == SortOption.alphabetical
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
          ),
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

    // Show all foods in a flat list (no grouping)
    return _buildFlatList();
  }

  Widget _buildFlatList() {
    return RefreshIndicator(
      onRefresh: _loadOfferedFoods,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredFoods.length,
        itemBuilder: (context, index) {
          final food = _filteredFoods[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OfferedFoodCard(
              key: ValueKey(food.id),
              food: food,
              showProvider: true, // Now show provider on each card
              onReservationChanged: _refreshFilterSilently,
            ),
          );
        },
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
  FriendConnection? _friendConnection;

  @override
  void initState() {
    super.initState();
    _checkReservationStatus();
    _loadFriendConnection();
  }

  Future<void> _loadFriendConnection() async {
    final friendId = SharedFoodsLoaderService.getFriendIdFromSharedFood(
      widget.food.id,
    );

    if (friendId != null) {
      try {
        final friends = await FriendService.getFriends();
        final friend = friends.firstWhere(
          (f) => f.friendId == friendId,
          orElse: () => FriendConnection(
            userId: '',
            friendId: friendId,
            status: '',
            createdAt: DateTime.now(),
          ),
        );

        if (mounted) {
          setState(() {
            _friendConnection = friend;
          });
        }
      } catch (e) {
        // Fehler beim Laden - nicht kritisch
      }
    }
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

            // Food name with provider in parentheses
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(text: widget.food.name),
                    if (widget.showProvider && providerName != null)
                      TextSpan(
                        text: ' ($providerName)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Messenger icon (if available)
            if (_friendConnection?.preferredMessenger != null &&
                _friendConnection!.preferredMessenger!.icon != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  final messenger = _friendConnection!.preferredMessenger!;
                  final message =
                      'Hallo! Ich interessiere mich für dein Angebot: ${widget.food.name}';
                  final ctx = context;

                  AppLogger.debug(
                    'Messenger-Icon geklickt: ${messenger.displayName}',
                  );
                  AppLogger.debug('Nachricht: $message');

                  final success = await MessengerService.openMessenger(
                    messenger,
                    message: message,
                  );

                  AppLogger.debug('Messenger öffnen: success=$success');

                  if (!success && mounted) {
                    ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                      SnackBar(
                        content: Text(
                          '${messenger.displayName} konnte nicht geöffnet werden. Ist die App installiert?',
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: Icon(
                  _friendConnection!.preferredMessenger!.icon,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            ],

            const SizedBox(width: 12),

            // Expiry date as circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  isExpired ? '-${daysUntilExpiry.abs()}' : '$daysUntilExpiry',
                  style: TextStyle(
                    color: isExpired
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
