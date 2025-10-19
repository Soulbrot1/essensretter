import 'package:flutter/material.dart';
import '../../domain/repositories/share_code_repository.dart';
import '../../../../injection_container.dart' as di;
import '../services/simple_user_identity_service.dart';

/// Widget für die Share-Code Sektion mit QR-Code und Copy-Funktionalität
///
/// Zeigt:
/// - Share-Code mit FutureBuilder
/// - QR-Code Button
/// - Copy Button
/// - Hilfetext
class UserIdSectionWidget extends StatelessWidget {
  final Function(String shareCode) onShowQrCode;
  final VoidCallback onCopyShareCode;

  const UserIdSectionWidget({
    super.key,
    required this.onShowQrCode,
    required this.onCopyShareCode,
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
                'Dein Share-Code',
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
            future: () async {
              final retterId =
                  await SimpleUserIdentityService.getCurrentUserId();
              if (retterId == null) return null;

              final repository = di.sl<ShareCodeRepository>();

              // Versuche Share-Code abzurufen
              var result = await repository.getShareCode(retterId);

              // Falls kein Share-Code existiert, erstelle einen neuen
              return result.fold((failure) async {
                // Erstelle neuen Share-Code
                final createResult = await repository.createShareCode(retterId);
                return createResult.fold(
                  (createFailure) => null,
                  (newShareCode) => newShareCode,
                );
              }, (shareCode) async => shareCode);
            }(),
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
                    Text('Lade Share-Code...'),
                  ],
                );
              }

              final shareCode = snapshot.data ?? 'Nicht verfügbar';
              return Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      shareCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: shareCode != 'Nicht verfügbar'
                        ? () => onShowQrCode(shareCode)
                        : null,
                    icon: const Icon(Icons.qr_code_2),
                    tooltip: 'QR-Code anzeigen',
                  ),
                  IconButton(
                    onPressed: shareCode != 'Nicht verfügbar'
                        ? onCopyShareCode
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
            'Teile diesen Code mit anderen, damit sie dich als Friend hinzufügen können.',
            style: TextStyle(fontSize: 12, color: Colors.green[600]),
          ),
        ],
      ),
    );
  }
}
