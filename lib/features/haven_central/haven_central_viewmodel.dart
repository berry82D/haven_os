// lib/features/haven_central/haven_central_viewmodel.dart
import 'package:flutter/material.dart';

class Task {
  final String title;
  final bool isDone;
  final DateTime dueDate;
  Task({required this.title, this.isDone = false, required this.dueDate});
}

class HavenCentralViewModel extends ChangeNotifier {
  // ---------- YOUR REAL FINANCIAL DATA (JULY 2026) ----------

  // Starting balance
  double _startingBalance = 1542.96;
  double get startingBalance => _startingBalance;

  // Total income (for July, just the starting balance)
  double _totalIncome = 1542.96;
  double get totalIncome => _totalIncome;

  // Total expenses
  double _totalExpenses = 0.0;
  double get totalExpenses => _totalExpenses;

  // Monthly expenses by period (3 periods per month)
  List<double> _monthlyExpenses = [];

  // Category breakdown
  final Map<String, double> _expenseCategories = {};

  // All transactions
  final List<Map<String, dynamic>> _transactions = [];

  // Remaining balance by period
  Map<String, double> _periodRemaining = {};
  Map<String, double> get periodRemaining => _periodRemaining;

  // Safe to spend (average remaining)
  double _safeToSpend = 0.0;
  double get safeToSpend => _safeToSpend;

  // ---------- Load real data ----------
  HavenCentralViewModel() {
    _loadRealData();
  }

  void _loadRealData() {
    // Define your July transactions
    final List<Map<String, dynamic>> julyTransactions = [
      // === July 2nd (Period 1) ===
      {'date': 'July 2', 'category': 'Rent', 'amount': 325.00},
      {'date': 'July 2', 'category': 'Power', 'amount': 199.80},
      {'date': 'July 2', 'category': 'Insurance', 'amount': 327.55},
      {'date': 'July 2', 'category': 'Santander', 'amount': 438.67},
      {'date': 'July 2', 'category': 'Trash', 'amount': 85.00},

      // === July 16th (Period 2) ===
      {'date': 'July 16', 'category': 'Onemain', 'amount': 365.60},
      {'date': 'July 16', 'category': 'Santander', 'amount': 438.67},
      {'date': 'July 16', 'category': 'Trash', 'amount': 85.00},
      {'date': 'July 16', 'category': 'Netflix', 'amount': 21.39},
      {'date': 'July 16', 'category': 'AT&T', 'amount': 351.33},
      {'date': 'July 16', 'category': 'Subscriptions', 'amount': 35.00},

      // === July 30th (Period 3) ===
      {'date': 'July 30', 'category': 'Rent', 'amount': 325.00},
      {'date': 'July 30', 'category': 'Internet', 'amount': 153.95},
      {'date': 'July 30', 'category': 'Power', 'amount': 288.00},
      {'date': 'July 30', 'category': 'Santander', 'amount': 438.67},
      {'date': 'July 30', 'category': 'Trash', 'amount': 85.00},
    ];

    // Calculate totals
    double total = 0.0;
    for (var t in julyTransactions) {
      total += t['amount'] as double;
      final cat = t['category'] as String;
      _expenseCategories[cat] =
          (_expenseCategories[cat] ?? 0) + (t['amount'] as double);
    }
    _totalExpenses = total;

    // Group by period and calculate monthly expenses
    final period1 = julyTransactions
        .where((t) => t['date'] == 'July 2')
        .fold(0.0, (s, t) => s + (t['amount'] as double));
    final period2 = julyTransactions
        .where((t) => t['date'] == 'July 16')
        .fold(0.0, (s, t) => s + (t['amount'] as double));
    final period3 = julyTransactions
        .where((t) => t['date'] == 'July 30')
        .fold(0.0, (s, t) => s + (t['amount'] as double));

    // Fill 12 months (July = month 6, index 6)
    _monthlyExpenses = List.filled(12, 0.0);
    _monthlyExpenses[6] = period1 + period2 + period3;

    // Remaining after each period
    _periodRemaining = {
      'July 2': 568.02,
      'July 16': 547.00,
      'July 30': 653.42,
    };

    // Safe to spend = average remaining
    _safeToSpend = (_periodRemaining.values.reduce((a, b) => a + b)) /
        _periodRemaining.length;

    // Store transactions
    _transactions.addAll(julyTransactions);

    notifyListeners();
  }

  // ---------- Getters ----------
  List<double> get monthlyExpenses => _monthlyExpenses;
  Map<String, double> get expenseCategories => _expenseCategories;
  List<Map<String, dynamic>> get transactions => _transactions;

  // ---------- Add methods (for commands) ----------
  void addExpense(double amount, String category) {
    _totalExpenses += amount;
    _monthlyExpenses[_monthlyExpenses.length - 1] += amount;
    _expenseCategories[category] = (_expenseCategories[category] ?? 0) + amount;
    _transactions.add({
      'date': DateTime.now().toString().substring(0, 10),
      'category': category,
      'amount': amount,
    });
    notifyListeners();
  }

  void addIncome(double amount, String category) {
    _totalIncome += amount;
    notifyListeners();
  }

  // ---------- Farm data (replace with your real farm data if you have it) ----------
  final Map<String, int> _animalCounts = {
    '🐄 Cows': 12,
    '🐖 Pigs': 8,
    '🐔 Chickens': 45,
  };
  Map<String, int> get animalCounts => _animalCounts;

  final Map<String, int> _feedInventory = {
    'Hay': 250,
    'Grain': 180,
    'Feed Mix': 95,
  };
  Map<String, int> get feedInventory => _feedInventory;

  String farmStatus() {
    final totalAnimals = _animalCounts.values.fold(0, (a, b) => a + b);
    final lowFeed = _feedInventory.entries
        .where((e) => e.value < 100)
        .map((e) => e.key)
        .join(', ');
    return '🐮 Total animals: $totalAnimals\n'
        '🌾 Feed stock: ${_feedInventory.values.fold(0, (a, b) => a + b)} kg\n'
        '⚠️ Low feed: ${lowFeed.isNotEmpty ? lowFeed : 'none'}';
  }

  // ---------- Tasks ----------
  final List<Task> tasks = [
    Task(
        title: 'Fix fence',
        isDone: false,
        dueDate: DateTime.now().subtract(const Duration(days: 2))),
    Task(
        title: 'Order feed',
        isDone: false,
        dueDate: DateTime.now().add(const Duration(days: 3))),
    Task(
        title: 'Clean coop',
        isDone: true,
        dueDate: DateTime.now().subtract(const Duration(days: 5))),
  ];

  // ---------- Health score (calculated) ----------
  int get healthScore {
    int score = 70;
    if (_totalIncome > _totalExpenses * 1.2) score += 10;
    if (_feedInventory.values.every((v) => v > 100)) score += 10;
    if (tasks.where((t) => !t.isDone).length < 3) score += 10;
    return score.clamp(0, 100);
  }
}
