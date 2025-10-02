import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_friend_names_service.dart';
import 'simple_user_identity_service.dart';
import 'supabase_food_sync_service.dart';

class FoodReservation {
  final String id;
  final String sharedFoodId;
  final String reservedBy;
  final String? reservedByName;
  final DateTime reservedAt;
  final String providerId;

  FoodReservation({
    required this.id,
    required this.sharedFoodId,
    required this.reservedBy,
    this.reservedByName,
    required this.reservedAt,
    required this.providerId,
  });

  factory FoodReservation.fromSupabase(Map<String, dynamic> data) {
    return FoodReservation(
      id: data['id'] ?? '',
      sharedFoodId: data['shared_food_id'] ?? '',
      reservedBy: data['reserved_by'] ?? '',
      reservedByName: data['reserved_by_name'],
      reservedAt: DateTime.parse(
        data['reserved_at'] ?? DateTime.now().toIso8601String(),
      ),
      providerId: data['provider_id'] ?? '',
    );
  }
}

class ReservationService {
  static SupabaseClient get client => SupabaseFoodSyncService.client;

  /// Create a new reservation for a shared food
  static Future<bool> createReservation({
    required String sharedFoodId,
    required String providerId,
  }) async {
    try {
      final currentUserId = await SimpleUserIdentityService.getCurrentUserId();
      if (currentUserId == null) {
        return false;
      }

      // Check if already reserved by this user
      final existing = await client
          .from('food_reservations')
          .select()
          .eq('shared_food_id', sharedFoodId)
          .eq('reserved_by', currentUserId)
          .maybeSingle();

      if (existing != null) {
        return true;
      }

      // For now, use user ID as display name until user sets their own name
      // TODO: Add user profile settings to allow users to set their display name
      final currentUserName = currentUserId; // Use ID as fallback name

      // Create new reservation
      await client.from('food_reservations').insert({
        'shared_food_id': sharedFoodId,
        'reserved_by': currentUserId,
        'reserved_by_name': currentUserName,
        'provider_id': providerId,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a reservation (by the user who reserved)
  static Future<bool> removeReservation(String sharedFoodId) async {
    try {
      final currentUserId = await SimpleUserIdentityService.getCurrentUserId();
      if (currentUserId == null) return false;

      await client
          .from('food_reservations')
          .delete()
          .eq('shared_food_id', sharedFoodId)
          .eq('reserved_by', currentUserId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get reservations for a specific shared food
  static Future<List<FoodReservation>> getReservationsForFood(
    String sharedFoodId,
  ) async {
    try {
      final data = await client
          .from('food_reservations')
          .select()
          .eq('shared_food_id', sharedFoodId)
          .order('reserved_at', ascending: false);

      final reservations = (data as List)
          .map((item) => FoodReservation.fromSupabase(item))
          .toList();

      // Load local names for reservations
      for (final reservation in reservations) {
        final localName = await LocalFriendNamesService.getFriendName(
          reservation.reservedBy,
        );
        if (localName != null) {
          // Update the object (create new with name)
          final index = reservations.indexOf(reservation);
          reservations[index] = FoodReservation(
            id: reservation.id,
            sharedFoodId: reservation.sharedFoodId,
            reservedBy: reservation.reservedBy,
            reservedByName: localName,
            reservedAt: reservation.reservedAt,
            providerId: reservation.providerId,
          );
        }
      }

      return reservations;
    } catch (e) {
      return [];
    }
  }

  /// Get all reservations for foods provided by current user
  static Future<Map<String, List<FoodReservation>>>
  getReservationsForProvider() async {
    try {
      final currentUserId = await SimpleUserIdentityService.getCurrentUserId();
      if (currentUserId == null) return {};

      final data = await client
          .from('food_reservations')
          .select()
          .eq('provider_id', currentUserId)
          .order('reserved_at', ascending: false);

      final reservations = (data as List)
          .map((item) => FoodReservation.fromSupabase(item))
          .toList();

      // Group by shared_food_id
      final grouped = <String, List<FoodReservation>>{};
      for (final reservation in reservations) {
        // Load local name
        final localName = await LocalFriendNamesService.getFriendName(
          reservation.reservedBy,
        );
        final reservationWithName = FoodReservation(
          id: reservation.id,
          sharedFoodId: reservation.sharedFoodId,
          reservedBy: reservation.reservedBy,
          reservedByName: localName ?? reservation.reservedBy,
          reservedAt: reservation.reservedAt,
          providerId: reservation.providerId,
        );

        grouped
            .putIfAbsent(reservation.sharedFoodId, () => [])
            .add(reservationWithName);
      }

      return grouped;
    } catch (e) {
      return {};
    }
  }

  /// Check if a food is reserved by current user
  static Future<bool> isReservedByCurrentUser(String sharedFoodId) async {
    try {
      final currentUserId = await SimpleUserIdentityService.getCurrentUserId();

      if (currentUserId == null) {
        return false;
      }

      final data = await client
          .from('food_reservations')
          .select()
          .eq('shared_food_id', sharedFoodId)
          .eq('reserved_by', currentUserId)
          .maybeSingle();

      final isReserved = data != null;

      return isReserved;
    } catch (e) {
      return false;
    }
  }

  /// Release a reservation (provider can free up the food)
  static Future<bool> releaseReservation(String reservationId) async {
    try {
      await client.from('food_reservations').delete().eq('id', reservationId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get reservation count for a shared food
  static Future<int> getReservationCount(String sharedFoodId) async {
    try {
      final data = await client
          .from('food_reservations')
          .select('id, reserved_by, reserved_at')
          .eq('shared_food_id', sharedFoodId);

      final count = (data as List).length;

      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Get reservation counts for multiple foods at once (efficient batch query)
  static Future<Map<String, int>> getReservationCounts(
    List<String> sharedFoodIds,
  ) async {
    try {
      if (sharedFoodIds.isEmpty) return {};

      final data = await client
          .from('food_reservations')
          .select('shared_food_id')
          .inFilter('shared_food_id', sharedFoodIds);

      final counts = <String, int>{};
      for (final foodId in sharedFoodIds) {
        counts[foodId] = 0;
      }

      for (final row in (data as List)) {
        final foodId = row['shared_food_id'] as String;
        counts[foodId] = (counts[foodId] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      return {};
    }
  }
}
