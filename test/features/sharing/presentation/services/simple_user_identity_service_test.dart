import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:essensretter/features/sharing/presentation/services/simple_user_identity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock storage for flutter_secure_storage
  final Map<String, String> secureStorageData = {};
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  group('SimpleUserIdentityService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      secureStorageData.clear();

      // Mock flutter_secure_storage MethodChannel using new API
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'read':
                final key = methodCall.arguments['key'] as String;
                return secureStorageData[key];
              case 'write':
                final key = methodCall.arguments['key'] as String;
                final value = methodCall.arguments['value'] as String;
                secureStorageData[key] = value;
                return null;
              case 'delete':
                final key = methodCall.arguments['key'] as String;
                secureStorageData.remove(key);
                return null;
              case 'readAll':
                return secureStorageData;
              default:
                return null;
            }
          });
    });

    tearDown(() {
      // Reset mock after each test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('should generate and save new User-ID on first call', () async {
      // act
      final userId1 = await SimpleUserIdentityService.ensureUserIdentity();
      final userId2 = await SimpleUserIdentityService.ensureUserIdentity();

      // assert
      expect(userId1, isNotEmpty);
      expect(userId1, startsWith('ER-'));
      expect(userId1.length, equals(11)); // ER- + 8 characters
      expect(userId1, equals(userId2)); // Should return same ID on second call
    });

    test('should return existing User-ID if already stored', () async {
      // arrange - Simulate existing User-ID
      const existingUserId = 'ER-TEST1234';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_identity_v2', existingUserId);

      // act
      final userId = await SimpleUserIdentityService.ensureUserIdentity();

      // assert
      expect(userId, equals(existingUserId));
    });

    test('should generate valid User-ID format', () async {
      // act
      final userId = await SimpleUserIdentityService.ensureUserIdentity();

      // assert
      expect(userId, startsWith('ER-'));
      expect(userId.length, equals(11));

      // Check if characters after ER- are valid (0-9, A-Z)
      final idPart = userId.substring(3);
      final validCharacters = RegExp(r'^[0-9A-Z]+$');
      expect(validCharacters.hasMatch(idPart), isTrue);
    });

    test('getCurrentUserId should return stored User-ID', () async {
      // arrange
      await SimpleUserIdentityService.ensureUserIdentity();

      // act
      final userId = await SimpleUserIdentityService.getCurrentUserId();

      // assert
      expect(userId, isNotNull);
      expect(userId, startsWith('ER-'));
    });

    test('getCurrentUserId should return null if no User-ID stored', () async {
      // act
      final userId = await SimpleUserIdentityService.getCurrentUserId();

      // assert
      expect(userId, isNull);
    });

    test('should generate unique User-IDs when storage is cleared', () async {
      // This test verifies that the random ID generation produces unique IDs
      // We need to clear BOTH storages between iterations
      final userIds = <String>{};

      for (int i = 0; i < 10; i++) {
        // Clear both storages completely
        SharedPreferences.setMockInitialValues({});
        secureStorageData.clear();

        // Generate new ID
        final userId = await SimpleUserIdentityService.ensureUserIdentity();
        userIds.add(userId);
      }

      // assert - All IDs should be unique due to random generation
      expect(userIds.length, equals(10));
    });

    test('should persist User-ID across service calls', () async {
      // act
      final userId1 = await SimpleUserIdentityService.ensureUserIdentity();

      // Simulate app restart by getting current ID
      final userId2 = await SimpleUserIdentityService.getCurrentUserId();

      final userId3 = await SimpleUserIdentityService.ensureUserIdentity();

      // assert
      expect(userId1, equals(userId2));
      expect(userId1, equals(userId3));
    });
  });
}
