// lib/features/cfo/widgets/cfo_screen.dart (corrected)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'ledger_screen.dart';
import 'transaction_entry_dialog.dart';

// =====================================================================
// DATA MODELS
// =====================================================================

class FinancialData extends ChangeNotifier {
  double income;
  double expenses;
  double debt;
  double savings;
  Map<String, double> categories;
  List<MonthData> monthlyHistory;

  FinancialData({
    required this.income,
    required this.expenses,
    required this.debt,
    required this.savings,
    required this.categories,
    required this.monthlyHistory,
  });
}

class MonthData {
  final DateTime month;
  final double income;
  final double expenses;
  MonthData(this.month, this.income, this.expenses);
}

// =====================================================================
// CFO SCREEN
// =====================================================================

class CfoScreen extends StatelessWidget {
  const CfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<FinancialData>(context);
    final healthScore = _calculateHealthScore(data);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CFO Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LedgerScreen(),
                ),
              );
            },
            tooltip: 'View Bills & Transactions',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HealthScoreCard(score: healthScore),
            const SizedBox(height: 24),
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _SpendingPieChart(categories: data.categories),
            ),
            const SizedBox(height: 24),
            const Text(
              'Income vs Expenses (Last 6 Months)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _IncomeExpenseBarChart(history: data.monthlyHistory),
            ),
            const SizedBox(height: 24),
            const Text(
              'Planning',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _PlanningCards(data: data),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LedgerScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('View Bills & Transactions'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: const TransactionEntryDialog(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Transaction or Bill',
      ),
    );
  }

  int _calculateHealthScore(FinancialData data) {
    double score = 50;
    if (data.income > data.expenses) score += 20;
    if (data.savings > 10000) score += 20;
    if (data.debt < 5000) score += 10;
    return score.clamp(0, 100).toInt();
  }
}

// =====================================================================
// HELPER WIDGETS (unchanged, but corrected the FlTitlesData 'show')
// =====================================================================

class _HealthScoreCard extends StatelessWidget {
  final int score;
  const _HealthScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.health_and_safety, size: 40, color: Colors.green),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Financial Health Score',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey[300],
                    color: _scoreColor(score),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$score / 100',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}

class _SpendingPieChart extends StatelessWidget {
  final Map<String, double> categories;
  const _SpendingPieChart({required this.categories});

  @override
  Widget build(BuildContext context) {
    final total = categories.values.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      return const Center(child: Text('No spending data'));
    }
    final colorPalette = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final sections = categories.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final e = entry.value;
      final percentage = (e.value / total) * 100;
      return PieChartSectionData(
        color: colorPalette[index % colorPalette.length],
        value: e.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 0,
      ),
    );
  }
}

class _IncomeExpenseBarChart extends StatelessWidget {
  final List<MonthData> history;
  const _IncomeExpenseBarChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(child: Text('No historical data'));
    }

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < history.length; i++) {
      final month = history[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: month.income,
              color: Colors.green,
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: month.expenses,
              color: Colors.red,
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    final titles =
        history.map((m) => DateFormat('MMM').format(m.month)).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          // 👇 removed the 'show: true' – it was the cause of the errors
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < titles.length) {
                  return Text(titles[index]);
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('\$${value.toInt()}');
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(enabled: true),
      ),
    );
  }
}

class _PlanningCards extends StatelessWidget {
  final FinancialData data;
  const _PlanningCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _PlanningCard(
        icon: Icons.credit_card_off,
        title: 'Pay Off Debt',
        subtitle: 'Current debt: \$${data.debt.toStringAsFixed(0)}',
        onTap: () => _showInfoDialog(context, 'Pay Off Debt',
            'Consider allocating extra funds to reduce your debt.'),
      ),
      _PlanningCard(
        icon: Icons.savings,
        title: 'Emergency Fund',
        subtitle: 'Savings: \$${data.savings.toStringAsFixed(0)}',
        onTap: () => _showInfoDialog(context, 'Emergency Fund',
            'Aim to save 3‑6 months of living expenses.'),
      ),
      _PlanningCard(
        icon: Icons.trending_up,
        title: 'Build Wealth',
        subtitle: 'Invest for the future',
        onTap: () => _showInfoDialog(context, 'Build Wealth',
            'Explore investment options to grow your net worth.'),
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((card) => SizedBox(width: 150, child: card)).toList(),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _PlanningCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PlanningCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
