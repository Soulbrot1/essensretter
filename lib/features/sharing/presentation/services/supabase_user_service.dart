import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class SupabaseUserService {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    _client ??= SupabaseClient(
      dotenv.env['SUPABASE_URL'] ?? '',
      dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    return _client!;
  }

  static Future<void> registerUser(String userId) async {
    try {
      // Platform detection
      String platform = 'unknown';
      if (kIsWeb) {
        platform = 'web';
      } else if (Platform.isIOS) {
        platform = 'ios';
      } else if (Platform.isAndroid) {
        platform = 'android';
      }

      // App version (später aus package_info_plus holen)
      const appVersion = '1.0.0';

      // Device info (später erweitern mit device_info_plus)
      final deviceInfo = {
        'platform': platform,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Upsert user using the SQL function we created
      await client.rpc(
        'upsert_user',
        params: {
          'p_user_id': userId,
          'p_display_name': null,
          'p_app_version': appVersion,
          'p_platform': platform,
          'p_device_info': deviceInfo,
        },
      );

      // Optional: Verify the user was created/updated
      await client.from('users').select().eq('user_id', userId).single();
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> testConnection() async {
    try {
      // Test if we can reach Supabase
      final response = await client.rpc('test_schema_ready');
      return response == true;
    } catch (e) {
      return false;
    }
  }
}
