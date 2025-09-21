import 'package:supabase_flutter/supabase_flutter.dart';

/// Temporärer Test für RLS Policies - nur für Entwicklung
class RLSPolicyTester {
  static final supabase = Supabase.instance.client;

  static Future<void> testRLSPolicies() async {
    print('🧪 Teste RLS Policies...');

    try {
      // 1. Anonymous Auth testen
      print('\n1️⃣ Anonymous Auth Test:');
      await supabase.auth.signInAnonymously();
      final user = supabase.auth.currentUser;
      print('✅ Anonymous User ID: ${user?.id}');

      // 2. Haushalt erstellen testen
      print('\n2️⃣ Haushalt erstellen Test:');
      final household = await supabase
          .from('households')
          .insert({})
          .select()
          .single();
      print('✅ Haushalt erstellt: ${household['id']}');
      print('✅ Master Key: ${household['master_key']}');

      // 3. Eigene Haushalte abrufen (sollte funktionieren)
      print('\n3️⃣ Eigene Haushalte abrufen:');
      final ownHouseholds = await supabase.from('households').select();
      print('✅ Gefundene Haushalte: ${ownHouseholds.length}');

      // 4. Access Key erstellen
      print('\n4️⃣ Access Key erstellen:');
      final accessKey = await supabase
          .from('access_keys')
          .insert({
            'household_id': household['id'],
            'key_type': 'sub_user',
            'label': 'Test Sub-User',
          })
          .select()
          .single();
      print('✅ Access Key erstellt: ${accessKey['key']}');

      // 5. Lebensmittel hinzufügen
      print('\n5️⃣ Lebensmittel hinzufügen:');
      final food = await supabase
          .from('foods')
          .insert({
            'household_id': household['id'],
            'name': 'Test Milch',
            'expiry_date': '2025-01-30',
          })
          .select()
          .single();
      print('✅ Lebensmittel erstellt: ${food['name']}');

      // 6. Lebensmittel abrufen
      print('\n6️⃣ Lebensmittel abrufen:');
      final foods = await supabase.from('foods').select();
      print('✅ Gefundene Lebensmittel: ${foods.length}');

      print('\n🎉 Alle RLS Tests erfolgreich!');
    } catch (e) {
      print('❌ RLS Test Fehler: $e');
    }
  }

  /// Test mit zweitem Anonymous User (sollte keine Daten sehen)
  static Future<void> testCrossUserAccess() async {
    print('\n🔒 Teste Cross-User Security...');

    try {
      // Ausloggen und neuen Anonymous User erstellen
      await supabase.auth.signOut();
      await supabase.auth.signInAnonymously();
      final newUser = supabase.auth.currentUser;
      print('👤 Neuer User ID: ${newUser?.id}');

      // Versuche fremde Haushalte zu sehen (sollte leer sein)
      final households = await supabase.from('households').select();
      print('🔍 Sichtbare Haushalte: ${households.length} (sollte 0 sein)');

      // Versuche fremde Lebensmittel zu sehen (sollte leer sein)
      final foods = await supabase.from('foods').select();
      print('🔍 Sichtbare Lebensmittel: ${foods.length} (sollte 0 sein)');

      if (households.isEmpty && foods.isEmpty) {
        print('✅ Cross-User Security funktioniert!');
      } else {
        print('❌ SICHERHEITSLÜCKE! User kann fremde Daten sehen!');
      }
    } catch (e) {
      print('❌ Security Test Fehler: $e');
    }
  }
}
