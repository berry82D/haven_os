import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/transaction.dart';

class CashFlowChart extends StatelessWidget {
  final List<Transaction> transactions;

  const CashFlowChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Get last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recent =
        transactions.where((t) => t.date.isAfter(thirtyDaysAgo)).toList();

    // Group by date
    final Map<DateTime, double> dailyIncome = {};
    final Map<DateTime, double> dailyExpenses = {};

    for (final tx in recent) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (tx.amount > 0) {
        dailyIncome[date] = (dailyIncome[date] ?? 0) + tx.amount;
      } else {
        dailyExpenses[date] = (dailyExpenses[date] ?? 0) + tx.amount.abs();
      }
    }

    final dates = {...dailyIncome.keys, ...dailyExpenses.keys}.toList()..sort();

    if (dates.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Text(
          'No cash flow data to show',
          style: TextStyle(color: HavenColors.muted),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final income = dailyIncome[date] ?? 0;
      final expenses = dailyExpenses[date] ?? 0;
      spots.add(FlSpot(i.toDouble(), income - expenses));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cash Flow (30 days)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: HavenColors.dark,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              minY: minY - padding,
              maxY: maxY + padding,
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toInt()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: HavenColors.muted,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: dates.length > 10 ? dates.length / 7 : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= dates.length)
                        return const SizedBox();
                      final date = dates[index];
                      return Text(
                        '${date.month}/${date.day}',
                        style: TextStyle(
                          fontSize: 10,
                          color: HavenColors.muted,
                        ),
                      );
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: HavenColors.green,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: HavenColors.green.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 16,
              height: 4,
              color: HavenColors.green,
            ),
            const SizedBox(width: 8),
            Text(
              'Net Cash Flow',
              style: TextStyle(
                fontSize: 12,
                color: HavenColors.muted,
              ),
            ),
            const Spacer(),
            Text(
              'Positive = Income > Expenses',
              style: TextStyle(
                fontSize: 10,
                color: HavenColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
