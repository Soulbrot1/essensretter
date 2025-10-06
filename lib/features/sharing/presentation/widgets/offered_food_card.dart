import 'package:flutter/material.dart';
import '../services/shared_foods_loader_service.dart';
import '../services/reservation_service.dart';
import '../services/friend_service.dart';
import '../services/messenger_service.dart';
import '../../../food_tracking/domain/entities/food.dart';
import '../../../../core/utils/app_logger.dart';

/// Widget für einzelne Food Card in der Shared Foods Liste
///
/// Zeigt:
/// - Reservierungs-Checkbox
/// - Lebensmittel-Name mit Anbieter
/// - Messenger-Icon (wenn verfügbar)
/// - Ablaufdatum als Kreis
class OfferedFoodCard extends StatefulWidget {
  final Food food;
  final bool showProvider;
  final VoidCallback? onReservationChanged;

  const OfferedFoodCard({
    super.key,
    required this.food,
    this.showProvider = true,
    this.onReservationChanged,
  });

  @override
  State<OfferedFoodCard> createState() => _OfferedFoodCardState();
}

class _OfferedFoodCardState extends State<OfferedFoodCard> {
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
                  final currentContext = context;

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
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.maybeOf(currentContext)?.showSnackBar(
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
