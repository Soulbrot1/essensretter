import 'package:flutter/material.dart';

/// Widget für den Empty State wenn keine Friends vorhanden sind
class FriendsEmptyStateWidget extends StatelessWidget {
  const FriendsEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Noch keine Friends',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Füge Friends hinzu, um ihre Lebensmittel zu sehen',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
