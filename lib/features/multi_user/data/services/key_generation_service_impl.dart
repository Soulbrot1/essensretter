import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../domain/services/key_generation_service.dart';

class KeyGenerationServiceImpl implements KeyGenerationService {
  static final _uuid = Uuid();
  static final _random = Random();

  @override
  String generateMasterKey() {
    return _uuid.v4();
  }

  @override
  String generateAccessKey() {
    return _uuid.v4();
  }

  @override
  String uuidToShortCode(String uuid) {
    // Entferne Bindestriche und nehme ersten 8 Zeichen
    final cleaned = uuid.replaceAll('-', '');
    final part1 = cleaned.substring(0, 4).toUpperCase();
    final part2 = cleaned.substring(4, 8);

    // Konvertiere zweiten Teil zu Zahlen (hex zu decimal)
    final numbers = part2
        .split('')
        .map((char) {
          final hexValue = int.tryParse(char, radix: 16) ?? 0;
          return (hexValue % 10).toString();
        })
        .join('');

    return '$part1-$numbers';
  }

  @override
  String shortCodeToUuid(String shortCode) {
    if (!isValidShortCode(shortCode)) {
      throw ArgumentError('Invalid short code format: $shortCode');
    }

    final parts = shortCode.split('-');
    final letters = parts[0].toLowerCase();
    final numbers = parts[1];

    // Rekonstruiere UUID (vereinfacht - nicht eindeutig umkehrbar)
    // In Production würden wir eine Mapping-Tabelle verwenden
    return '${letters}${numbers}0000-0000-0000-000000000000';
  }

  @override
  bool isValidShortCode(String shortCode) {
    // Format: ABCD-1234
    final regex = RegExp(r'^[A-Z]{4}-[0-9]{4}$');
    return regex.hasMatch(shortCode);
  }

  /// Generiert einen neuen Kurz-Code direkt (für bessere UX)
  String generateShortCode() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';

    final letterPart = List.generate(
      4,
      (index) => letters[_random.nextInt(letters.length)],
    ).join('');

    final numberPart = List.generate(
      4,
      (index) => numbers[_random.nextInt(numbers.length)],
    ).join('');

    return '$letterPart-$numberPart';
  }
}
