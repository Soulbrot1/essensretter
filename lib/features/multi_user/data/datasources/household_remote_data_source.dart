import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../models/household_model.dart';

abstract class HouseholdRemoteDataSource {
  Future<HouseholdModel> createHousehold();
  Future<HouseholdModel?> getCurrentHousehold(String masterKey);
  Future<void> deleteHousehold(String householdId);
}

class HouseholdRemoteDataSourceImpl implements HouseholdRemoteDataSource {
  final SupabaseClient supabase;

  HouseholdRemoteDataSourceImpl({required this.supabase});

  @override
  Future<HouseholdModel> createHousehold() async {
    try {
      final response = await supabase
          .from('households')
          .insert({})
          .select()
          .single();

      return HouseholdModel.fromJson(response);
    } catch (e) {
      throw ServerException('Haushalt konnte nicht erstellt werden: $e');
    }
  }

  @override
  Future<HouseholdModel?> getCurrentHousehold(String masterKey) async {
    try {
      final response = await supabase
          .from('households')
          .select()
          .eq('master_key', masterKey)
          .maybeSingle();

      return response != null ? HouseholdModel.fromJson(response) : null;
    } catch (e) {
      throw ServerException('Haushalt konnte nicht geladen werden: $e');
    }
  }

  @override
  Future<void> deleteHousehold(String householdId) async {
    try {
      await supabase.from('households').delete().eq('id', householdId);
    } catch (e) {
      throw ServerException('Haushalt konnte nicht gelöscht werden: $e');
    }
  }
}
