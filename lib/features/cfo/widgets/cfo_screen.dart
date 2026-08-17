// lib/features/cfo/widgets/cfo_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:fl_chart/fl_chart.dart';

class CfoScreen extends StatelessWidget {
  const CfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use AppState's finance data (stub) – replace with real data later
    final appState = Provider.of<AppState>(context);
    final transactions = appState.myTransactions; // empty list for now

    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 CFO Dashboard'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                _buildSummaryCard(
                  title: 'Income',
                  amount: 5000.0,
                  color: Colors.green,
                  icon: Icons.arrow_upward,
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  title: 'Expenses',
                  amount: 3200.0,
                  color: Colors.red,
                  icon: Icons.arrow_downward,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryCard(
                  title: 'Savings',
                  amount: 8000.0,
                  color: Colors.blue,
                  icon: Icons.savings,
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  title: 'Debt',
                  amount: 12000.0,
                  color: Colors.orange,
                  icon: Icons.credit_card,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Monthly chart
            const Text(
              'Monthly Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    _makeBarGroup(0, 4200, Colors.teal),
                    _makeBarGroup(1, 4800, Colors.teal),
                    _makeBarGroup(2, 5100, Colors.teal),
                    _makeBarGroup(3, 4900, Colors.teal),
                    _makeBarGroup(4, 5300, Colors.teal),
                    _makeBarGroup(5, 5000, Colors.teal),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun'
                          ];
                          return Text(
                            months[value.toInt() % months.length],
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent transactions (from AppState stub – will be empty)
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions yet',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return ListTile(
                          leading: Icon(
                            tx.type == 'income'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color:
                                tx.type == 'income' ? Colors.green : Colors.red,
                          ),
                          title: Text(tx.title),
                          subtitle: Text(
                              '${tx.category} • ${tx.date.day}/${tx.date.month}'),
                          trailing: Text(
                            '\$${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tx.type == 'income'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
