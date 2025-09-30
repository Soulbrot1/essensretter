import 'package:flutter_test/flutter_test.dart';
import 'package:essensretter/features/sharing/presentation/services/friend_service.dart';

void main() {
  group('FriendService', () {
    test('should validate correct User-ID format', () {
      // Valid IDs
      expect(FriendService.isValidUserId('ER-ABC12345'), true);
      expect(FriendService.isValidUserId('ER-XYZ98765'), true);
      expect(FriendService.isValidUserId('ER-A1B2C3D4'), true);

      // Invalid IDs
      expect(
        FriendService.isValidUserId('ABC12345'),
        false,
      ); // Missing ER- prefix
      expect(FriendService.isValidUserId('ER-ABC'), false); // Too short
      expect(FriendService.isValidUserId('ER-ABC123456'), false); // Too long
      expect(FriendService.isValidUserId('ER-abc12345'), false); // Lowercase
      expect(FriendService.isValidUserId(''), false);
      expect(FriendService.isValidUserId('ER-'), false);
    });

    test('FriendConnection should parse from Supabase data correctly', () {
      final data = {
        'user_id': 'ER-USER1234',
        'friend_id': 'ER-FRND5678',
        'friend_name': 'Anna',
        'status': 'connected',
        'created_at': '2025-01-01T10:00:00.000Z',
      };

      final connection = FriendConnection.fromSupabase(data);

      expect(connection.userId, 'ER-USER1234');
      expect(connection.friendId, 'ER-FRND5678');
      expect(connection.friendName, 'Anna');
      expect(connection.status, 'connected');
      expect(connection.createdAt.year, 2025);
    });

    test('FriendConnection should handle null friend_name', () {
      final data = {
        'user_id': 'ER-USER1234',
        'friend_id': 'ER-FRND5678',
        'friend_name': null,
        'status': 'connected',
        'created_at': '2025-01-01T10:00:00.000Z',
      };

      final connection = FriendConnection.fromSupabase(data);

      expect(connection.friendName, null);
    });
  });
}
