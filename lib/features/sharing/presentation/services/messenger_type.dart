import 'package:flutter/material.dart';

enum MessengerType {
  whatsapp('WhatsApp', Icons.chat),
  telegram('Telegram', Icons.send),
  signal('Signal', Icons.shield),
  sms('SMS/iMessage', Icons.message),
  none('Keiner', null);

  final String displayName;
  final IconData? icon;

  const MessengerType(this.displayName, this.icon);

  String get urlScheme {
    switch (this) {
      case MessengerType.whatsapp:
        return 'whatsapp://send';
      case MessengerType.telegram:
        return 'tg://msg';
      case MessengerType.signal:
        return 'sgnl://';
      case MessengerType.sms:
        return 'sms:';
      case MessengerType.none:
        return '';
    }
  }

  static MessengerType fromString(String? value) {
    if (value == null) return MessengerType.none;
    return MessengerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessengerType.none,
    );
  }
}
