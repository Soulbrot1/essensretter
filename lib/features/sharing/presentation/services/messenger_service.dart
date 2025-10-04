import 'package:url_launcher/url_launcher.dart';
import 'messenger_type.dart';

/// Service zum Öffnen von Messenger-Apps
class MessengerService {
  /// Öffnet den angegebenen Messenger
  ///
  /// [messenger] - Der zu öffnende Messenger-Typ
  /// [message] - Optionale Nachricht, die vorausgefüllt werden soll
  ///
  /// Returns true wenn erfolgreich geöffnet, false bei Fehler
  static Future<bool> openMessenger(
    MessengerType messenger, {
    String? message,
  }) async {
    if (messenger == MessengerType.none) {
      return false;
    }

    try {
      final Uri url = _buildUrl(messenger, message);

      // Prüfe ob der Messenger verfügbar ist
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Erstellt die URL für den jeweiligen Messenger
  static Uri _buildUrl(MessengerType messenger, String? message) {
    final encodedMessage = message != null ? Uri.encodeComponent(message) : '';

    switch (messenger) {
      case MessengerType.whatsapp:
        // WhatsApp: whatsapp://send?text=message
        return Uri.parse(
          'whatsapp://send${message != null ? '?text=$encodedMessage' : ''}',
        );

      case MessengerType.telegram:
        // Telegram: tg://msg?text=message
        return Uri.parse(
          'tg://msg${message != null ? '?text=$encodedMessage' : ''}',
        );

      case MessengerType.signal:
        // Signal: sgnl:// (Signal hat leider keine direkte Message-Unterstützung via URL)
        return Uri.parse('sgnl://');

      case MessengerType.sms:
        // SMS: sms:?body=message
        return Uri.parse(
          'sms:${message != null ? '?body=$encodedMessage' : ''}',
        );

      case MessengerType.none:
        return Uri.parse('');
    }
  }

  /// Prüft ob ein bestimmter Messenger verfügbar/installiert ist
  static Future<bool> isMessengerAvailable(MessengerType messenger) async {
    if (messenger == MessengerType.none) {
      return false;
    }

    try {
      final Uri url = _buildUrl(messenger, null);
      return await canLaunchUrl(url);
    } catch (e) {
      return false;
    }
  }
}
