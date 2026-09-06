import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/transaction.dart';
import '../../models/budget.dart';
import '../../services/firestore_service.dart';

// ---------- Constants ----------
const List<String> transactionCategories = [
  'General',
  'Groceries',
  'Farm Supplies',
  'Equipment',
  'Utilities',
  'Housing',
  'Transport',
  'Healthcare',
  'Entertainment',
  'Dining',
  'Crop Sales',
  'Livestock Sales',
  'Rental Income',
  'Salary',
  'Other',
];

// ---------- Main Screen ----------
class HavenCentralScreen extends StatefulWidget {
  final String username;
  const HavenCentralScreen({super.key, required this.username});

  @override
  State<HavenCentralScreen> createState() => _HavenCentralScreenState();
}

class _HavenCentralScreenState extends State<HavenCentralScreen> {
  // ---------- Tab index ----------
  int _currentIndex = 0;

  // ---------- Chart toggle ----------
  bool _showCumulativeLine = false;

  // ---------- Collapsible recent activity ----------
  bool _showRecentActivity = true;

  // ---------- Firestore service ----------
  final FirestoreService _firestore = FirestoreService();

  // ---------- Controllers (for modals) ----------
  final TextEditingController _loanNameController = TextEditingController();
  final TextEditingController _loanPrincipalController =
      TextEditingController();
  final TextEditingController _loanRateController = TextEditingController();
  final TextEditingController _loanMonthsController = TextEditingController();
  final TextEditingController _loanExtraController = TextEditingController();
  final TextEditingController _loanPenaltyController = TextEditingController();
  DateTime _loanStartDate = DateTime.now();
  Loan? _editingLoan;

  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _farmQtyController = TextEditingController();

  final TextEditingController _taskController = TextEditingController();
  DateTime _taskDueDate = DateTime.now().add(const Duration(days: 1));

