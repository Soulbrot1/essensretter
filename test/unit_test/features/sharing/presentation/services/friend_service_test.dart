import 'package:flutter_test/flutter_test.dart';
import 'package:essensretter/features/sharing/presentation/services/friend_service.dart';
import 'package:essensretter/features/sharing/presentation/services/messenger_type.dart';

void main() {
  group('FriendConnection', () {
    test('fromSupabase should create FriendConnection from map', () {
      final data = {
        'user_id': 'ER-USER1234',
        'friend_id': 'ER-FRIEND12',
        'status': 'connected',
        'created_at': '2024-01-15T10:00:00Z',
      };

      final connection = FriendConnection.fromSupabase(data);

      expect(connection.userId, 'ER-USER1234');
      expect(connection.friendId, 'ER-FRIEND12');
      expect(connection.status, 'connected');
      expect(connection.friendName, isNull);
      expect(connection.preferredMessenger, isNull);
    });

    test('copyWith should update friendName', () {
      final connection = FriendConnection(
        userId: 'ER-USER1234',
        friendId: 'ER-FRIEND12',
        status: 'connected',
        createdAt: DateTime(2024, 1, 15),
      );

      final updated = connection.copyWith(friendName: 'Test Friend');

      expect(updated.friendName, 'Test Friend');
      expect(updated.friendId, connection.friendId);
    });

    test('copyWith should update preferredMessenger', () {
      final connection = FriendConnection(
        userId: 'ER-USER1234',
        friendId: 'ER-FRIEND12',
        status: 'connected',
        createdAt: DateTime(2024, 1, 15),
      );

      final updated = connection.copyWith(
        preferredMessenger: MessengerType.whatsapp,
      );

      expect(updated.preferredMessenger, MessengerType.whatsapp);
      expect(updated.friendId, connection.friendId);
    });

    test('copyWithLocalName should update friendName (deprecated)', () {
      final connection = FriendConnection(
        userId: 'ER-USER1234',
        friendId: 'ER-FRIEND12',
        status: 'connected',
        createdAt: DateTime(2024, 1, 15),
      );

      final updated = connection.copyWithLocalName('Old Friend');

      expect(updated.friendName, 'Old Friend');
    });
  });

  group('FriendService.isValidUserId', () {
    test('should return true for valid user ID', () {
      expect(FriendService.isValidUserId('ER-ABC12345'), true);
      expect(FriendService.isValidUserId('ER-12345678'), true);
      expect(FriendService.isValidUserId('ER-ZZZZZ999'), true);
    });

    test('should return false for invalid user ID', () {
      expect(FriendService.isValidUserId('ER-ABC123'), false); // too short
      expect(FriendService.isValidUserId('ER-ABC123456'), false); // too long
      expect(FriendService.isValidUserId('ABC12345678'), false); // no prefix
      expect(
        FriendService.isValidUserId('er-ABC12345'),
        false,
      ); // lowercase prefix
      expect(
        FriendService.isValidUserId('ER-abc12345'),
        false,
      ); // lowercase chars
      expect(FriendService.isValidUserId('ER-ABC@1234'), false); // special char
      expect(FriendService.isValidUserId(''), false); // empty
    });
  });

  group('FriendConnection equality and properties', () {
    test('should create connection with all properties', () {
      final connection = FriendConnection(
        userId: 'ER-USER1234',
        friendId: 'ER-FRIEND12',
        friendName: 'Test Friend',
        preferredMessenger: MessengerType.telegram,
        status: 'connected',
        createdAt: DateTime(2024, 1, 15),
      );

      expect(connection.userId, 'ER-USER1234');
      expect(connection.friendId, 'ER-FRIEND12');
      expect(connection.friendName, 'Test Friend');
      expect(connection.preferredMessenger, MessengerType.telegram);
      expect(connection.status, 'connected');
      expect(connection.createdAt, DateTime(2024, 1, 15));
    });

    test('copyWith should preserve unspecified properties', () {
      final connection = FriendConnection(
        userId: 'ER-USER1234',
        friendId: 'ER-FRIEND12',
        friendName: 'Original Name',
        preferredMessenger: MessengerType.whatsapp,
        status: 'connected',
        createdAt: DateTime(2024, 1, 15),
      );

      final updated = connection.copyWith(friendName: 'New Name');

      expect(updated.friendName, 'New Name');
      expect(updated.preferredMessenger, MessengerType.whatsapp); // preserved
      expect(updated.userId, connection.userId); // preserved
      expect(updated.status, connection.status); // preserved
    });
  });

  group('Edge cases and validation', () {
    test('isValidUserId should handle edge cases', () {
      expect(FriendService.isValidUserId('ER-00000000'), true);
      expect(FriendService.isValidUserId('ER-ZZZZZZZZ'), true);
      expect(FriendService.isValidUserId('ER-99999999'), true);
    });

    test('fromSupabase should handle minimal data', () {
      final data = {
        'user_id': 'ER-USER1234',
        'friend_id': 'ER-FRIEND12',
        'status': 'pending',
        'created_at': '2024-01-15T10:00:00Z',
      };

      final connection = FriendConnection.fromSupabase(data);

      expect(connection.status, 'pending');
      expect(connection.friendName, isNull);
      expect(connection.preferredMessenger, isNull);
    });

    test('copyWith with null values should preserve existing', () {
      final connection = FriendConnection(
        userId: 'ER-USER1234',
        friendId: 'ER-FRIEND12',
        friendName: 'Existing Name',
        preferredMessenger: MessengerType.signal,
        status: 'connected',
        createdAt: DateTime(2024, 1, 15),
      );

      final updated = connection.copyWith();

      expect(updated.friendName, 'Existing Name');
      expect(updated.preferredMessenger, MessengerType.signal);
    });
  });

  group('FriendConnection date handling', () {
    test('should parse ISO8601 datetime correctly', () {
      final data = {
        'user_id': 'ER-USER1234',
        'friend_id': 'ER-FRIEND12',
        'status': 'connected',
        'created_at': '2024-01-15T14:30:00.000Z',
      };

      final connection = FriendConnection.fromSupabase(data);

      expect(connection.createdAt.year, 2024);
      expect(connection.createdAt.month, 1);
      expect(connection.createdAt.day, 15);
      expect(connection.createdAt.hour, 14);
      expect(connection.createdAt.minute, 30);
    });

    test('should handle different datetime formats', () {
      final data = {
        'user_id': 'ER-USER1234',
        'friend_id': 'ER-FRIEND12',
        'status': 'connected',
        'created_at': '2024-12-31T23:59:59Z',
      };

      final connection = FriendConnection.fromSupabase(data);

      expect(connection.createdAt.year, 2024);
      expect(connection.createdAt.month, 12);
      expect(connection.createdAt.day, 31);
    });
  });

  group('FriendConnection status values', () {
    test('should support different status values', () {
      final statuses = ['connected', 'pending', 'blocked', 'disconnected'];

      for (final status in statuses) {
        final data = {
          'user_id': 'ER-USER1234',
          'friend_id': 'ER-FRIEND12',
          'status': status,
          'created_at': '2024-01-15T10:00:00Z',
        };

        final connection = FriendConnection.fromSupabase(data);
        expect(connection.status, status);
      }
    });
  });

  group('MessengerType integration', () {
    test('copyWith should handle all messenger types', () {
      final connection = FriendConnection(
        userId: 'ER-USER1234',
        friendId: 'ER-FRIEND12',
        status: 'connected',
        createdAt: DateTime(2024, 1, 15),
      );

      final messengerTypes = [
        MessengerType.whatsapp,
        MessengerType.telegram,
        MessengerType.signal,
        MessengerType.sms,
        MessengerType.none,
      ];

      for (final messengerType in messengerTypes) {
        final updated = connection.copyWith(preferredMessenger: messengerType);
        expect(updated.preferredMessenger, messengerType);
      }
    });
  });
}
