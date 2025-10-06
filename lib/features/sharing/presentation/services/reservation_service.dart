import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_friend_names_service.dart';
import 'simple_user_identity_service.dart';
import 'supabase_food_sync_service.dart';
import '../../../../core/utils/app_logger.dart';

class FoodReservation {
  final String id;
  final String sharedFoodId;
  final String reservedBy;
  final String? reservedByName;
  final DateTime reservedAt;
  final String providerId;
  final String? foodName; // Optional: name of the food

  FoodReservation({
    required this.id,
    required this.sharedFoodId,
    required this.reservedBy,
    this.reservedByName,
    required this.reservedAt,
    required this.providerId,
    this.foodName,
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
      foodName: data['food_name'],
    );
  }

  FoodReservation copyWith({
    String? id,
    String? sharedFoodId,
    String? reservedBy,
    String? reservedByName,
    DateTime? reservedAt,
    String? providerId,
    String? foodName,
  }) {
    return FoodReservation(
      id: id ?? this.id,
      sharedFoodId: sharedFoodId ?? this.sharedFoodId,
      reservedBy: reservedBy ?? this.reservedBy,
      reservedByName: reservedByName ?? this.reservedByName,
      reservedAt: reservedAt ?? this.reservedAt,
      providerId: providerId ?? this.providerId,
      foodName: foodName ?? this.foodName,
    );
  }
}

class ReservationService {
  static SupabaseClient get client => SupabaseFoodSyncService.client;

  /// Create a new reservation for a shared food
  /// Returns true if successful, false if food is already reserved by someone else
  static Future<bool> createReservation({
    required String sharedFoodId,
    required String providerId,
  }) async {
    try {
      final currentUserId = await SimpleUserIdentityService.getCurrentUserId();
      if (currentUserId == null) {
        return false;
      }

      // Check if food is already reserved (by ANYONE)
      final existingReservation = await client
          .from('food_reservations')
          .select()
          .eq('shared_food_id', sharedFoodId)
          .maybeSingle();

      if (existingReservation != null) {
        // Food is already reserved
        // If it's by current user, that's fine (already reserved)
        if (existingReservation['reserved_by'] == currentUserId) {
          return true;
        }
        // Reserved by someone else - cannot reserve
        return false;
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

  /// Get all reservations by a specific user (reserved_by) with food names
  static Future<List<FoodReservation>> getReservationsByUser(
    String userId,
  ) async {
    try {
      final currentUserId = await SimpleUserIdentityService.getCurrentUserId();
      if (currentUserId == null) {
        AppLogger.debug('currentUserId is null');
        return [];
      }

      AppLogger.debug(
        'Getting reservations for user $userId, provider $currentUserId',
      );

      // Get all reservations by this user for foods provided by current user
      final data = await client
          .from('food_reservations')
          .select()
          .eq('reserved_by', userId)
          .eq('provider_id', currentUserId)
          .order('reserved_at', ascending: false);

      AppLogger.debug('Raw data from query: $data');

      if ((data as List).isEmpty) {
        AppLogger.debug('No data returned from query');
        return [];
      }

      final reservations = <FoodReservation>[];

      for (final item in (data as List)) {
        AppLogger.debug('Processing item: $item');
        final sharedFoodId = item['shared_food_id'] as String;

        // Get the food name from shared_foods table
        final foodData = await client
            .from('shared_foods')
            .select('name')
            .eq('id', sharedFoodId)
            .maybeSingle();

        final foodName = foodData?['name'] as String?;
        AppLogger.debug(
          'Extracted food name: $foodName for food $sharedFoodId',
        );

        // Only add if food still exists (has a name)
        if (foodName != null) {
          reservations.add(
            FoodReservation.fromSupabase(item).copyWith(foodName: foodName),
          );
        } else {
          AppLogger.debug(
            'Skipping reservation for deleted food $sharedFoodId',
          );
        }
      }

      AppLogger.debug('Created ${reservations.length} reservations');

      // Load local name for the user
      final localName = await LocalFriendNamesService.getFriendName(userId);
      if (localName != null) {
        return reservations
            .map((r) => r.copyWith(reservedByName: localName))
            .toList();
      }

      return reservations;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error in getReservationsByUser',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
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
