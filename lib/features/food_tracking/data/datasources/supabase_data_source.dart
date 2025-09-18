import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_model.dart';
import '../../../../core/services/local_key_service.dart';

abstract class SupabaseDataSource {
  Future<List<FoodModel>> getAllFoods();
  Future<FoodModel> addFood(FoodModel food);
  Future<void> deleteFood(String id);
  Future<FoodModel> updateFood(FoodModel food);
  Future<void> syncToCloud();
  Future<void> syncFromCloud();
  Future<String> createHousehold(String masterKey, String? name);
  Future<void> addSubKeyToHousehold(
    String masterKey,
    String subKey,
    String? name,
    List<String> permissions,
  );
  Future<bool> householdExists(String masterKey);
  Future<bool> validateSubKey(String masterKey, String subKey);
}

class SupabaseDataSourceImpl implements SupabaseDataSource {
  final SupabaseClient _client;
  final LocalKeyService _keyService;

  SupabaseDataSourceImpl(this._client, this._keyService);

  /// Setzt die aktuellen Schlüssel für Row Level Security
  Future<void> _setRLSContext() async {
    // RLS ist deaktiviert, also brauchen wir keinen Context zu setzen
    // Diese Methode ist ein Platzhalter für später wenn RLS aktiviert wird
    return;
  }

  /// Holt die Household ID basierend auf dem aktuellen Schlüssel
  Future<String?> _getCurrentHouseholdId() async {
    await _setRLSContext();

    final currentHousehold = _keyService.getCurrentHousehold();
    if (currentHousehold == null) {
      print('No current household found in keyService');
      return null;
    }

    print(
      'Looking for household with master_key: ${currentHousehold.masterKey.substring(0, 4)}****',
    );

    final response = await _client
        .from('households')
        .select('id')
        .eq('master_key', currentHousehold.masterKey)
        .maybeSingle();

    print('Household lookup result: $response');
    return response?['id'];
  }

  @override
  Future<List<FoodModel>> getAllFoods() async {
    try {
      await _setRLSContext();

      // Hole die aktuelle Household ID
      final householdId = await _getCurrentHouseholdId();
      if (householdId == null) {
        print('No household found, returning empty list');
        return [];
      }

      print('Loading foods for household: $householdId');

      // Lade nur Lebensmittel die zu diesem Haushalt gehören
      final response = await _client
          .from('foods')
          .select('*')
          .eq('household_id', householdId)
          .order('expiry_date', ascending: true);

      print('Found ${(response as List).length} foods for this household');

      return response.map((food) => FoodModel.fromSupabase(food)).toList();
    } catch (e) {
      print('Error loading foods: $e');
      throw Exception('Fehler beim Laden der Lebensmittel: $e');
    }
  }

  @override
  Future<FoodModel> addFood(FoodModel food) async {
    try {
      print('Adding food to Supabase: ${food.name}');

      final householdId = await _getCurrentHouseholdId();
      print('Current household ID: $householdId');

      if (householdId == null) {
        throw Exception('Kein aktiver Haushalt gefunden');
      }

      final currentHousehold = _keyService.getCurrentHousehold();
      final addedBySubKey = currentHousehold?.isOwn == false
          ? currentHousehold?.subKey
          : null;

      final foodData = food.toSupabaseMap()
        ..['household_id'] = householdId
        ..['added_by_sub_key'] = addedBySubKey;

      print('Food data to insert: $foodData');

      final response = await _client
          .from('foods')
          .insert(foodData)
          .select()
          .single();

      print('Food added successfully: ${response['id']}');
      return FoodModel.fromSupabase(response);
    } catch (e) {
      print('Failed to add food: $e');
      throw Exception('Fehler beim Hinzufügen des Lebensmittels: $e');
    }
  }

  @override
  Future<void> deleteFood(String id) async {
    try {
      await _setRLSContext();

      await _client.from('foods').delete().eq('id', id);
    } catch (e) {
      throw Exception('Fehler beim Löschen des Lebensmittels: $e');
    }
  }

  @override
  Future<FoodModel> updateFood(FoodModel food) async {
    try {
      await _setRLSContext();

      final response = await _client
          .from('foods')
          .update(food.toSupabaseMap())
          .eq('id', food.id)
          .select()
          .single();

      return FoodModel.fromSupabase(response);
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren des Lebensmittels: $e');
    }
  }

  @override
  Future<void> syncToCloud() async {
    // Lokale Daten zur Cloud synchronisieren
    // Wird später implementiert wenn lokale Datenbank noch existiert
    throw UnimplementedError('Sync to cloud noch nicht implementiert');
  }

  @override
  Future<void> syncFromCloud() async {
    // Cloud Daten lokal cachen
    // Wird später implementiert für Offline-Funktionalität
    throw UnimplementedError('Sync from cloud noch nicht implementiert');
  }

  /// Erstellt einen neuen Haushalt in Supabase
  @override
  Future<String> createHousehold(String masterKey, String? name) async {
    try {
      print('Creating household in Supabase: ${masterKey.substring(0, 4)}****');
      final response = await _client
          .from('households')
          .insert({'master_key': masterKey, 'name': name})
          .select('id')
          .single();

      print('Household created successfully: ${response['id']}');
      return response['id'];
    } catch (e) {
      print('Failed to create household in Supabase: $e');
      throw Exception('Fehler beim Erstellen des Haushalts: $e');
    }
  }

  /// Fügt einen Sub-Key zu einem Haushalt hinzu
  @override
  Future<void> addSubKeyToHousehold(
    String masterKey,
    String subKey,
    String? name,
    List<String> permissions,
  ) async {
    try {
      // Hole Household ID
      final householdResponse = await _client
          .from('households')
          .select('id')
          .eq('master_key', masterKey)
          .single();

      await _client.from('sub_keys').insert({
        'household_id': householdResponse['id'],
        'sub_key': subKey,
        'name': name,
        'permissions': permissions,
      });
    } catch (e) {
      throw Exception('Fehler beim Hinzufügen des Sub-Keys: $e');
    }
  }

  /// Prüft ob ein Master-Key existiert
  @override
  Future<bool> householdExists(String masterKey) async {
    try {
      final response = await _client
          .from('households')
          .select('id')
          .eq('master_key', masterKey)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Validiert einen Sub-Key
  @override
  Future<bool> validateSubKey(String masterKey, String subKey) async {
    try {
      final response = await _client
          .from('sub_keys')
          .select('sk.id')
          .eq('sub_key', subKey)
          .eq('is_active', true)
          .eq('households.master_key', masterKey)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}
