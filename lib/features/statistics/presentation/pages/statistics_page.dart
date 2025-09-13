import 'package:flutter/material.dart';
import '../../domain/entities/waste_entry.dart';
import '../../data/datasources/statistics_local_data_source.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  Map<String, List<WasteEntry>> _monthlyData = {};
  Map<String, int> _monthlyComparison = {};
  String? _selectedMonth;
  bool _isLoading = false;
  final StatisticsLocalDataSource _dataSource = StatisticsLocalDataSourceImpl();

  @override
  void initState() {
    super.initState();
    _loadMonthlyComparison();
  }

  Future<void> _loadMonthlyComparison() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final months = <DateTime>[];

      // Lade Daten für die letzten 6 Monate
      for (int i = 5; i >= 0; i--) {
        months.add(DateTime(now.year, now.month - i, 1));
      }

      final monthlyData = <String, List<WasteEntry>>{};
      final monthlyComparison = <String, int>{};

      for (final month in months) {
        final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
        final entries = await _dataSource.getWasteEntries(month, endOfMonth);

        final monthName = _getMonthName(month);
        monthlyData[monthName] = entries;
        monthlyComparison[monthName] = entries.length;
      }

      setState(() {
        _monthlyData = monthlyData;
        _monthlyComparison = monthlyComparison;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return months[date.month - 1];
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
              if (_selectedMonth != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = null;
                    });
                  },
                ),
              Icon(Icons.delete_outline, color: Colors.green[600], size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedMonth ?? 'Weggeworfene Lebensmittel',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey[300]),

        Expanded(
          child: _selectedMonth != null
              ? _buildDetailView()
              : _buildMonthlyComparisonView(),
        ),
      ],
    );
  }

  Widget _buildMonthlyComparisonView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_monthlyComparison.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Keine Daten verfügbar',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    final maxValue = _monthlyComparison.values.isEmpty
        ? 1
        : _monthlyComparison.values.reduce((a, b) => a > b ? a : b);

    final entries = _monthlyComparison.entries.toList();
    final currentMonthName = _getMonthName(DateTime.now());

    // Berechne Trend für die letzten beiden Monate
    int? trend;
    int? trendPercent;
    if (entries.length >= 2) {
      final lastMonthValue = entries[entries.length - 2].value;
      final currentMonthValue = entries[entries.length - 1].value;
      trend = currentMonthValue - lastMonthValue;
      trendPercent = lastMonthValue > 0
          ? ((trend / lastMonthValue) * 100).round()
          : 0;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Trend Indicator
          if (trend != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: trend <= 0 ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: trend <= 0 ? Colors.green[200]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    trend <= 0 ? Icons.trending_down : Icons.trending_up,
                    color: trend <= 0 ? Colors.green[700] : Colors.orange[700],
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trend <= 0
                              ? 'Weniger verschwendet!'
                              : 'Mehr verschwendet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: trend <= 0
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                        ),
                        Text(
                          '${trend.abs()} Artikel (${trendPercent!.abs()}%) im Vergleich zum Vormonat',
                          style: TextStyle(
                            color: trend <= 0
                                ? Colors.green[600]
                                : Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Bar Chart
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((entry) {
                final heightPercent = maxValue > 0
                    ? entry.value / maxValue
                    : 0.0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMonth = entry.key;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: FractionallySizedBox(
                              heightFactor: heightPercent == 0
                                  ? 0.05
                                  : heightPercent,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: entry.key == currentMonthName
                                      ? Colors.green[600]
                                      : Colors.green[400],
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: entry.value > 0
                                      ? null
                                      : Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.eco,
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            size: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        RotatedBox(
                          quarterTurns: entries.length > 4 ? -1 : 0,
                          child: Text(
                            entry.key.substring(0, 3),
                            style: TextStyle(
                              fontSize: entries.length > 4 ? 10 : 12,
                              fontWeight: entry.key == currentMonthName
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (entries.length <= 4) const SizedBox(height: 4),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Info Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tippe auf eine Säule für Details',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView() {
    final entries = _monthlyData[_selectedMonth] ?? [];

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, size: 64, color: Colors.green[400]),
            const SizedBox(height: 16),
            Text(
              'Keine weggeworfenen Lebensmittel',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'in $_selectedMonth',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Toll gemacht! 🌱',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.green[600]),
            ),
          ],
        ),
      );
    }

    // Gruppiere nach Kategorien
    final Map<String, List<WasteEntry>> categorizedEntries = {};
    for (final entry in entries) {
      final category = entry.category ?? 'Unbekannt';
      categorizedEntries.putIfAbsent(category, () => []).add(entry);
    }

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${entries.length}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Artikel', style: TextStyle(color: Colors.green[700])),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.green[300]),
              Column(
                children: [
                  Text(
                    '${categorizedEntries.length}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Kategorien',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Category Pills
        if (categorizedEntries.isNotEmpty)
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categorizedEntries.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.green[600],
                      child: Text(
                        '${entry.value.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    label: Text(entry.key),
                    backgroundColor: Colors.green[100],
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 16),

        // List of entries
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(
                      _getCategoryIcon(entry.category),
                      color: Colors.green[700],
                    ),
                  ),
                  title: Text(entry.name),
                  subtitle: Text(
                    '${entry.category ?? "Unbekannt"} • ${_formatDate(entry.deletedDate)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, color: Colors.green[600], size: 20),
                      Text(
                        _formatDate(entry.deletedDate),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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
    if (difference < 7) return 'vor $difference Tagen';
    if (difference < 30) return 'vor ${(difference / 7).round()} Wochen';
    return '${date.day}.${date.month}.';
  }
}
