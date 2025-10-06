import 'package:flutter/material.dart';
import '../services/simple_user_identity_service.dart';

/// Widget für die User-ID Sektion mit QR-Code und Copy-Funktionalität
///
/// Zeigt:
/// - User-ID mit FutureBuilder
/// - QR-Code Button
/// - Copy Button
/// - Hilfetext
class UserIdSectionWidget extends StatelessWidget {
  final Function(String userId) onShowQrCode;
  final VoidCallback onCopyUserId;

  const UserIdSectionWidget({
    super.key,
    required this.onShowQrCode,
    required this.onCopyUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Deine User-ID',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<String?>(
            future: SimpleUserIdentityService.getCurrentUserId(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Lade User-ID...'),
                  ],
                );
              }

              final userId = snapshot.data ?? 'Nicht verfügbar';
              return Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      userId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: userId != 'Nicht verfügbar'
                        ? () => onShowQrCode(userId)
                        : null,
                    icon: const Icon(Icons.qr_code_2),
                    tooltip: 'QR-Code anzeigen',
                  ),
                  IconButton(
                    onPressed: userId != 'Nicht verfügbar'
                        ? onCopyUserId
                        : null,
                    icon: const Icon(Icons.copy),
                    tooltip: 'Kopieren',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Teile diese ID mit anderen, damit sie dich als Friend hinzufügen können.',
            style: TextStyle(fontSize: 12, color: Colors.green[600]),
          ),
        ],
      ),
    );
  }
}
