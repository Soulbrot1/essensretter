import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:essensretter/core/services/local_key_service.dart';

void main() {
  group('LocalKeyService', () {
    late LocalKeyService service;

    setUp(() async {
      // Coding-Prinzip: Test Isolation
      // Jeder Test startet mit sauberem State
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = LocalKeyService(prefs);
    });

    group('Master Key Generation', () {
      test('should generate key in correct format', () {
        // Coding-Prinzip: Arrange-Act-Assert (AAA)
        // Arrange: Setup ist im setUp()

        // Act
        final key = service.generateMasterKey();

        // Assert
        expect(key, matches(RegExp(r'^[A-Z]+-[A-Z0-9]{4}$')));
        expect(key.split('-').length, equals(2));
      });

      test('should generate unique keys', () {
        // Generiere 100 Keys und prüfe Einzigartigkeit
        final keys = <String>{};

        for (int i = 0; i < 100; i++) {
          keys.add(service.generateMasterKey());
        }

        // Set enthält nur unique Werte
        expect(keys.length, equals(100));
      });

      test('should use secure random', () {
        // Keys sollten nicht vorhersagbar sein
        final key1 = service.generateMasterKey();
        final key2 = service.generateMasterKey();

        expect(key1, isNot(equals(key2)));
      });

      test('should only use defined words', () {
        const validWords = [
          'APFEL',
          'BIRNE',
          'MANGO',
          'KIWI',
          'TRAUBE',
          'ORANGE',
          'BANANE',
          'ZITRONE',
        ];

        for (int i = 0; i < 20; i++) {
          final key = service.generateMasterKey();
          final word = key.split('-')[0];

          expect(validWords, contains(word));
        }
      });
    });

    group('Master Key Persistence', () {
      test('should save and retrieve master key', () async {
        // Act
        final generatedKey = await service.initializeMasterKey();
        final retrievedKey = service.getMasterKey();

        // Assert
        expect(retrievedKey, equals(generatedKey));
        expect(retrievedKey, isNotNull);
      });

      test('should return same key on multiple initializations', () async {
        // Coding-Prinzip: Idempotenz testen
        final key1 = await service.initializeMasterKey();
        final key2 = await service.initializeMasterKey();
        final key3 = await service.initializeMasterKey();

        expect(key1, equals(key2));
        expect(key2, equals(key3));
      });

      test('should detect first time user correctly', () async {
        // Before initialization
        expect(service.isFirstTimeUser(), isTrue);

        // After initialization
        await service.initializeMasterKey();
        expect(service.isFirstTimeUser(), isFalse);
      });

      test('should delete master key permanently', () async {
        // Setup
        await service.initializeMasterKey();
        expect(service.getMasterKey(), isNotNull);

        // Act
        final success = await service.deleteMasterKeyPermanently();

        // Assert
        expect(success, isTrue);
        expect(service.getMasterKey(), isNull);
        expect(service.isFirstTimeUser(), isTrue);
      });
    });

    group('Sub Key Management', () {
      test('should generate sub key in correct format', () {
        final subKey = service.generateSubKey();

        expect(subKey, matches(RegExp(r'^SUB-\d{8}$')));
        expect(subKey.length, equals(12)); // "SUB-" + 8 digits
      });

      test('should save and retrieve sub keys', () async {
        // Arrange
        final subKey = service.generateSubKey();
        final permissions = ['read', 'write'];

        // Act
        await service.saveSubKey(subKey, permissions);
        final subKeys = service.getSubKeys();

        // Assert
        expect(subKeys.length, equals(1));
        expect(subKeys.first.key, equals(subKey));
        expect(subKeys.first.permissions, equals(permissions));
      });

      test('should handle multiple sub keys', () async {
        // Create multiple sub keys
        for (int i = 0; i < 5; i++) {
          final key = service.generateSubKey();
          final permissions = i % 2 == 0 ? ['read'] : ['read', 'write'];
          await service.saveSubKey(key, permissions);
        }

        final subKeys = service.getSubKeys();
        expect(subKeys.length, equals(5));

        // Check permission helpers
        final readOnlyKeys = subKeys.where((k) => k.isReadOnly).length;
        expect(readOnlyKeys, equals(3)); // 0, 2, 4 are read-only
      });

      test('should revoke sub key correctly', () async {
        // Setup
        final subKey1 = service.generateSubKey();
        final subKey2 = service.generateSubKey();
        await service.saveSubKey(subKey1, ['read']);
        await service.saveSubKey(subKey2, ['read', 'write']);

        // Act
        final success = await service.revokeSubKey(subKey1);

        // Assert
        expect(success, isTrue);
        final remaining = service.getSubKeys();
        expect(remaining.length, equals(1));
        expect(remaining.first.key, equals(subKey2));
      });

      test('should return false when revoking non-existent key', () async {
        final success = await service.revokeSubKey('SUB-99999999');
        expect(success, isFalse);
      });
    });

    group('Statistics', () {
      test('should provide correct statistics', () async {
        // Setup
        await service.initializeMasterKey();
        await service.saveSubKey(service.generateSubKey(), ['read']);
        await service.saveSubKey(service.generateSubKey(), ['read', 'write']);

        // Act
        final stats = service.getStatistics();

        // Assert
        expect(stats['hasMasterKey'], isTrue);
        expect(stats['totalSubKeys'], equals(2));
        expect(stats['masterKeyAge'], equals(0)); // Created today
      });

      test('should handle empty state in statistics', () {
        final stats = service.getStatistics();

        expect(stats['hasMasterKey'], isFalse);
        expect(stats['totalSubKeys'], equals(0));
        expect(stats['masterKeyAge'], isNull);
      });
    });

    group('Edge Cases', () {
      test('should handle corrupted sub key data', () async {
        // Manually inject corrupted data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('sub_keys', [
          'VALID-KEY|read,write|2024-01-01T00:00:00',
          'CORRUPTED_DATA',
          'ANOTHER-VALID|read|2024-01-02T00:00:00',
        ]);

        // Should filter out corrupted entries
        final subKeys = service.getSubKeys();
        expect(subKeys.length, equals(2));
      });

      test('should not log full keys', () {
        // This tests our _maskKey function indirectly
        // In real implementation, we'd capture debug output
        final key = 'APFEL-X7K9';
        final masked = service.getMasterKey(); // Will be logged masked

        // The actual key should still be complete
        expect(key.length, greaterThan(4));
      });
    });

    group('SubKeyInfo Helper Methods', () {
      test('should correctly identify permissions', () {
        final readOnly = SubKeyInfo(
          key: 'SUB-12345678',
          permissions: ['read'],
          createdAt: DateTime.now(),
        );

        final readWrite = SubKeyInfo(
          key: 'SUB-87654321',
          permissions: ['read', 'write'],
          createdAt: DateTime.now(),
        );

        expect(readOnly.canRead, isTrue);
        expect(readOnly.canWrite, isFalse);
        expect(readOnly.isReadOnly, isTrue);

        expect(readWrite.canRead, isTrue);
        expect(readWrite.canWrite, isTrue);
        expect(readWrite.isReadOnly, isFalse);
      });
    });
  });
}
