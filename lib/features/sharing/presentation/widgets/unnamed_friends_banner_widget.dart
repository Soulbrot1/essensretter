import 'package:flutter/material.dart';

/// Banner-Widget das angezeigt wird wenn unbenannte Friends existieren
class UnnamedFriendsBannerWidget extends StatelessWidget {
  final int unnamedCount;

  const UnnamedFriendsBannerWidget({super.key, required this.unnamedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$unnamedCount neue${unnamedCount > 1 ? ' Friends' : 'r Friend'} ohne Namen! Tippe auf "Namen ändern" im Menü.',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
