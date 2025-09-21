abstract class SecureStorageService {
  /// Speichert Master-Key sicher auf Gerät
  Future<void> storeMasterKey(String masterKey);

  /// Lädt Master-Key vom Gerät
  Future<String?> getMasterKey();

  /// Löscht Master-Key (bei Haushalt verlassen)
  Future<void> deleteMasterKey();

  /// Prüft ob Master-Key existiert
  Future<bool> hasMasterKey();

  /// Speichert aktuellen Access-Key (Sub-User Mode)
  Future<void> storeCurrentAccessKey(String accessKey);

  /// Lädt aktuellen Access-Key
  Future<String?> getCurrentAccessKey();

  /// Löscht aktuellen Access-Key (zurück zu Master-Mode)
  Future<void> deleteCurrentAccessKey();

  /// Backup zu iCloud/Android Keychain
  Future<bool> backupToCloudKeychain();

  /// Restore von iCloud/Android Keychain
  Future<String?> restoreFromCloudKeychain();
}
