import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../food_tracking/domain/repositories/food_repository.dart';
import '../../../../core/utils/app_logger.dart';
import 'simple_user_identity_service.dart';

/// Service für automatisches Cleanup von verwaisten shared_foods Einträgen
///
/// Problem: Wenn User die App neu installiert, werden lokale Lebensmittel
/// gelöscht, aber shared_foods in Supabase bleiben bestehen.
///
/// Lösung: Beim App-Start alle shared_foods prüfen und nicht-existierende löschen
class SharedFoodsCleanupService {
  final SupabaseClient _supabaseClient;
  final FoodRepository _foodRepository;

  SharedFoodsCleanupService({
    required SupabaseClient supabaseClient,
    required FoodRepository foodRepository,
  }) : _supabaseClient = supabaseClient,
       _foodRepository = foodRepository;

  /// Bereinigt verwaiste shared_foods Einträge des aktuellen Users
  ///
  /// Wird aufgerufen:
  /// - Beim App-Start (in main.dart)
  /// - Beim Laden der OfferedFoodsBottomSheet
  ///
  /// Löscht alle shared_foods die nicht mehr in der lokalen Datenbank existieren
  Future<int> cleanupOrphanedSharedFoods() async {
    try {
      final userId = await SimpleUserIdentityService.getCurrentUserId();
      if (userId == null) {
        AppLogger.warning('Cleanup: Keine UserId gefunden');
        return 0;
      }

      AppLogger.info('🧹 Cleanup startet für UserId: $userId');

      // 1. Hole alle shared_foods des Users aus Supabase
      final response = await _supabaseClient
          .from('shared_foods')
          .select('id, metadata, name')
          .eq('user_id', userId);

      final sharedFoods = response as List<dynamic>;

      AppLogger.info(
        '📊 Supabase: ${sharedFoods.length} shared_foods gefunden',
      );

      if (sharedFoods.isEmpty) {
        AppLogger.info('✅ Cleanup: Keine shared_foods in Supabase');
        return 0;
      }

      // 2. Hole alle lokalen Foods (nicht nur IDs, sondern komplette Foods)
      final localFoodsResult = await _foodRepository.getAllFoods();
      final localFoods = localFoodsResult.fold(
        (failure) {
          AppLogger.error(
            '❌ Cleanup: Fehler beim Laden lokaler Foods',
            error: failure,
          );
          return <String, bool>{}; // Map<FoodId, isShared>
        },
        (foods) {
          AppLogger.info('📱 Lokal: ${foods.length} Lebensmittel gefunden');
          // Erstelle Map: food_id -> isShared Status
          return Map.fromEntries(foods.map((f) => MapEntry(f.id, f.isShared)));
        },
      );

      // 3. Finde verwaiste Einträge (nicht mehr lokal ODER isShared=false)
      final orphanedIds = <String>[];
      final orphanedDetails = <Map<String, dynamic>>[];

      for (final sharedFood in sharedFoods) {
        // Extrahiere local_id aus metadata
        final metadata = sharedFood['metadata'] as Map<String, dynamic>?;
        final localId = metadata?['local_id'] as String?;
        final name = sharedFood['name'] as String?;

        String? reason;

        if (localId == null) {
          reason = 'keine local_id in metadata';
        } else if (!localFoods.containsKey(localId)) {
          reason = 'nicht mehr lokal vorhanden (wurde gelöscht)';
        } else if (localFoods[localId] == false) {
          reason = 'isShared=false (Teilen deaktiviert)';
        }

        if (reason != null) {
          orphanedIds.add(sharedFood['id'] as String);
          orphanedDetails.add({
            'id': sharedFood['id'],
            'name': name ?? 'unbekannt',
            'local_id': localId ?? 'keine local_id',
            'reason': reason,
          });
        }
      }

      if (orphanedIds.isEmpty) {
        AppLogger.info('✅ Cleanup: Alle shared_foods sind synchron');
        return 0;
      }

      AppLogger.warning(
        '🗑️  Verwaiste Einträge gefunden (${orphanedIds.length}):',
      );
      for (final detail in orphanedDetails) {
        AppLogger.warning('   - ${detail['name']} (${detail['reason']})');
      }

      // 4. Lösche verwaiste Einträge aus Supabase
      await _supabaseClient
          .from('shared_foods')
          .delete()
          .inFilter('id', orphanedIds);

      AppLogger.info(
        '✅ Cleanup erfolgreich: ${orphanedIds.length} verwaiste shared_foods gelöscht',
      );
      return orphanedIds.length;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Cleanup-Fehler', error: e);
      AppLogger.error('Stack trace:', error: stackTrace);
      return 0;
    }
  }

  /// Bereinigt einen spezifischen local_id Eintrag
  ///
  /// Wird aufgerufen wenn ein Lebensmittel lokal gelöscht wird
  Future<void> cleanupSingleFood(String localFoodId) async {
    try {
      final userId = await SimpleUserIdentityService.getCurrentUserId();
      if (userId == null) return;

      // Lösche über metadata->local_id (JSONB Abfrage)
      await _supabaseClient
          .from('shared_foods')
          .delete()
          .eq('user_id', userId)
          .eq('metadata->>local_id', localFoodId);

      AppLogger.info('Cleanup: shared_food für local_id=$localFoodId gelöscht');
    } catch (e) {
      AppLogger.error('Cleanup-Fehler für einzelnes Food', error: e);
    }
  }
}
