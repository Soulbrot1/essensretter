import 'package:flutter/material.dart';
import '../../../food_tracking/domain/entities/food.dart';
import '../services/reservation_service.dart';
import '../services/supabase_food_sync_service.dart';

class ReservationPopupDialog extends StatefulWidget {
  final Food food;
  final VoidCallback? onFoodRemoved;
  final VoidCallback? onReservationChanged;

  const ReservationPopupDialog({
    super.key,
    required this.food,
    this.onFoodRemoved,
    this.onReservationChanged,
  });

  @override
  State<ReservationPopupDialog> createState() => _ReservationPopupDialogState();
}

class _ReservationPopupDialogState extends State<ReservationPopupDialog> {
  List<FoodReservation> _reservations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Extract shared food ID from the Food entity
      final sharedFoodId = _getSharedFoodId();
      if (sharedFoodId == null) {
        setState(() {
          _error = 'Ungültige Lebensmittel-ID';
          _isLoading = false;
        });
        return;
      }

      final reservations = await ReservationService.getReservationsForFood(
        sharedFoodId,
      );

      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  String? _getSharedFoodId() {
    // Extract original supabase ID from shared food
    final foodId = widget.food.id;
    if (foodId.startsWith('shared_')) {
      final parts = foodId.split('_');
      if (parts.length >= 3) {
        return parts[1]; // The original supabase ID
      }
    }
    return null;
  }

  Future<void> _releaseReservation(FoodReservation reservation) async {
    try {
      final success = await ReservationService.releaseReservation(
        reservation.id,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservierung wurde freigegeben'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReservations(); // Reload
        widget.onReservationChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeFromList() async {
    try {
      // Remove from shared_foods table
      await SupabaseFoodSyncService.unshareFood(widget.food);

      // Also delete all associated reservations
      final sharedFoodId = _getSharedFoodId();
      if (sharedFoodId != null) {
        // Delete all reservations for this food
        await SupabaseFoodSyncService.client
            .from('food_reservations')
            .delete()
            .eq('shared_food_id', sharedFoodId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lebensmittel wurde aus der Liste entfernt'),
            backgroundColor: Colors.orange,
          ),
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      }

      // Force immediate UI update
      widget.onFoodRemoved?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Entfernen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFoodInfo(),
            const SizedBox(height: 20),
            Expanded(child: _buildBody()),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bookmark, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Reservierungen',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildFoodInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.fastfood, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.food.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
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
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!),
          ],
        ),
      );
    }

    if (_reservations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Keine Reservierungen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text(
              'Noch niemand hat dieses Lebensmittel reserviert',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final reservation = _reservations[index];
        return _buildReservationItem(reservation);
      },
    );
  }

  Widget _buildReservationItem(FoodReservation reservation) {
    final timeAgo = _getTimeAgo(reservation.reservedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green,
            child: Text(
              (reservation.reservedByName ?? reservation.reservedBy)[0]
                  .toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.reservedByName ?? reservation.reservedBy,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _releaseReservation(reservation),
            tooltip: 'Reservierung freigeben',
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _removeFromList,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text(
              'Aus Liste entfernen',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'gerade eben';
    } else if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes} Min';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours} Std';
    } else {
      return 'vor ${difference.inDays} Tag${difference.inDays == 1 ? '' : 'en'}';
    }
  }
}
