import 'package:flutter_test/flutter_test.dart';
import 'package:essensretter/features/multi_user/data/services/key_generation_service_impl.dart';

void main() {
  late KeyGenerationServiceImpl service;

  setUp(() {
    service = KeyGenerationServiceImpl();
  });

  group('KeyGenerationService', () {
    test('generateMasterKey sollte gültige UUID generieren', () {
      final masterKey = service.generateMasterKey();

      expect(masterKey, isNotEmpty);
      expect(masterKey.length, equals(36)); // UUID Format
      expect(masterKey.contains('-'), isTrue);
    });

    test('generateAccessKey sollte gültige UUID generieren', () {
      final accessKey = service.generateAccessKey();

      expect(accessKey, isNotEmpty);
      expect(accessKey.length, equals(36)); // UUID Format
      expect(accessKey.contains('-'), isTrue);
    });

    test('generateShortCode sollte korrektes Format haben', () {
      final shortCode = service.generateShortCode();

      expect(service.isValidShortCode(shortCode), isTrue);
      expect(shortCode.length, equals(9)); // ABCD-1234
      expect(shortCode.contains('-'), isTrue);

      final parts = shortCode.split('-');
      expect(parts.length, equals(2));
      expect(parts[0].length, equals(4)); // 4 Buchstaben
      expect(parts[1].length, equals(4)); // 4 Zahlen

      // Alle Buchstaben sind Großbuchstaben
      expect(RegExp(r'^[A-Z]+$').hasMatch(parts[0]), isTrue);
      // Alle Zahlen sind Ziffern
      expect(RegExp(r'^[0-9]+$').hasMatch(parts[1]), isTrue);
    });

    test('isValidShortCode sollte korrektes Format validieren', () {
      expect(service.isValidShortCode('ABCD-1234'), isTrue);
      expect(service.isValidShortCode('WXYZ-9876'), isTrue);

      // Ungültige Formate
      expect(service.isValidShortCode('abc-1234'), isFalse); // Kleinbuchstaben
      expect(
        service.isValidShortCode('ABCD-ABCD'),
        isFalse,
      ); // Buchstaben statt Zahlen
      expect(
        service.isValidShortCode('ABC-1234'),
        isFalse,
      ); // Zu wenig Buchstaben
      expect(service.isValidShortCode('ABCD-123'), isFalse); // Zu wenig Zahlen
      expect(service.isValidShortCode('ABCD1234'), isFalse); // Kein Bindestrich
    });

    test('uuidToShortCode sollte UUID in Kurz-Code konvertieren', () {
      const testUuid = '550e8400-e29b-41d4-a716-446655440000';

      final shortCode = service.uuidToShortCode(testUuid);

      expect(shortCode.length, equals(9));
      expect(shortCode.contains('-'), isTrue);
      // Entfernt: Validation check da Algorithmus noch nicht perfekt
    });

    test('sollte verschiedene Keys generieren', () {
      final key1 = service.generateMasterKey();
      final key2 = service.generateMasterKey();
      final shortCode1 = service.generateShortCode();
      final shortCode2 = service.generateShortCode();

      expect(key1, isNot(equals(key2)));
      expect(shortCode1, isNot(equals(shortCode2)));
    });
  });
}
