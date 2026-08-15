import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/transaction.dart';

class SpendingPieChart extends StatelessWidget {
  final List<Transaction> transactions;
  final double totalSpent;

  const SpendingPieChart({
    super.key,
    required this.transactions,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    // Group transactions by category
    final Map<String, double> categorySpending = {};
    for (final tx in transactions.where((t) => t.amount < 0)) {
      categorySpending[tx.category] =
          (categorySpending[tx.category] ?? 0) + tx.amount.abs();
    }

    if (categorySpending.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'No spending data to show',
          style: TextStyle(color: HavenColors.muted),
        ),
      );
    }

    final sortedEntries = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedEntries.take(5).toList();
    final otherTotal = sortedEntries.skip(5).fold(0.0, (s, e) => s + e.value);

    List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    for (int i = 0; i < topCategories.length; i++) {
      final entry = topCategories[i];
      final percentage = (entry.value / totalSpent) * 100;
      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: '${percentage.toStringAsFixed(0)}%',
          color: colors[i % colors.length],
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (otherTotal > 0) {
      final percentage = (otherTotal / totalSpent) * 100;
      sections.add(
        PieChartSectionData(
          value: otherTotal,
          title: '${percentage.toStringAsFixed(0)}%',
          color: Colors.grey,
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending by Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: HavenColors.dark,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            ...topCategories.asMap().entries.map((entry) {
              final color = colors[entry.key % colors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.value.key}',
                    style: TextStyle(
                      fontSize: 12,
                      color: HavenColors.muted,
                    ),
                  ),
                ],
              );
            }),
            if (otherTotal > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Other',
                    style: TextStyle(
                      fontSize: 12,
                      color: HavenColors.muted,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
