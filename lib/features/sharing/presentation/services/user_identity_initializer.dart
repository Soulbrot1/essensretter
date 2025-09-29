import '../../../core/config/supabase_config.dart';
import '../../domain/usecases/generate_user_id.dart';
import '../../data/repositories/user_identity_repository_impl.dart';
import '../../data/repositories/sharing_repository_impl.dart';
import '../../data/datasources/sharing_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserIdentityInitializer {
  static Future<String> initializeUserIdentity() async {
    try {
      // 1. SharedPreferences initialisieren
      final prefs = await SharedPreferences.getInstance();

      // 2. User-ID Generator
      final generateUserId = GenerateUserId();

      // 3. User Identity Repository
      final userIdentityRepo = UserIdentityRepositoryImpl(
        prefs: prefs,
        generateUserId: generateUserId,
      );

      // 4. User Identity abrufen oder erstellen
      final userIdentity = await userIdentityRepo.getUserIdentity();

      print('DEBUG: User ID initialized: ${userIdentity.userId}');

      // 5. Optional: Bei Supabase registrieren (wenn verfügbar)
      try {
        final remoteDataSource = SharingRemoteDataSourceImpl(
          client: SupabaseConfig.client,
        );

        final sharingRepo = SharingRepositoryImpl(
          remoteDataSource: remoteDataSource,
        );

        final result = await sharingRepo.registerUser(userIdentity);
        result.fold(
          (failure) =>
              print('DEBUG: Supabase registration failed: ${failure.message}'),
          (_) => print('DEBUG: Supabase registration successful'),
        );
      } catch (e) {
        print('DEBUG: Supabase not available or failed: $e');
        // Nicht kritisch - App funktioniert auch ohne Supabase
      }

      return userIdentity.userId;
    } catch (e) {
      print('ERROR: User identity initialization failed: $e');
      rethrow;
    }
  }
}
