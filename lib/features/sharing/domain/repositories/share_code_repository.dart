import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

/// Repository für Share-Code-Verwaltung
///
/// Share-Codes ersetzen die direkte RetterId-Teilung:
/// - Nutzer teilen einen Share-Code (z.B. "A3F9B2") statt ihrer RetterId
/// - Share-Codes können jederzeit regeneriert werden
/// - Alte Share-Codes werden dabei ungültig
/// - Bestehende Freundschaften bleiben erhalten
abstract class ShareCodeRepository {
  /// Holt den Share-Code für eine gegebene RetterId
  ///
  /// Gibt Left(ServerFailure) zurück wenn:
  /// - Netzwerkfehler auftritt
  /// - User nicht existiert
  ///
  /// Gibt Right(String) zurück mit dem Share-Code (6 Zeichen)
  Future<Either<Failure, String>> getShareCode(String retterId);

  /// Findet die RetterId zu einem gegebenen Share-Code
  ///
  /// Gibt Left(ServerFailure) zurück wenn:
  /// - Share-Code nicht existiert
  /// - Netzwerkfehler auftritt
  ///
  /// Gibt Right(String) zurück mit der RetterId
  Future<Either<Failure, String>> getRetterIdByShareCode(String shareCode);

  /// Generiert einen neuen Share-Code für eine RetterId
  ///
  /// Der alte Share-Code wird dabei ungültig gemacht.
  /// Bestehende Freundschaften bleiben unberührt.
  ///
  /// Gibt Left(ServerFailure) zurück wenn:
  /// - Netzwerkfehler auftritt
  /// - Code-Generierung fehlschlägt
  ///
  /// Gibt Right(String) zurück mit dem neuen Share-Code
  Future<Either<Failure, String>> regenerateShareCode(String retterId);

  /// Erstellt einen Share-Code für einen neuen User
  ///
  /// Wird automatisch beim ersten Login aufgerufen.
  /// Wenn bereits ein Share-Code existiert, wird dieser zurückgegeben.
  ///
  /// Gibt Left(ServerFailure) zurück bei Netzwerkfehler
  /// Gibt Right(String) zurück mit dem Share-Code
  Future<Either<Failure, String>> createShareCode(String retterId);
}
