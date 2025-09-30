import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../food_tracking/domain/entities/food.dart' as food_tracking;
import '../services/simple_user_identity_service.dart';

class SupabaseFoodSyncService {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    _client ??= SupabaseClient(
      dotenv.env['SUPABASE_URL'] ?? '',
      dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    return _client!;
  }

  static Future<void> shareFood(food_tracking.Food food) async {
    try {
      final userId = await SimpleUserIdentityService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Update user's last activity
      await _updateUserActivity(userId);

      // Prüfe erst, ob das Food bereits geteilt ist
      final existingFood = await client
          .from('shared_foods')
          .select('id')
          .eq('user_id', userId)
          .eq('metadata->>local_id', food.id)
          .maybeSingle();

      if (existingFood != null) {
        print('DEBUG: Food already shared, updating instead: ${food.name}');
        await updateSharedFood(food);
        return;
      }

      final Map<String, dynamic> foodData = {
        'user_id': userId,
        'name': food.name,
        'expiry_date': food.expiryDate?.toIso8601String().split(
          'T',
        )[0], // Date only
        'category': food.category,
        'notes': food.notes,
        'quantity':
            null, // Future: could be extracted from notes or added as field
        'status': food.isConsumed ? 'consumed' : 'active',
        'metadata': {
          'local_id': food.id,
          'added_date': food.addedDate.toIso8601String(),
        },
      };

      final response = await client
          .from('shared_foods')
          .insert(foodData)
          .select('id')
          .single();

      print('DEBUG: Food shared to Supabase: ${response['id']}');
    } catch (e) {
      print('ERROR: Failed to share food to Supabase: $e');
      rethrow;
    }
  }

  static Future<void> unshareFood(food_tracking.Food food) async {
    try {
      final userId = await SimpleUserIdentityService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Delete the shared food by local_id in metadata
      await client
          .from('shared_foods')
          .delete()
          .eq('user_id', userId)
          .eq('metadata->>local_id', food.id);

      print('DEBUG: Food unshared from Supabase: ${food.id}');
    } catch (e) {
      print('ERROR: Failed to unshare food from Supabase: $e');
      rethrow;
    }
  }

  static Future<void> updateSharedFood(food_tracking.Food food) async {
    try {
      final userId = await SimpleUserIdentityService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final Map<String, dynamic> updates = {
        'name': food.name,
        'expiry_date': food.expiryDate?.toIso8601String().split(
          'T',
        )[0], // Date only
        'category': food.category,
        'notes': food.notes,
        'status': food.isConsumed ? 'consumed' : 'active',
        'updated_at': 'NOW()',
        'metadata': {
          'local_id': food.id,
          'added_date': food.addedDate.toIso8601String(),
        },
      };

      await client
          .from('shared_foods')
          .update(updates)
          .eq('user_id', userId)
          .eq('metadata->>local_id', food.id);

      print('DEBUG: Shared food updated in Supabase: ${food.id}');
    } catch (e) {
      print('ERROR: Failed to update shared food in Supabase: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getSharedFoods(
    String userId,
  ) async {
    try {
      final response = await client
          .from('shared_foods')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('added_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('ERROR: Failed to get shared foods from Supabase: $e');
      return [];
    }
  }

  static Future<bool> testConnection() async {
    try {
      await client.from('shared_foods').select('count').limit(1);
      return true;
    } catch (e) {
      print('ERROR: Supabase food sync connection test failed: $e');
      return false;
    }
  }

  static Future<void> _updateUserActivity(String userId) async {
    try {
      await client.from('user_activity').upsert({
        'user_id': userId,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('WARNING: Failed to update user activity: $e');
      // Non-critical error, don't rethrow
    }
  }

  /// Lösche alle Daten für inaktive User (>90 Tage keine Aktivität)
  static Future<void> cleanupInactiveUsers() async {
    try {
      // Diese Funktion sollte als Supabase Edge Function implementiert werden
      // oder als Cron Job auf dem Server laufen
      await client.rpc('cleanup_inactive_users');
    } catch (e) {
      print('WARNING: Cleanup of inactive users failed: $e');
    }
  }
}