  // ---------- Budget modal controllers ----------
  String _selectedBudgetCategory = 'General';
  final TextEditingController _budgetLimitController = TextEditingController();
  String _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  // ---------- Lifecycle ----------
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _loanNameController.dispose();
    _loanPrincipalController.dispose();
    _loanRateController.dispose();
    _loanMonthsController.dispose();
    _loanExtraController.dispose();
    _loanPenaltyController.dispose();
    _farmNameController.dispose();
    _farmQtyController.dispose();
    _taskController.dispose();
    _budgetLimitController.dispose();
    super.dispose();
  }

  // ---------- Build methods for each tab ----------

  // 1. HOME TAB
  Widget _buildHomeTab(
    List<Transaction> transactions,
    List<Task> tasks,
    List<Budget> budgets,
  ) {
    final upcomingTasks = tasks.where((t) => !t.isDone).take(5).toList();
    final insights = _generateAIInsights(transactions, budgets);

    return Container(
      color: const Color(0xFF121212),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gradient Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00695C), Color(0xFF004D40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌾 Haven OS',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome, ${widget.username}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Edit Widgets coming soon'),
                          backgroundColor: Colors.grey),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Toggle Tabs (static)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToggleTab('🌱 Breeding', true),
              _buildToggleTab('💰 Finances', false),
              _buildToggleTab('📋 Records', false),
            ],
          ),
          const SizedBox(height: 16),

          // Action Cards
          Row(
            children: [
              Expanded(
                  child: _buildActionCard(
                      '📝', 'New', () => _showAddTransactionSheet())),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildActionCard('📥', 'Reports', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Download Reports coming soon'),
                      backgroundColor: Colors.grey),
                );
              })),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildActionCard('👁️', 'View All', () {
                setState(() {
                  _currentIndex = 2;
                });
              })),
            ],
          ),
          const SizedBox(height: 16),

          // Upcoming Tasks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📅 Upcoming Tasks',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 4;
                  });
                },
                child: const Text('View All >',
                    style: TextStyle(color: Colors.tealAccent)),
              ),
            ],
          ),
          if (upcomingTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No tasks yet. Add one!',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ...upcomingTasks.map((task) => _buildTaskTile(task)),
          const SizedBox(height: 16),

          // AI Insights
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.tealAccent),
                    SizedBox(width: 8),
                    Text(
                      '🧠 AI Insights',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...insights.map((text) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        text,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // AI Insights Generator (budget‑aware)
  List<String> _generateAIInsights(
      List<Transaction> transactions, List<Budget> budgets) {
    final insights = <String>[];
    if (transactions.isEmpty) {
      insights.add('📊 No transactions yet. Start tracking to get insights!');
      return insights;
    }

    // Totals
    final totalIncome =
        transactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final net = totalIncome - totalExpense;

    // Top spending category
    final catExp = <String, double>{};
    for (final t in transactions.where((t) => !t.isIncome)) {
      catExp[t.category] = (catExp[t.category] ?? 0) + t.amount;
    }
    if (catExp.isNotEmpty) {
      final topCat = catExp.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add(
          '💡 Your top spending category is **${topCat.key}** (${topCat.value.toStringAsFixed(0)}).');
    }

    // Average monthly spending
    if (transactions.isNotEmpty) {
      final earliest = transactions
          .map((t) => t.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final latest = transactions
          .map((t) => t.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final months = (latest.year - earliest.year) * 12 +
          (latest.month - earliest.month) +
          1;
      if (months > 0) {
        final avgExpense = totalExpense / months;
        insights.add(
            '📆 Average monthly spending: \$${avgExpense.toStringAsFixed(0)}.');
      }
    }

    // Net advice
    if (net > 0) {
      insights.add('✅ You\'re saving money! Keep it up.');
    } else if (net < 0) {
      insights.add(
          '⚠️ You\'re spending more than you earn. Consider cutting back on "${catExp.keys.first}" if possible.');
    } else {
      insights.add('⚖️ You\'re breaking even.');
    }

    // Budget warnings
    if (budgets.isNotEmpty) {
      final now = DateTime.now();
      final monthKey = DateFormat('yyyy-MM').format(now);
      final relevantBudgets =
          budgets.where((b) => b.month == monthKey).toList();
      for (final budget in relevantBudgets) {
        final spent = transactions
            .where((t) => !t.isIncome && t.category == budget.category)
            .fold(0.0, (s, t) => s + t.amount);
        final percent =
            budget.limit > 0 ? (spent / budget.limit * 100).clamp(0, 100) : 0;
        if (percent >= 80) {
          insights.add(
              '⚠️ You\'ve used ${percent.toStringAsFixed(0)}% of your "${budget.category}" budget (\$${spent.toStringAsFixed(0)} of \$${budget.limit.toStringAsFixed(0)}). Consider cutting back.');
        } else if (percent >= 50) {
          insights.add(
              '📊 You\'ve used ${percent.toStringAsFixed(0)}% of your "${budget.category}" budget. You\'re on track.');
        }
      }
    }

    if (insights.isEmpty) {
      insights.add(
          '🧠 AI is learning your habits. Add more transactions for better insights!');
    }
    return insights;
  }

  // 2. BATCHES TAB
  Widget _buildBatchesTab(List<Map<String, dynamic>> farmItems, String unit) {
    return Container(
      color: const Color(0xFF121212),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('🐄 Batches (Farm Inventory)',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _farmNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _farmQtyController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Qty ($unit)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final name = _farmNameController.text.trim();
                  final qty = double.tryParse(_farmQtyController.text.trim());
                  if (name.isEmpty || qty == null) return;
                  final newItem = {'name': name, 'quantity': qty};
                  await _firestore.saveFarmItem(newItem);
                  _farmNameController.clear();
                  _farmQtyController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent[700],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                child: const Text('Add', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...farmItems
              .map((item) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['name'],
                            style: const TextStyle(color: Colors.white)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove,
                                  color: Colors.red, size: 18),
                              onPressed: () async {
                                final newQty = (item['quantity'] ?? 0) - 0.5;
                                if (newQty <= 0) {
                                  await _firestore.deleteFarmItem(item['id']);
                                } else {
                                  item['quantity'] = newQty;
                                  await _firestore.saveFarmItem(item);
                                }
                              },
                            ),
                            Text('${item['quantity']} $unit',
                                style: const TextStyle(color: Colors.white)),
                            IconButton(
                              icon: const Icon(Icons.add,
                                  color: Colors.green, size: 18),
                              onPressed: () async {
                                item['quantity'] =
                                    (item['quantity'] ?? 0) + 0.5;
                                await _firestore.saveFarmItem(item);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.grey, size: 18),
                              onPressed: () async {
                                await _firestore.deleteFarmItem(item['id']);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  // 3. FINANCES TAB (CFO Dashboard)
  Widget _buildFinancesTab(List<Transaction> transactions) {
    final incomes = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expenses = transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final net = incomes - expenses;
    final savingsRate = incomes > 0 ? (net / incomes * 100).clamp(0, 100) : 0.0;

    // Monthly data
    List<DateTime> monthRange = [];
    if (transactions.isNotEmpty) {
      DateTime earliest = transactions.first.date;
      DateTime latest = transactions.first.date;
      for (var tx in transactions) {
        if (tx.date.isBefore(earliest)) earliest = tx.date;
        if (tx.date.isAfter(latest)) latest = tx.date;
      }
      earliest = DateTime(earliest.year, earliest.month, 1);
      latest = DateTime(latest.year, latest.month, 1);
      DateTime current = earliest;
      while (current.isBefore(latest) || current.isAtSameMomentAs(latest)) {
        monthRange.add(current);
        current = DateTime(current.year, current.month + 1, 1);
      }
      if (monthRange.length > 24) {
        monthRange = monthRange.skip(monthRange.length - 24).toList();
      }
    } else {
      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        monthRange.add(DateTime(now.year, now.month - i, 1));
      }
    }

    final monthlyData = monthRange.map((month) {
      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 1);
      final monthTxs = transactions.where((t) =>
          t.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          t.date.isBefore(monthEnd));
      final inc =
          monthTxs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
      final exp =
          monthTxs.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
      return {
        'label': DateFormat('MMM').format(month),
        'income': inc,
        'expense': exp,
        'net': inc - exp,
      };
    }).toList();

    // Expense categories
    final expenseCategories = <String, double>{};
    for (final tx in transactions.where((t) => !t.isIncome)) {
      expenseCategories[tx.category] =
          (expenseCategories[tx.category] ?? 0) + tx.amount;
    }
    final categoryEntries = expenseCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = categoryEntries.take(5).toList();
    final otherTotal = categoryEntries.skip(5).fold(0.0, (s, e) => s + e.value);

    // Projection
    final validMonths = monthlyData
        .where(
            (m) => (m['income'] as double) > 0 || (m['expense'] as double) > 0)
        .toList();
    final avgSavings = validMonths.isNotEmpty
        ? validMonths.fold(0.0, (s, m) => s + (m['net'] as double)) /
            validMonths.length
        : 0.0;
    final projectedNet = net + avgSavings * 12;

    // maxY
    double maxVal = 0;
    for (var data in monthlyData) {
      final inc = data['income'] as double;
      final exp = data['expense'] as double;
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    if (maxVal == 0) maxVal = 100;
    final maxY = maxVal * 1.2;

    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: const Color(0xFF121212),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        children: [
          const Text('📊 CFO Dashboard',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 16),

          // Summary Cards
          Row(
            children: [
              _buildSummaryCard(
                  'Income', '\$${incomes.toStringAsFixed(0)}', Colors.green),
              const SizedBox(width: 8),
              _buildSummaryCard(
                  'Expenses', '\$${expenses.toStringAsFixed(0)}', Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSummaryCard('Net', '\$${net.toStringAsFixed(0)}',
                  net >= 0 ? Colors.teal : Colors.orange),
              const SizedBox(width: 8),
              _buildSummaryCard('Savings Rate',
                  '${savingsRate.toStringAsFixed(1)}%', Colors.blue),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monthly Income vs Expenses',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Row(
                      children: [
                        const Text('Cumulative',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Switch(
                          value: _showCumulativeLine,
                          onChanged: (val) {
                            setState(() {
                              _showCumulativeLine = val;
                            });
                          },
                          activeThumbColor: Colors.tealAccent,
                          activeTrackColor: Colors.tealAccent.withAlpha(100),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (monthlyData.isEmpty ||
                    monthlyData.every((m) =>
                        (m['income'] as double) == 0 &&
                        (m['expense'] as double) == 0))
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No data to display',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        barGroups: monthlyData.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final data = entry.value;
                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: data['income'] as double,
                                color: Colors.green,
                                width: 12,
                              ),
                              BarChartRodData(
                                toY: data['expense'] as double,
                                color: Colors.red,
                                width: 12,
                              ),
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= monthlyData.length)
                                  return const Text('');
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                      monthlyData[index]['label'] as String,
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) => Text(
                                  '\$${value.toInt()}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 10)),
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData:
                            FlGridData(show: true, drawVerticalLine: false),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _LegendItem(color: Colors.green, label: 'Income'),
                    SizedBox(width: 16),
                    _LegendItem(color: Colors.red, label: 'Expense'),
                    SizedBox(width: 16),
                    _LegendItem(color: Colors.blue, label: 'Cumulative Net'),
                  ],
                ),
                const SizedBox(height: 8),
                // Net labels
                Container(
                  width: screenWidth - 24,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: monthlyData.map((data) {
                        final netVal = data['net'] as double;
                        return Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Text(
                                '\$${netVal.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color:
                                      netVal >= 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data['label'] as String,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 8),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Category Pie Chart
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Expense Breakdown',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                if (expenseCategories.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No expenses yet',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  Row(
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              ...topCategories.map((e) => PieChartSectionData(
                                    value: e.value,
                                    color: _categoryColor(e.key),
                                    radius: 20,
                                    title:
                                        '${(e.value / expenses * 100).toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  )),
                              if (otherTotal > 0)
                                PieChartSectionData(
                                  value: otherTotal,
                                  color: Colors.grey,
                                  radius: 20,
                                  title:
                                      '${(otherTotal / expenses * 100).toStringAsFixed(0)}%',
                                  titleStyle: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                            ],
                            centerSpaceRadius: 0,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...topCategories.map((e) =>
                                _buildCategoryLegend(e.key, e.value, expenses)),
                            if (otherTotal > 0)
                              _buildCategoryLegend(
                                  'Other', otherTotal, expenses),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Projection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📈 12‑Month Projection',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Net Worth',
                        style: TextStyle(color: Colors.grey)),
                    Text('\$${net.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Projected (12 mo)',
                        style: TextStyle(color: Colors.grey)),
                    Text(
                      '\$${projectedNet.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: projectedNet >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: projectedNet >= 0 ? 1 : 0.5,
                  backgroundColor: Colors.grey[800],
                  color: projectedNet >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Monthly Summary
          const Text('Monthly Summary',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: const [
                        SizedBox(
                            width: 50,
                            child: Text('Month',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                        SizedBox(
                            width: 60,
                            child: Text('Income',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                        SizedBox(
                            width: 60,
                            child: Text('Expense',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                        SizedBox(
                            width: 60,
                            child: Text('Net',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  ...monthlyData.map((data) {
                    final netVal = data['net'] as double;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 50,
                              child: Text(data['label'] as String,
                                  style: const TextStyle(color: Colors.white))),
                          SizedBox(
                              width: 60,
                              child: Text(
                                  '\$${(data['income'] as double).toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.green))),
                          SizedBox(
                              width: 60,
                              child: Text(
                                  '\$${(data['expense'] as double).toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.red))),
                          SizedBox(
                              width: 60,
                              child: Text(
                                '\$${netVal.toStringAsFixed(0)}',
                                style: TextStyle(
                                    color:
                                        netVal >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold),
                              )),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Collapsible Recent Activity with Edit/Delete
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text(
                  '📋 Recent Activity',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                initiallyExpanded: _showRecentActivity,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _showRecentActivity = expanded;
                  });
                },
                children: [
                  if (transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No transactions yet.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...transactions.reversed
                        .take(10)
                        .map((tx) => _buildActivityTile(tx)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 4. RECORDS (Loans)
  Widget _buildRecordsTab(List<Loan> loans) {
    return Container(
      color: const Color(0xFF121212),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('📋 Records (Loans)',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showLoanForm,
            icon: const Icon(Icons.add, color: Colors.black),
            label:
                const Text('New Loan', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent[700],
            ),
          ),
          const SizedBox(height: 16),
          ...loans.map((loan) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loan.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Principal: \$${loan.principal.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey)),
                  Text('Rate: ${loan.annualRate}% • ${loan.months} mo',
                      style: const TextStyle(color: Colors.grey)),
                  if (loan.extraPayment > 0)
                    Text('Extra: \$${loan.extraPayment}/mo',
                        style: const TextStyle(color: Colors.grey)),
                  if (loan.missedPaymentPenalty > 0)
                    Text('Penalty: \$${loan.missedPaymentPenalty}',
                        style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: Colors.blue, size: 18),
                        onPressed: () => _showLoanForm(existingLoan: loan),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 18),
                        onPressed: () => _confirmDeleteLoan(loan),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 5. SCHEDULE (Tasks)
  Widget _buildScheduleTab(List<Task> tasks) {
    final sortedTasks = List<Task>.from(tasks)
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return Container(
      color: const Color(0xFF121212),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('📅 Schedule Tasks',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showAddTaskDialog,
            icon: const Icon(Icons.add, color: Colors.black),
            label:
                const Text('Add Task', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent[700],
            ),
          ),
          const SizedBox(height: 16),
          if (sortedTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No tasks scheduled.',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ...sortedTasks.map((task) => _buildTaskTile(task)),
        ],
      ),
    );
  }

  // 6. BUDGET TAB (NEW)
  Widget _buildBudgetTab(List<Budget> budgets, List<Transaction> transactions) {
    final monthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final monthBudgets = budgets.where((b) => b.month == monthKey).toList();

    return Container(
      color: const Color(0xFF121212),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('💰 Budgets',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('Month: ${DateFormat('MMMM yyyy').format(DateTime.now())}',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddBudgetDialog,
            icon: const Icon(Icons.add, color: Colors.black),
            label:
                const Text('Set Budget', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent[700],
            ),
          ),
          const SizedBox(height: 16),
          if (monthBudgets.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No budgets set for this month.',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ...monthBudgets.map((budget) {
              final spent = transactions
                  .where((t) => !t.isIncome && t.category == budget.category)
                  .fold(0.0, (s, t) => s + t.amount);
              final percent = budget.limit > 0
                  ? (spent / budget.limit * 100).clamp(0, 100)
                  : 0;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(budget.category,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red, size: 18),
                          onPressed: () => _confirmDeleteBudget(budget),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: Colors.grey[800],
                      color: percent > 80 ? Colors.red : Colors.tealAccent,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${spent.toStringAsFixed(2)} spent',
                            style: const TextStyle(color: Colors.white)),
                        Text('\$${budget.limit.toStringAsFixed(2)} limit',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Text('${percent.toStringAsFixed(0)}% used',
                        style: TextStyle(
                            color: percent > 80 ? Colors.red : Colors.grey)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------- Helper Widgets ----------

  Widget _buildToggleTab(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.tealAccent[700] : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.black : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionCard(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Icon(
            task.isDone ? Icons.check_circle : Icons.pending,
            color: task.isDone ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                color: task.isDone ? Colors.grey : Colors.white,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            DateFormat('h:mm a').format(task.dueDate),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
            onPressed: () async {
              await _firestore.deleteTask(task.id);
            },
          ),
        ],
      ),
    );
  }

  // Transaction tile with Edit & Delete buttons
  Widget _buildActivityTile(Transaction tx) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: tx.isIncome ? Colors.green[900] : Colors.red[900],
            child: Text(
              tx.isIncome ? '+' : '-',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${tx.place} • ${tx.formattedDate}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            tx.formattedAmount,
            style: TextStyle(
              color: tx.isIncome ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          // EDIT BUTTON
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
            onPressed: () => _showAddTransactionSheet(existingTransaction: tx),
            tooltip: 'Edit',
          ),
          // DELETE BUTTON
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
            onPressed: () => _confirmDeleteTransaction(tx),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  // Confirm Delete Transaction
  void _confirmDeleteTransaction(Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Transaction?',
            style: TextStyle(color: Colors.white)),
        content: Text('Delete "${tx.description}"?',
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              await _firestore.deleteTransaction(tx.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ---------- Finance Helper Widgets ----------
  Widget _buildSummaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryLegend(String label, double amount, double total) {
    final percent = total > 0 ? (amount / total * 100) : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: _categoryColor(label)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 12))),
          Text('${percent.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.indigo,
      Colors.teal,
      Colors.brown,
    ];
    final hash = category.hashCode;
    return colors[hash.abs() % colors.length];
  }

  // ---------- Modals ----------
  void _showAddTransactionSheet({Transaction? existingTransaction}) {
    final isEditing = existingTransaction != null;
    final controllerDescription =
        TextEditingController(text: existingTransaction?.description ?? '');
    final controllerPlace =
        TextEditingController(text: existingTransaction?.place ?? '');
    final controllerAmount = TextEditingController(
        text: existingTransaction?.amount.toString() ?? '');
    final controllerNotes =
        TextEditingController(text: existingTransaction?.notes ?? '');
    DateTime selectedDate = existingTransaction?.date ?? DateTime.now();
    bool isIncome = existingTransaction?.isIncome ?? false;
    String selectedCategory = existingTransaction?.category ?? 'General';

    bool _isScanning = false;

    void _parseReceiptTextForForm(
      String text,
      TextEditingController descCtrl,
      TextEditingController amountCtrl,
    ) {
      RegExp amountRegex = RegExp(r'\$?(\d+\.\d{2})');
      final matches = amountRegex.allMatches(text);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        String amountStr = lastMatch.group(1) ?? '';
        if (amountStr.isNotEmpty) {
          double amount = double.tryParse(amountStr) ?? 0.0;
          if (amount > 0) {
            amountCtrl.text = amount.toStringAsFixed(2);
          }
        }
      }

      List<String> lines = text.split('\n');
      for (String line in lines) {
        String trimmed = line.trim();
        if (trimmed.isNotEmpty && trimmed.length > 3 && trimmed.length < 50) {
          if (!trimmed.contains('TOTAL') &&
              !trimmed.contains('Total') &&
              !trimmed.contains('total') &&
              !trimmed.contains('TAX') &&
              !trimmed.contains('Tax') &&
              !trimmed.contains('tax') &&
              !trimmed.contains('SUBTOTAL') &&
              !trimmed.contains('Subtotal')) {
            descCtrl.text = trimmed;
            break;
          }
        }
      }
    }

    Future<void> _scanReceiptForForm() async {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Select source',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Gallery',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title:
                    const Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      if (source == ImageSource.camera) {
        var status = await Permission.camera.status;
        if (!status.isGranted) {
          status = await Permission.camera.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Camera permission denied'),
                  backgroundColor: Colors.red),
            );
            return;
          }
        }
      }

      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: source);
        if (pickedFile == null) return;

        setState(() => _isScanning = true);

        final inputImage = InputImage.fromFile(File(pickedFile.path));
        final textDetector = TextRecognizer();
        final recognizedText = await textDetector.processImage(inputImage);
        await textDetector.close();

        String fullText = recognizedText.text;
        _parseReceiptTextForForm(
            fullText, controllerDescription, controllerAmount);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Receipt scanned! Check description and amount.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isScanning = false);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEditing ? 'Edit Transaction' : 'Add Transaction',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 20),

                // Scan Receipt Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanReceiptForForm,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.qr_code_scanner),
                    label: Text(
                      _isScanning ? 'Scanning...' : '📸 Scan Receipt',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Income/Expense Toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isIncome = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isIncome ? Colors.green : Colors.grey[800],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Income',
                              style: TextStyle(
                                color: isIncome ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isIncome = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isIncome ? Colors.red : Colors.grey[800],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Expense',
                              style: TextStyle(
                                color: !isIncome ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: controllerDescription,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Place
                TextField(
                  controller: controllerPlace,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Place / Vendor',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF2C2C2C),
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                  items: transactionCategories.map((String cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat,
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      selectedCategory = newValue;
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Amount
                TextField(
                  controller: controllerAmount,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    prefixText: '\$ ',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Date Picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[600]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(selectedDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Icon(Icons.calendar_today,
                            size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: controllerNotes,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final desc = controllerDescription.text.trim();
                      final amount =
                          double.tryParse(controllerAmount.text.trim());
                      if (desc.isEmpty || amount == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please fill in Description and valid Amount'),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }

                      final newTransaction = Transaction(
                        // 🔥 FIX: pass the existing id when editing
                        id: existingTransaction?.id,
                        description: desc,
                        place: controllerPlace.text.trim(),
                        date: selectedDate,
                        amount: amount.abs(),
                        notes: controllerNotes.text.trim(),
                        isIncome: isIncome,
                        category: selectedCategory,
                      );

                      await _firestore.saveTransaction(newTransaction);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent[700],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isEditing ? 'Update Transaction' : 'Save Transaction',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Loan Form
  void _showLoanForm({Loan? existingLoan}) {
    final isEditing = existingLoan != null;
    if (isEditing) {
      _loanNameController.text = existingLoan.name;
      _loanPrincipalController.text = existingLoan.principal.toString();
      _loanRateController.text = existingLoan.annualRate.toString();
      _loanMonthsController.text = existingLoan.months.toString();
      _loanExtraController.text = existingLoan.extraPayment.toString();
      _loanPenaltyController.text =
          existingLoan.missedPaymentPenalty.toString();
      _loanStartDate = existingLoan.startDate;
      _editingLoan = existingLoan;
    } else {
      _loanNameController.clear();
      _loanPrincipalController.clear();
      _loanRateController.clear();
      _loanMonthsController.clear();
      _loanExtraController.clear();
      _loanPenaltyController.clear();
      _loanStartDate = DateTime.now();
      _editingLoan = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEditing ? 'Edit Loan' : 'New Loan',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _loanNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Loan Name',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      )),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _loanPrincipalController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Principal (\$)',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      )),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _loanRateController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Annual Rate (%)',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      )),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _loanMonthsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Months',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      )),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _loanExtraController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Extra Payment (\$/month)',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      )),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _loanPenaltyController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Missed Payment Penalty (\$)',
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      )),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _loanStartDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _loanStartDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[600]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(_loanStartDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Icon(Icons.calendar_today,
                            size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = _loanNameController.text.trim();
                      final principal =
                          double.tryParse(_loanPrincipalController.text.trim());
                      final rate =
                          double.tryParse(_loanRateController.text.trim());
                      final months =
                          int.tryParse(_loanMonthsController.text.trim());
                      final extra =
                          double.tryParse(_loanExtraController.text.trim()) ??
                              0;
                      final penalty =
                          double.tryParse(_loanPenaltyController.text.trim()) ??
                              0;
                      if (name.isEmpty ||
                          principal == null ||
                          rate == null ||
                          months == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill all required fields'),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }

                      final loan = Loan(
                        id: isEditing
                            ? _editingLoan?.id ??
                                DateTime.now().millisecondsSinceEpoch.toString()
                            : DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        principal: principal,
                        annualRate: rate,
                        months: months,
                        extraPayment: extra,
                        missedPaymentPenalty: penalty,
                        startDate: _loanStartDate,
                      );

                      await _firestore.saveLoan(loan);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent[700],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isEditing ? 'Update Loan' : 'Add Loan',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add Task Dialog
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('New Task', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Task title',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title:
                  const Text('Due Date', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                DateFormat('MMM dd, yyyy').format(_taskDueDate),
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.calendar_today, color: Colors.grey),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _taskDueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _taskDueDate = picked);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = _taskController.text.trim();
              if (title.isEmpty) return;
              final newTask = Task(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title,
                dueDate: _taskDueDate,
              );
              await _firestore.saveTask(newTask);
              _taskController.clear();
              _taskDueDate = DateTime.now().add(const Duration(days: 1));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent[700],
            ),
            child: const Text('Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // Budget Dialog
  void _showAddBudgetDialog() {
    _selectedBudgetCategory = 'General';
    _budgetLimitController.clear();
    _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Set Monthly Budget',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedBudgetCategory,
              style: const TextStyle(color: Colors.white),
              dropdownColor: const Color(0xFF2C2C2C),
              decoration: const InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              items: transactionCategories.map((String cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(cat, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  _selectedBudgetCategory = newValue;
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _budgetLimitController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Monthly Limit (\$)',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final limit = double.tryParse(_budgetLimitController.text.trim());
              if (limit == null || limit <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid budget amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final budget = Budget(
                category: _selectedBudgetCategory,
                limit: limit,
                month: _currentMonth,
              );
              await _firestore.saveBudget(budget);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent[700],
            ),
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // Confirm Delete Loan
  void _confirmDeleteLoan(Loan loan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            const Text('Delete Loan?', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${loan.name}"?',
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              await _firestore.deleteLoan(loan.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Confirm Delete Budget
  void _confirmDeleteBudget(Budget budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            const Text('Delete Budget?', style: TextStyle(color: Colors.white)),
        content: Text('Delete budget for "${budget.category}"?',
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              await _firestore.deleteBudget(budget.category);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ---------- Stream Combiner ----------
  Stream<Map<String, dynamic>> _getAllStreams() async* {
    final txStream = _firestore.streamTransactions();
    final loanStream = _firestore.streamLoans();
    final farmStream = _firestore.streamFarmItems();
    final taskStream = _firestore.streamTasks();
    final unitStream = _firestore.streamUnit();
    final budgetStream =
        _firestore.streamBudgets(DateFormat('yyyy-MM').format(DateTime.now()));

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    List<dynamic> latestData = [null, null, null, null, null, null];

    void checkAndEmit() {
      if (latestData.every((d) => d != null)) {
        controller.add({
          'transactions': latestData[0],
          'loans': latestData[1],
          'farmItems': latestData[2],
          'tasks': latestData[3],
          'unit': latestData[4],
          'budgets': latestData[5],
        });
      }
    }

    txStream.listen((data) {
      latestData[0] = data;
      checkAndEmit();
    });
    loanStream.listen((data) {
      latestData[1] = data;
      checkAndEmit();
    });
    farmStream.listen((data) {
      latestData[2] = data;
      checkAndEmit();
    });
    taskStream.listen((data) {
      latestData[3] = data;
      checkAndEmit();
    });
    unitStream.listen((data) {
      latestData[4] = data;
      checkAndEmit();
    });
    budgetStream.listen((data) {
      latestData[5] = data;
      checkAndEmit();
    });

    yield* controller.stream;
  }

  // ---------- Main Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text([
          '🌾 Haven OS', // Home
          '🐄 Batches', // Batches
          '💰 Finances', // Finances
          '📋 Records', // Records
          '📅 Schedule', // Schedule
          '💰 Budgets', // Budget
        ][_currentIndex]),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _getAllStreams(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading data: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final data = snapshot.data!;
          final transactions = data['transactions'] as List<Transaction>;
          final loans = data['loans'] as List<Loan>;
          final farmItems = data['farmItems'] as List<Map<String, dynamic>>;
          final tasks = data['tasks'] as List<Task>;
          final budgets = data['budgets'] as List<Budget>;
          final unit = data['unit'] as String;

          return IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeTab(transactions, tasks, budgets),
              _buildBatchesTab(farmItems, unit),
              _buildFinancesTab(transactions),
              _buildRecordsTab(loans),
              _buildScheduleTab(tasks),
              _buildBudgetTab(budgets, transactions),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2), label: 'Batches'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: 'Finances'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Records'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Schedule'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Budgets'),
        ],
      ),
    );
  }

  // ---------- Settings Dialog ----------
  void _showSettings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Unit toggle (will be saved to Firestore)
            ListTile(
              title: const Text('Unit System',
                  style: TextStyle(color: Colors.white)),
              subtitle: StreamBuilder<String>(
                stream: _firestore.streamUnit(),
                initialData: 'KG',
                builder: (context, snapshot) {
                  final unit = snapshot.data ?? 'KG';
                  return Text('Current: $unit',
                      style: const TextStyle(color: Colors.grey));
                },
              ),
              trailing: StreamBuilder<String>(
                stream: _firestore.streamUnit(),
                initialData: 'KG',
                builder: (context, snapshot) {
                  final unit = snapshot.data ?? 'KG';
                  return ToggleButtons(
                    isSelected: [
                      unit == 'KG',
                      unit == 'LB',
                    ],
                    onPressed: (index) async {
                      final newUnit = index == 0 ? 'KG' : 'LB';
                      await _firestore.saveUnit(newUnit);
                      Navigator.pop(ctx);
                    },
                    color: Colors.grey,
                    selectedColor: Colors.tealAccent,
                    children: const [Text('KG'), Text('LB')],
                  );
                },
              ),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              leading: const Icon(Icons.logout, color: Colors.red),
              onTap: () {
                Navigator.pop(ctx);
                // Clear storage and navigate to sign in
                const FlutterSecureStorage().delete(key: 'auth_username');
                Navigator.pushReplacementNamed(context, '/signin');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// ---------- Legend Item ----------
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
