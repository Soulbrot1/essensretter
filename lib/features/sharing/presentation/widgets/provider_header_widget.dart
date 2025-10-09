import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../services/shared_foods_loader_service.dart';
import '../services/messenger_service.dart';
import '../../../food_tracking/domain/entities/food.dart';
import '../../../../core/utils/app_logger.dart';

/// Header-Widget für Provider-Gruppierung in Reserviert-Ansicht
///
/// Zeigt:
/// - Provider-Name (fett)
/// - Messenger-Icon (wenn verfügbar)
class ProviderHeaderWidget extends StatefulWidget {
  final String providerName;
  final List<Food> foods;

  const ProviderHeaderWidget({
    super.key,
    required this.providerName,
    required this.foods,
  });

  @override
  State<ProviderHeaderWidget> createState() => _ProviderHeaderWidgetState();
}

class _ProviderHeaderWidgetState extends State<ProviderHeaderWidget> {
  FriendConnection? _friendConnection;

  @override
  void initState() {
    super.initState();
    _loadFriendConnection();
  }

  Future<void> _loadFriendConnection() async {
    if (widget.foods.isEmpty) return;

    final firstFood = widget.foods.first;
    final friendId = SharedFoodsLoaderService.getFriendIdFromSharedFood(
      firstFood.id,
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
        AppLogger.error('Fehler beim Laden der Friend-Connection', error: e);
      }
    }
  }

  /// Sammelt alle reservierten Lebensmittel-Namen von diesem Provider
  List<String> _getReservedFoodNames() {
    return widget.foods.map((food) => food.name).toList();
  }

  Future<void> _openMessenger() async {
    if (_friendConnection?.preferredMessenger == null) return;

    final messenger = _friendConnection!.preferredMessenger!;
    final reservedFoods = _getReservedFoodNames();

    // Erstelle Draft-Nachricht mit allen reservierten Lebensmitteln
    String message;
    if (reservedFoods.isEmpty) {
      message = 'Hallo! Ich interessiere mich für deine Lebensmittel.';
    } else if (reservedFoods.length == 1) {
      message = 'Hallo! Ich habe reserviert:\n- ${reservedFoods[0]}';
    } else {
      final foodList = reservedFoods.map((name) => '- $name').join('\n');
      message = 'Hallo! Ich habe folgende Lebensmittel reserviert:\n$foodList';
    }

    AppLogger.debug('Messenger-Icon geklickt: ${messenger.displayName}');
    AppLogger.debug('Nachricht: $message');

    final success = await MessengerService.openMessenger(
      messenger,
      message: message,
    );

    AppLogger.debug('Messenger öffnen: success=$success');

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${messenger.displayName} konnte nicht geöffnet werden. Ist die App installiert?',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.providerName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // Messenger-Icon (wenn verfügbar)
          if (_friendConnection?.preferredMessenger != null &&
              _friendConnection!.preferredMessenger!.icon != null)
            GestureDetector(
              onTap: _openMessenger,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _friendConnection!.preferredMessenger!.icon,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
