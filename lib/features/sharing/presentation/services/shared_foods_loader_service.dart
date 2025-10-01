import '../../../food_tracking/domain/entities/food.dart';
import 'friend_service.dart';
import 'supabase_food_sync_service.dart';

class SharedFoodsLoaderService {
  /// Lädt alle geteilten Lebensmittel von Friends und wandelt sie in Food-Entities um
  static Future<List<Food>> loadSharedFoodsFromFriends() async {
    try {
      // 1. Alle Friends laden
      final friends = await FriendService.getFriends();

      if (friends.isEmpty) {
        return [];
      }

      // 2. Für jeden Friend die geteilten Lebensmittel laden
      final List<Food> allSharedFoods = [];

      for (final friend in friends) {
        try {
          final sharedFoodsData = await SupabaseFoodSyncService.getSharedFoods(
            friend.friendId,
          );

          // 3. Supabase-Daten in Food-Entities umwandeln
          for (final foodData in sharedFoodsData) {
            final food = _convertSupabaseFoodToEntity(foodData, friend);
            if (food != null) {
              allSharedFoods.add(food);
            }
          }
        } catch (e) {
          print(
            'WARNING: Failed to load shared foods from ${friend.friendId}: $e',
          );
          // Fehler bei einem Friend soll nicht alle anderen blockieren
          continue;
        }
      }

      print(
        'DEBUG: Loaded ${allSharedFoods.length} shared foods from ${friends.length} friends',
      );
      return allSharedFoods;
    } catch (e) {
      print('ERROR: Failed to load shared foods from friends: $e');
      return [];
    }
  }

  /// Wandelt Supabase shared_foods Daten in Food Entity um
  static Food? _convertSupabaseFoodToEntity(
    Map<String, dynamic> foodData,
    FriendConnection friend,
  ) {
    try {
      final String id = 'shared_${foodData['id']}_${friend.friendId}';
      final String name = foodData['name'] ?? 'Unbekannt';

      // Parse expiry date
      DateTime? expiryDate;
      if (foodData['expiry_date'] != null) {
        try {
          expiryDate = DateTime.parse(foodData['expiry_date']);
        } catch (e) {
          print(
            'WARNING: Failed to parse expiry date for shared food: ${foodData['expiry_date']}',
          );
        }
      }

      // Parse added date from metadata
      DateTime addedDate = DateTime.now();
      if (foodData['metadata'] != null &&
          foodData['metadata']['added_date'] != null) {
        try {
          addedDate = DateTime.parse(foodData['metadata']['added_date']);
        } catch (e) {
          // Fallback to created_at from Supabase
          if (foodData['created_at'] != null) {
            try {
              addedDate = DateTime.parse(foodData['created_at']);
            } catch (e2) {
              print(
                'WARNING: Failed to parse dates for shared food, using current time',
              );
            }
          }
        }
      }

      final String category = foodData['category'] ?? 'Sonstiges';

      // Notes mit Friend-Info erweitern
      String? notes = foodData['notes'];
      final String friendName = friend.friendName ?? friend.friendId;
      final String sharedFromText = 'Geteilt von: $friendName';

      if (notes != null && notes.isNotEmpty) {
        notes = '$notes\n\n$sharedFromText';
      } else {
        notes = sharedFromText;
      }

      // Shared foods sind standardmäßig als "geteilt" markiert und nicht verbraucht
      return Food(
        id: id,
        name: name,
        expiryDate: expiryDate,
        addedDate: addedDate,
        category: category,
        notes: notes,
        isConsumed:
            false, // Shared foods sind nie "verbraucht" in der lokalen Ansicht
        isShared: true, // Wichtig: als geteilt markieren
      );
    } catch (e) {
      print('ERROR: Failed to convert shared food data to entity: $e');
      print('Food data: $foodData');
      return null;
    }
  }

  /// Prüft ob eine Food-ID zu einem geteilten Lebensmittel gehört
  static bool isSharedFoodId(String foodId) {
    return foodId.startsWith('shared_');
  }

  /// Extrahiert die Original-Supabase-ID aus einer Shared-Food-ID
  static String? getOriginalSupabaseId(String sharedFoodId) {
    if (!isSharedFoodId(sharedFoodId)) return null;

    try {
      // Format: shared_{supabase_id}_{friend_id}
      final parts = sharedFoodId.split('_');
      if (parts.length >= 3) {
        return parts[1]; // supabase_id ist der zweite Teil
      }
    } catch (e) {
      print(
        'ERROR: Failed to extract original Supabase ID from: $sharedFoodId',
      );
    }
    return null;
  }

  /// Extrahiert die Friend-ID aus einer Shared-Food-ID
  static String? getFriendIdFromSharedFood(String sharedFoodId) {
    if (!isSharedFoodId(sharedFoodId)) return null;

    try {
      // Format: shared_{supabase_id}_{friend_id}
      final parts = sharedFoodId.split('_');
      if (parts.length >= 3) {
        // Friend-ID ist alles nach dem zweiten Unterstrich
        return parts.sublist(2).join('_');
      }
    } catch (e) {
      print('ERROR: Failed to extract friend ID from: $sharedFoodId');
    }
    return null;
  }
}
