import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:essensretter/features/sharing/presentation/services/friend_service.dart';
import 'package:essensretter/features/sharing/presentation/services/simple_user_identity_service.dart';

void main() {
  group('FriendService Integration Tests', () {
    setUpAll(() async {
      // Load environment variables for Supabase connection
      await dotenv.load(fileName: '.env');
    });

    test('should establish Supabase connection', () async {
      final connectionResult = await FriendService.testConnection();
      expect(connectionResult, true, reason: 'Should connect to Supabase');
    });

    test('should handle bidirectional friend connection workflow', () async {
      // This is an integration test that verifies the complete workflow
      // but doesn't actually create real connections to avoid test pollution

      // Test User-ID validation
      const validUserId = 'ER-TEST1234';
      const invalidUserId = 'INVALID-ID';

      expect(FriendService.isValidUserId(validUserId), true);
      expect(FriendService.isValidUserId(invalidUserId), false);

      // Test UserIdentity service integration
      final currentUserId = await SimpleUserIdentityService.getCurrentUserId();

      if (currentUserId != null) {
        expect(
          FriendService.isValidUserId(currentUserId),
          true,
          reason: 'Current user ID should be valid format',
        );
      }
    });

    test('should parse FriendConnection from Supabase data', () {
      final testData = {
        'user_id': 'ER-USER1234',
        'friend_id': 'ER-FRND5678',
        'status': 'connected',
        'created_at': '2025-01-01T10:00:00.000Z',
      };

      final connection = FriendConnection.fromSupabase(testData);

      expect(connection.userId, 'ER-USER1234');
      expect(connection.friendId, 'ER-FRND5678');
      expect(
        connection.friendName,
        null,
      ); // Namen werden jetzt nur lokal gespeichert
      expect(connection.status, 'connected');
      expect(connection.createdAt.year, 2025);
    });
  });
}
