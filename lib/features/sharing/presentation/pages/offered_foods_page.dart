import 'package:flutter/material.dart';
import '../services/shared_foods_loader_service.dart';
import '../services/friend_service.dart';
import '../services/messenger_service.dart';
import '../services/messenger_type.dart';
import '../../../food_tracking/domain/entities/food.dart';

class OfferedFoodsPage extends StatefulWidget {
  const OfferedFoodsPage({super.key});

  @override
  State<OfferedFoodsPage> createState() => _OfferedFoodsPageState();
}

class _OfferedFoodsPageState extends State<OfferedFoodsPage> {
  bool _isLoading = true;
  Map<String, List<Food>> _groupedFoods = {};
  String? _error;

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
      final grouped = SharedFoodsLoaderService.groupSharedFoodsByProvider(
        sharedFoods,
      );

      setState(() {
        _groupedFoods = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden der angebotenen Lebensmittel: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text(
          'Angebotene Lebensmittel',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOfferedFoods,
          ),
        ],
      ),
      body: _buildBody(),
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
            Text(
              'Fehler beim Laden',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOfferedFoods,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_groupedFoods.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOfferedFoods,
      child: _buildGroupedFoodsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Keine angebotenen Lebensmittel',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Deine Friends haben noch keine Lebensmittel geteilt.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedFoodsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groupedFoods.keys.length,
      itemBuilder: (context, index) {
        final friendName = _groupedFoods.keys.elementAt(index);
        final foods = _groupedFoods[friendName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 24),
            _buildFriendHeader(friendName, foods.length),
            const SizedBox(height: 12),
            ...foods.map(
              (food) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OfferedFoodCard(food: food),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFriendHeader(String friendName, int foodCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                Text(
                  '$foodCount ${foodCount == 1 ? 'Lebensmittel' : 'Lebensmittel'}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Spezielle FoodCard für angebotene Lebensmittel (read-only)
class OfferedFoodCard extends StatefulWidget {
  final Food food;

  const OfferedFoodCard({super.key, required this.food});

  @override
  State<OfferedFoodCard> createState() => _OfferedFoodCardState();
}

class _OfferedFoodCardState extends State<OfferedFoodCard> {
  Future<void> _contactProvider() async {
    try {
      // Extrahiere Provider-ID aus der Food-ID
      // Format: shared_SUPABASE_ID_PROVIDER_ID
      final providerId = SharedFoodsLoaderService.getFriendIdFromSharedFood(
        widget.food.id,
      );

      if (providerId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Provider-ID konnte nicht ermittelt werden'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Hole Friend-Informationen
      final friends = await FriendService.getFriends();
      final friend = friends.where((f) => f.friendId == providerId).firstOrNull;

      if (friend == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Friend nicht gefunden'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final messenger = friend.preferredMessenger ?? MessengerType.whatsapp;

      // Öffne Messenger
      final success = await MessengerService.openMessenger(messenger);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${messenger.displayName} konnte nicht geöffnet werden. Ist die App installiert?',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Öffnen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysUntilExpiry = widget.food.daysUntilExpiry;
    final isExpired = widget.food.isExpired;
    final urgencyColor = _getUrgencyColor(daysUntilExpiry, isExpired);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Icon für angebotenes Lebensmittel
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volunteer_activism,
                color: Colors.blue,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Lebensmittel Name
            Expanded(
              child: Text(
                widget.food.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            // Kontakt-Button
            IconButton(
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.blue,
                size: 20,
              ),
              onPressed: _contactProvider,
              tooltip: 'Kontaktieren',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),

            // Haltbarkeitsdatum
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
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
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
    if (isExpired) return Colors.red.shade700;
    if (days <= 0) return Colors.red.shade700;
    if (days <= 1) return Colors.orange;
    if (days <= 3) return Colors.amber;
    return Colors.green;
  }
}
