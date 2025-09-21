abstract class KeyGenerationService {
  /// Generiert einen neuen Master-Key (UUID)
  String generateMasterKey();

  /// Generiert einen neuen Access-Key (UUID)
  String generateAccessKey();

  /// Konvertiert UUID zu Kurz-Code (ABCD-1234)
  String uuidToShortCode(String uuid);

  /// Konvertiert Kurz-Code zurück zu UUID
  String shortCodeToUuid(String shortCode);

  /// Validiert Kurz-Code Format
  bool isValidShortCode(String shortCode);
}
