// lib/features/cfo/widgets/cfo_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:fl_chart/fl_chart.dart';

class CfoScreen extends StatelessWidget {
  const CfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final transactions = appState.myTransactions;

    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    final netCashFlow = totalIncome - totalExpenses;

    final debt = transactions
        .where((t) => t.category.toLowerCase() == 'loan')
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 CFO Dashboard'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        // ❌ No add button here – view‑only
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSummaryCard(
                  title: 'Income',
                  amount: totalIncome,
                  color: Colors.green,
                  icon: Icons.arrow_upward,
                  onTap: () => _navigateToTransactions(context, 'Income'),
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  title: 'Expenses',
                  amount: totalExpenses,
                  color: Colors.red,
                  icon: Icons.arrow_downward,
                  onTap: () => _navigateToTransactions(context, 'Expense'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryCard(
                  title: 'Net Cash Flow',
                  amount: netCashFlow,
                  color: netCashFlow >= 0 ? Colors.blue : Colors.red,
                  icon: Icons.account_balance,
                  onTap: () => _navigateToTransactions(context, 'All'),
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  title: 'Debt',
                  amount: debt,
                  color: Colors.orange,
                  icon: Icons.credit_card,
                  onTap: () => _navigateToTransactions(context, 'Loan'),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                  barGroups: _buildBarGroups(transactions),
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
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec'
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
            const SizedBox(height: 16),
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No transactions yet')),
              )
            else
              Column(
                children: [
                  ...transactions.reversed
                      .take(3)
                      .map((tx) => _buildTransactionTile(tx)),
                  if (transactions.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: TextButton(
                          onPressed: () =>
                              _navigateToTransactions(context, 'All'),
                          child: Text(
                            'Show All (${transactions.length - 3} more)',
                            style: TextStyle(color: Colors.teal),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction tx) {
    final isIncome = tx.type == TransactionType.income;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: isIncome ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                ),
                Text(
                  '${tx.category} • ${tx.date.day}/${tx.date.month}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '\$${tx.amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTransactions(BuildContext context, String filterType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FilteredTransactionsScreen(filterType: filterType),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
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
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<Transaction> transactions) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return date;
    }).reversed.toList();

    return months.asMap().entries.map((entry) {
      final index = entry.key;
      final month = entry.value;

      final monthIncome = transactions
          .where((t) =>
              t.type == TransactionType.income &&
              t.date.year == month.year &&
              t.date.month == month.month)
          .fold(0.0, (sum, t) => sum + t.amount);

      final monthExpense = transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.year == month.year &&
              t.date.month == month.month)
          .fold(0.0, (sum, t) => sum + t.amount.abs());

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: monthIncome,
            color: Colors.green,
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            fromY: monthIncome,
            toY: monthIncome + monthExpense,
            color: Colors.red,
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }
}

// ---- Filtered Transactions Screen (view‑only) ----
class _FilteredTransactionsScreen extends StatelessWidget {
  final String filterType;

  const _FilteredTransactionsScreen({required this.filterType});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final allTransactions = appState.myTransactions;

    final filtered = allTransactions.where((t) {
      if (filterType == 'Income') return t.type == TransactionType.income;
      if (filterType == 'Expense') return t.type == TransactionType.expense;
      if (filterType == 'Loan') return t.category.toLowerCase() == 'loan';
      return true;
    }).toList();

    final total = filtered.fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('$filterType Transactions'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
                Text(
                  '\$${total.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: total >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No transactions found'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      final isIncome = tx.type == TransactionType.income;
                      return ListTile(
                        leading: Icon(
                          isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                        title: Text(tx.description),
                        subtitle: Text(
                          '${tx.category} • ${tx.date.day}/${tx.date.month}',
                        ),
                        trailing: Text(
                          '\$${tx.amount.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
