// lib/features/haven_central/haven_central_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Transaction model with JSON support
class HavenTransaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String type; // 'income' or 'expense'
  final DateTime date;
  final String note;

  HavenTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.note = '',
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'type': type,
        'date': date.toIso8601String(),
        'note': note,
      };

  // Create from JSON
  factory HavenTransaction.fromJson(Map<String, dynamic> json) {
    return HavenTransaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      category: json['category'],
      type: json['type'],
      date: DateTime.parse(json['date']),
      note: json['note'] ?? '',
    );
  }
}

class Task {
  final String title;
  final bool isDone;
  final DateTime dueDate;
  Task({required this.title, this.isDone = false, required this.dueDate});
}

class HavenCentralViewModel extends ChangeNotifier {
  // ---------- Transaction list ----------
  List<HavenTransaction> _transactions = [];
  List<HavenTransaction> get transactions => _transactions;

  // ---------- Financial totals ----------
  List<double> _monthlyExpenses = [
    120,
    90,
    150,
    80,
    200,
    130,
    110,
    95,
    160,
    140,
    100,
    170
  ];
  List<double> get monthlyExpenses => _monthlyExpenses;

  double _totalIncome = 3000;
  double _totalExpenses = 1400;
  double get safeToSpend => _totalIncome - _totalExpenses;

  double get totalIncome => _totalIncome;
  double get totalExpenses => _totalExpenses;

  // ---------- Constructor – load saved transactions ----------
  HavenCentralViewModel() {
    _loadTransactions();
  }

  // ---------- Load transactions from disk ----------
  Future<void> _loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('transactions');
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _transactions =
            decoded.map((item) => HavenTransaction.fromJson(item)).toList();
        _recalculateTotals();
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, start with empty list
      _transactions = [];
      notifyListeners();
    }
  }

  // ---------- Save transactions to disk ----------
  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _transactions.map((tx) => tx.toJson()).toList();
    await prefs.setString('transactions', jsonEncode(jsonList));
  }

  // ---------- Recalculate totals from transactions ----------
  void _recalculateTotals() {
    _totalIncome = _transactions
        .where((tx) => tx.type == 'income')
        .fold(0.0, (sum, tx) => sum + tx.amount);
    _totalExpenses = _transactions
        .where((tx) => tx.type == 'expense')
        .fold(0.0, (sum, tx) => sum + tx.amount);
    // Rebuild monthly expenses (simplified: last 12 months from transactions)
    // For demo, we keep the hardcoded monthly expenses – you can extend this.
  }

  // ---------- Add a transaction ----------
  Future<void> addTransaction({
    required String title,
    required double amount,
    required String category,
    required String type,
    DateTime? date,
    String note = '',
  }) async {
    final newTransaction = HavenTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: category,
      type: type,
      date: date ?? DateTime.now(),
      note: note,
    );
    _transactions.insert(0, newTransaction); // newest first
    _recalculateTotals();
    notifyListeners();
    await _saveTransactions();
  }

  // ---------- Convenience methods (keep the existing interface) ----------
  void addExpense(double amount, String category) {
    addTransaction(
      title: category,
      amount: amount,
      category: category,
      type: 'expense',
    );
  }

  void addIncome(double amount, String category) {
    addTransaction(
      title: category,
      amount: amount,
      category: category,
      type: 'income',
    );
  }

  // ---------- Farm data (unchanged) ----------
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

  // ---------- Tasks (unchanged) ----------
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

  // ---------- Health score ----------
  int get healthScore {
    int score = 70;
    if (_totalIncome > _totalExpenses * 1.2) score += 10;
    if (_feedInventory.values.every((v) => v > 100)) score += 10;
    if (tasks.where((t) => !t.isDone).length < 3) score += 10;
    return score.clamp(0, 100);
  }
}
