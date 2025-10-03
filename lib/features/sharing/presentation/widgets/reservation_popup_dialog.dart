import 'package:flutter/material.dart';
import '../../../food_tracking/domain/entities/food.dart';
import '../services/reservation_service.dart';
import '../services/supabase_food_sync_service.dart';
import '../services/shared_foods_loader_service.dart';
import '../services/simple_user_identity_service.dart';

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
  FoodReservation? _currentReservation;
  List<FoodReservation> _otherReservations = [];
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
      final sharedFoodId = await _getSharedFoodId();
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

      if (reservations.isEmpty) {
        setState(() {
          _currentReservation = null;
          _otherReservations = [];
          _isLoading = false;
        });
        return;
      }

      // Get the first reservation for this food
      final reservation = reservations.first;
      print('DEBUG Dialog: Current reservation by ${reservation.reservedBy}');

      // Load all other reservations by the same user
      final allUserReservations =
          await ReservationService.getReservationsByUser(
            reservation.reservedBy,
          );
      print(
        'DEBUG Dialog: Found ${allUserReservations.length} total reservations for user',
      );

      // Filter out the current food
      final otherReservations = allUserReservations
          .where((r) => r.sharedFoodId != sharedFoodId)
          .toList();
      print(
        'DEBUG Dialog: Filtered to ${otherReservations.length} other reservations',
      );

      setState(() {
        _currentReservation = reservation.copyWith(foodName: widget.food.name);
        _otherReservations = otherReservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _getSharedFoodId() async {
    // Check if this is a shared food from a friend (format: shared_SUPABASE_ID_FRIEND_ID)
    final extractedId = SharedFoodsLoaderService.getOriginalSupabaseId(
      widget.food.id,
    );
    if (extractedId != null) {
      return extractedId;
    }

    // Otherwise, this is OUR OWN food that we shared
    // We need to look it up in the shared_foods table by local_id
    try {
      final userId = await SimpleUserIdentityService.getCurrentUserId();
      if (userId == null) return null;

      final response = await SupabaseFoodSyncService.client
          .from('shared_foods')
          .select('id')
          .eq('user_id', userId)
          .eq("metadata->>local_id", widget.food.id) // JSON query for local_id
          .maybeSingle();

      if (response != null) {
        return response['id'] as String;
      }
    } catch (e) {
      // Failed to lookup
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
      final sharedFoodId = await _getSharedFoodId();
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
    if (_currentReservation == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.fastfood, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.food.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.green,
                  child: Text(
                    (_currentReservation!.reservedByName ??
                            _currentReservation!.reservedBy)[0]
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _currentReservation!.reservedByName ??
                      _currentReservation!.reservedBy,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.cancel_outlined,
              color: Colors.red,
              size: 20,
            ),
            onPressed: () => _releaseReservation(_currentReservation!),
            tooltip: 'Stornieren',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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

    if (_currentReservation == null) {
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

    // Show other reservations by the same user
    if (_otherReservations.isEmpty) {
      return const Center(
        child: Text(
          'Keine weiteren Reservierungen von diesem Nutzer',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Weitere Reservierungen von ${_currentReservation!.reservedByName ?? _currentReservation!.reservedBy}:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _otherReservations.length,
            itemBuilder: (context, index) {
              final reservation = _otherReservations[index];
              return _buildOtherReservationItem(reservation);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOtherReservationItem(FoodReservation reservation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.fastfood, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reservation.foodName ?? 'Unbekannt',
              style: const TextStyle(fontSize: 14),
            ),
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
}
