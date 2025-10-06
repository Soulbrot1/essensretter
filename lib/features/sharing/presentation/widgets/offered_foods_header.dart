import 'package:flutter/material.dart';
import '../pages/friends_page.dart';

/// Header für das OfferedFoodsBottomSheet
///
/// Enthält:
/// - Handle bar für Bottom Sheet
/// - Close Button
/// - Icon
/// - Friends Button
/// - Refresh Button
class OfferedFoodsHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const OfferedFoodsHeader({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.handshake, color: Colors.blue, size: 28),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.people),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FriendsPage(),
                    ),
                  );
                },
                tooltip: 'Friends verwalten',
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
            ],
          ),
        ],
      ),
    );
  }
}
