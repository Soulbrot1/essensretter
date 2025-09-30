import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:essensretter/features/sharing/presentation/services/simple_user_identity_service.dart';

void main() {
  group('SimpleUserIdentityService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
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

    test('should generate unique User-IDs', () async {
      // arrange - Clear any existing data
      SharedPreferences.setMockInitialValues({});

      // act - Generate multiple IDs
      final userIds = <String>{};
      for (int i = 0; i < 10; i++) {
        SharedPreferences.setMockInitialValues({}); // Reset for each iteration
        final userId = await SimpleUserIdentityService.ensureUserIdentity();
        userIds.add(userId);
      }

      // assert
      expect(userIds.length, equals(10)); // All should be unique
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
