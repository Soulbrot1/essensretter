import 'package:flutter/material.dart';
import '../services/shared_foods_loader_service.dart';
import '../services/reservation_service.dart';
import '../../../food_tracking/domain/entities/food.dart';

/// Widget für einzelne Food Card in der Shared Foods Liste
///
/// Zeigt:
/// - Reservierungs-Checkbox
/// - Lebensmittel-Name mit Anbieter
/// - Ablaufdatum als Kreis
class OfferedFoodCard extends StatefulWidget {
  final Food food;
  final bool showProvider;
  final bool isReservedView;
  final VoidCallback? onReservationChanged;

  const OfferedFoodCard({
    super.key,
    required this.food,
    this.showProvider = true,
    this.isReservedView = false,
    this.onReservationChanged,
  });

  @override
  State<OfferedFoodCard> createState() => _OfferedFoodCardState();
}

class _OfferedFoodCardState extends State<OfferedFoodCard> {
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
