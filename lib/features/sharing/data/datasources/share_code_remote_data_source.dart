import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_logger.dart';

/// Remote Data Source für Share-Code-Operationen mit Supabase
///
/// Kommuniziert direkt mit der share_codes Tabelle in Supabase
abstract class ShareCodeRemoteDataSource {
  /// Holt den Share-Code für eine RetterId
  Future<String> getShareCode(String retterId);

  /// Findet RetterId anhand eines Share-Codes
  Future<String> getRetterIdByShareCode(String shareCode);

  /// Generiert einen neuen Share-Code (alter wird ungültig)
  Future<String> regenerateShareCode(String retterId);

  /// Erstellt Share-Code für neuen User
  Future<String> createShareCode(String retterId);
}

class ShareCodeRemoteDataSourceImpl implements ShareCodeRemoteDataSource {
  final SupabaseClient supabaseClient;

  ShareCodeRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<String> getShareCode(String retterId) async {
    try {
      final response = await supabaseClient
          .from('share_codes')
          .select('share_code')
          .eq('user_id', retterId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Share-Code nicht gefunden für User: $retterId');
      }

      return response['share_code'] as String;
    } catch (e) {
      AppLogger.error('Failed to get share code', error: e);
      rethrow;
    }
  }

  @override
  Future<String> getRetterIdByShareCode(String shareCode) async {
    try {
      final response = await supabaseClient
          .from('share_codes')
          .select('user_id')
          .eq('share_code', shareCode.toUpperCase())
          .maybeSingle();

      if (response == null) {
        throw Exception('Ungültiger Share-Code: $shareCode');
      }

      return response['user_id'] as String;
    } catch (e) {
      AppLogger.error('Failed to resolve share code', error: e);
      rethrow;
    }
  }

  @override
  Future<String> regenerateShareCode(String retterId) async {
    try {
      // Rufe Supabase-Funktion auf die einen neuen Code generiert
      final response = await supabaseClient.rpc('ensure_unique_share_code');

      final newShareCode = response as String;

      // Update den Share-Code für diesen User
      await supabaseClient.from('share_codes').upsert({
        'user_id': retterId,
        'share_code': newShareCode,
        'created_at': DateTime.now().toIso8601String(),
      });

      return newShareCode;
    } catch (e) {
      AppLogger.error('Failed to regenerate share code', error: e);
      rethrow;
    }
  }

  @override
  Future<String> createShareCode(String retterId) async {
    try {
      // Prüfe ob bereits ein Share-Code existiert
      final existing = await supabaseClient
          .from('share_codes')
          .select('share_code')
          .eq('user_id', retterId)
          .maybeSingle();

      if (existing != null) {
        // Share-Code existiert bereits
        return existing['share_code'] as String;
      }

      // Generiere neuen Share-Code
      final response = await supabaseClient.rpc('ensure_unique_share_code');

      final newShareCode = response as String;

      // Erstelle Eintrag
      await supabaseClient.from('share_codes').insert({
        'user_id': retterId,
        'share_code': newShareCode,
      });

      return newShareCode;
    } catch (e) {
      AppLogger.error('Failed to create share code', error: e);
      rethrow;
    }
  }
}
