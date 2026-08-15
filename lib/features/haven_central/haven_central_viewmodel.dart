// lib/features/haven_central/haven_central_viewmodel.dart
import 'package:flutter/material.dart';

class Task {
  final String title;
  final bool isDone;
  final DateTime dueDate;
  Task({required this.title, this.isDone = false, required this.dueDate});
}

class HavenCentralViewModel extends ChangeNotifier {
  // Financial data
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

  void addExpense(double amount, String category) {
    _totalExpenses += amount;
    _monthlyExpenses[_monthlyExpenses.length - 1] += amount;
    notifyListeners();
  }

  void addIncome(double amount, String category) {
    _totalIncome += amount;
    notifyListeners();
  }

  // Farm data
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

  // Tasks
  final List<Task> tasks = [
    Task(
        title: 'Fix fence',
        isDone: false,
        dueDate: DateTime.now().subtract(Duration(days: 2))),
    Task(
        title: 'Order feed',
        isDone: false,
        dueDate: DateTime.now().add(Duration(days: 3))),
    Task(
        title: 'Clean coop',
        isDone: true,
        dueDate: DateTime.now().subtract(Duration(days: 5))),
  ];

  // Health score
  int get healthScore {
    int score = 70;
    if (_totalIncome > _totalExpenses * 1.2) score += 10;
    if (_feedInventory.values.every((v) => v > 100)) score += 10;
    if (tasks.where((t) => !t.isDone).length < 3) score += 10;
    return score.clamp(0, 100);
  }
}
