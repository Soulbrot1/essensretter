import 'package:flutter/material.dart';
import '../pages/friends_page.dart';

/// Header für das OfferedFoodsBottomSheet
///
/// Enthält:
/// - Handle bar für Bottom Sheet
/// - Friends Button
class OfferedFoodsHeader extends StatelessWidget {
  const OfferedFoodsHeader({super.key});

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
          // Friends Button
          Row(
            children: [
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
            ],
          ),
        ],
      ),
    );
  }
}
