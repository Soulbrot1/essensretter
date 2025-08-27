import 'package:flutter/material.dart';
import '../../domain/entities/waste_entry.dart';
import '../../data/datasources/statistics_local_data_source.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _selectedPeriod = 0; // 0: Woche, 1: Monat, 2: Jahr
  List<WasteEntry> _wasteEntries = [];
  bool _isLoading = false;
  final StatisticsLocalDataSource _dataSource = StatisticsLocalDataSourceImpl();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Daten laden
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedPeriod) {
        case 0: // Woche
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 1: // Monat
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 2: // Jahr
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      final entries = await _dataSource.getWasteEntries(startDate, now);
      setState(() {
        _wasteEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bottom Sheet Handle
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Title Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red[400], size: 28),
              const SizedBox(width: 12),
              Text(
                'Weggeworfene Lebensmittel',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey[300]),
        Expanded(
          child: Column(
            children: [
              // Period Selector
              Container(
                margin: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _buildPeriodButton('Woche', 0)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPeriodButton('Monat', 1)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPeriodButton('Jahr', 2)),
                  ],
                ),
              ),

              // Statistics Summary
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${_wasteEntries.length}',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Weggeworfen',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.red[300]),
                    Column(
                      children: [
                        Text(
                          _getCategoryCount(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Kategorien',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Waste Entries List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _wasteEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.eco, size: 64, color: Colors.green[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Keine weggeworfenen Lebensmittel!',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              'Toll gemacht! 🌱',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.green[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _wasteEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _wasteEntries[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red[100],
                                child: Icon(
                                  _getCategoryIcon(entry.category),
                                  color: Colors.red[700],
                                ),
                              ),
                              title: Text(entry.name),
                              subtitle: Text(
                                '${entry.category ?? "Unbekannt"} • ${_formatDate(entry.deletedDate)}',
                              ),
                              trailing: Icon(
                                Icons.delete,
                                color: Colors.red[400],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String label, int period) {
    final isSelected = _selectedPeriod == period;
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedPeriod = period);
        _loadData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.red[400] : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(label),
    );
  }

  String _getCategoryCount() {
    final categories = _wasteEntries
        .map((e) => e.category ?? 'Unbekannt')
        .toSet()
        .length;
    return categories.toString();
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'obst':
        return Icons.apple;
      case 'gemüse':
        return Icons.eco;
      case 'fleisch':
        return Icons.lunch_dining;
      case 'milchprodukte':
        return Icons.local_drink;
      case 'backwaren':
        return Icons.bakery_dining;
      default:
        return Icons.fastfood;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Heute';
    if (difference == 1) return 'Gestern';
    return 'vor $difference Tagen';
  }
}
