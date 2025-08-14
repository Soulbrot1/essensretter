import 'package:flutter/material.dart';

class SimpleStatisticsPage extends StatelessWidget {
  const SimpleStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken'),
        backgroundColor: Colors.red[400],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Statistiken funktionieren!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Die Statistik-Seite wurde erfolgreich geöffnet.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
