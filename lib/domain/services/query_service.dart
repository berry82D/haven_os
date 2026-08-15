import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/models/animal.dart';
import 'package:haven_os/models/bill.dart';
import 'package:haven_os/models/task.dart';

/// Haven Query Service – answers natural language questions about your household
class QueryService {
  const QueryService();

  /// Main entry point – processes a user query and returns a response
  Map<String, dynamic> answer(
    String query, {
    required List<Transaction> transactions,
    required List<Animal> animals,
    required List<Bill> bills,
    required List<Task> tasks,
  }) {
    final lower = query.toLowerCase().trim();

    // ---- Detect and route to specific handlers ----

    if (_isBalanceQuestion(lower)) {
      return _answerBalance(transactions, bills);
    }

    if (_isTodayQuestion(lower)) {
      return _answerToday(animals, bills, tasks);
    }

    if (_isFarmQuestion(lower)) {
      return _answerFarm(animals);
    }

    if (_isBillsQuestion(lower)) {
      return _answerBills(bills);
    }

    if (_isTasksQuestion(lower)) {
      return _answerTasks(tasks);
    }

    if (_isSpendingQuestion(lower)) {
      return _answerSpending(transactions);
    }

    if (_isHelpQuestion(lower)) {
      return _answerHelp();
    }

    // ---- Default fallback ----
    return {
      'type': 'general',
      'message':
          'I can help with money, farm, bills, tasks, or what needs attention today. Ask me something specific.',
    };
  }

  // ---- Question Detection ----

  bool _isBalanceQuestion(String query) {
    final words = [
      'how much',
      'balance',
      'have',
      'money',
      'spend',
      'safe to spend',
      'available'
    ];
    return words.any((w) => query.contains(w));
  }

  bool _isTodayQuestion(String query) {
    final words = [
      'today',
      'attention',
      'need',
      'focus',
      'what\'s up',
      'status'
    ];
    return words.any((w) => query.contains(w));
  }

  bool _isFarmQuestion(String query) {
    final words = [
      'animal',
      'livestock',
      'farm',
      'pig',
      'cow',
      'chicken',
      'goat',
      'sheep',
      'horse'
    ];
    return words.any((w) => query.contains(w));
  }

  bool _isBillsQuestion(String query) {
    final words = ['bill', 'due', 'pay', 'owed', 'invoice'];
    return words.any((w) => query.contains(w));
  }

  bool _isTasksQuestion(String query) {
    final words = ['task', 'to do', 'todo', 'chore', 'need to', 'should'];
    return words.any((w) => query.contains(w));
  }

  bool _isSpendingQuestion(String query) {
    final words = [
      'spent',
      'spending',
      'expense',
      'cost',
      'paid',
      'buy',
      'purchase'
    ];
    return words.any((w) => query.contains(w));
  }

  bool _isHelpQuestion(String query) {
    final words = [
      'help',
      'what can you do',
      'what do you do',
      'capabilities',
      'can you'
    ];
    return words.any((w) => query.contains(w));
  }

  // ---- Response Handlers ----

  Map<String, dynamic> _answerBalance(
      List<Transaction> transactions, List<Bill> bills) {
    final totalIncome = _calculateTotalIncome(transactions);
    final totalExpenses = _calculateTotalExpenses(transactions);
    final balance = totalIncome - totalExpenses;

    // Calculate upcoming bills (7 days)
    final upcomingBills = bills.where(
        (b) => !b.isPaid && b.dueDate.difference(DateTime.now()).inDays <= 7);

    final upcomingTotal = upcomingBills.fold(0.0, (s, b) => s + b.amount);
    final safeToSpend = balance - upcomingTotal;

    String message;
    if (transactions.isEmpty) {
      message =
          'You haven\'t added any transactions yet. Add some to track your balance.';
    } else if (safeToSpend < 0) {
      message =
          '⚠️ Your account may go negative. You have \$${safeToSpend.toStringAsFixed(2)} available after bills.';
    } else if (upcomingTotal > 0) {
      message =
          '💵 You have \$${safeToSpend.toStringAsFixed(2)} available after ${upcomingBills.length} upcoming bills totaling \$${upcomingTotal.toStringAsFixed(2)}.';
    } else {
      message =
          '💵 You have \$${balance.toStringAsFixed(2)} available. No bills due this week.';
    }

    return {
      'type': 'balance',
      'safeToSpend': safeToSpend,
      'income': totalIncome,
      'expenses': totalExpenses,
      'balance': balance,
      'upcomingBills': upcomingBills.length,
      'upcomingBillsTotal': upcomingTotal,
      'message': message,
    };
  }

  Map<String, dynamic> _answerToday(
      List<Animal> animals, List<Bill> bills, List<Task> tasks) {
    final pendingTasks = tasks.where((t) => !t.isDone);
    final upcomingBills = bills.where(
        (b) => !b.isPaid && b.dueDate.difference(DateTime.now()).inDays <= 3);
    final poorHealth = animals.where((a) => a.health == 'Poor');

    final parts = <String>[];
    if (pendingTasks.isNotEmpty) {
      parts.add('${pendingTasks.length} tasks need attention');
    }
    if (upcomingBills.isNotEmpty) {
      final total = upcomingBills.fold(0.0, (s, b) => s + b.amount);
      parts.add(
          '${upcomingBills.length} bills totaling \$${total.toStringAsFixed(2)} due soon');
    }
    if (poorHealth.isNotEmpty) {
      parts.add('${poorHealth.length} animals need care');
    }

    String message;
    if (parts.isEmpty) {
      message = '🌿 Quiet day. No tasks, no bills due, all animals healthy.';
    } else {
      message = '📋 ${parts.join(' • ')}';
    }

    return {
      'type': 'today',
      'tasks': pendingTasks.length,
      'bills': upcomingBills.length,
      'healthIssues': poorHealth.length,
      'message': message,
    };
  }

  Map<String, dynamic> _answerFarm(List<Animal> animals) {
    if (animals.isEmpty) {
      return {
        'type': 'farm',
        'totalAnimals': 0,
        'feedCost': 0.0,
        'health': {'Good': 0, 'Fair': 0, 'Poor': 0},
        'message': 'No animals on the farm yet. Add some to track them!',
      };
    }

    final totalAnimals = animals.fold(0, (s, a) => s + a.count);
    final totalFeedCost = animals.fold(0.0, (s, a) => s + a.feedCost);
    final health = {
      'Good': animals.where((a) => a.health == 'Good').length,
      'Fair': animals.where((a) => a.health == 'Fair').length,
      'Poor': animals.where((a) => a.health == 'Poor').length,
    };

    String message;
    final poor = health['Poor'] ?? 0;
    if (poor > 0) {
      message =
          '🐾 $totalAnimals animals on the farm. Feed cost: \$${totalFeedCost.toStringAsFixed(2)}. ${poor} need attention.';
    } else {
      message =
          '🐾 $totalAnimals animals on the farm. Feed cost: \$${totalFeedCost.toStringAsFixed(2)}. All healthy!';
    }

    return {
      'type': 'farm',
      'totalAnimals': totalAnimals,
      'feedCost': totalFeedCost,
      'health': health,
      'message': message,
    };
  }

  Map<String, dynamic> _answerBills(List<Bill> bills) {
    if (bills.isEmpty) {
      return {
        'type': 'bills',
        'count': 0,
        'thisWeek': 0,
        'totalDue': 0.0,
        'message': 'No bills tracked yet.',
      };
    }

    final unpaid = bills.where((b) => !b.isPaid);
    final thisWeek =
        unpaid.where((b) => b.dueDate.difference(DateTime.now()).inDays <= 7);
    final totalDue = unpaid.fold(0.0, (s, b) => s + b.amount);

    String message;
    if (unpaid.isEmpty) {
      message = '🎉 All bills are paid!';
    } else if (thisWeek.isNotEmpty) {
      message =
          '📄 ${thisWeek.length} bills totaling \$${totalDue.toStringAsFixed(2)} due this week.';
    } else {
      message =
          '📄 ${unpaid.length} bills totaling \$${totalDue.toStringAsFixed(2)} due later.';
    }

    return {
      'type': 'bills',
      'count': unpaid.length,
      'thisWeek': thisWeek.length,
      'totalDue': totalDue,
      'message': message,
    };
  }

  Map<String, dynamic> _answerTasks(List<Task> tasks) {
    if (tasks.isEmpty) {
      return {
        'type': 'tasks',
        'pending': 0,
        'done': 0,
        'message': 'No tasks yet. Add some to stay organized!',
      };
    }

    final pending = tasks.where((t) => !t.isDone);
    final done = tasks.where((t) => t.isDone);

    String message;
    if (pending.isEmpty) {
      message = '🎉 All ${done.length} tasks are complete! Great job!';
    } else {
      message = '📋 ${pending.length} tasks pending, ${done.length} completed.';
    }

    return {
      'type': 'tasks',
      'pending': pending.length,
      'done': done.length,
      'message': message,
    };
  }

  Map<String, dynamic> _answerSpending(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return {
        'type': 'spending',
        'message': 'No spending recorded yet.',
      };
    }

    // Get last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recent = transactions.where((t) => t.date.isAfter(thirtyDaysAgo));
    final totalSpent = recent
        .where((t) => t.amount < 0)
        .fold(0.0, (s, t) => s + t.amount.abs());

    // Top categories
    final categoryTotals = <String, double>{};
    for (final t in recent.where((t) => t.amount < 0)) {
      categoryTotals[t.category] =
          (categoryTotals[t.category] ?? 0) + t.amount.abs();
    }
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sorted
        .take(3)
        .map((e) => '${e.key}: \$${e.value.toStringAsFixed(2)}')
        .join(' • ');

    return {
      'type': 'spending',
      'total': totalSpent,
      'topCategories': topCategories,
      'message':
          '💳 You spent \$${totalSpent.toStringAsFixed(2)} in the last 30 days. Top categories: $topCategories',
    };
  }

  Map<String, dynamic> _answerHelp() {
    return {
      'type': 'help',
      'message': 'I can help with questions about your household. Try asking:\n'
          '• "How much can I spend?"\n'
          '• "What needs attention today?"\n'
          '• "How are my animals?"\n'
          '• "What bills are due?"\n'
          '• "How much have I spent this month?"\n'
          '• "Show me my tasks"',
    };
  }

  // ---- Helper Methods ----

  double _calculateTotalIncome(List<Transaction> transactions) {
    return transactions
        .where((t) => t.amount > 0)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double _calculateTotalExpenses(List<Transaction> transactions) {
    return transactions
        .where((t) => t.amount < 0)
        .fold(0.0, (s, t) => s + t.amount.abs());
  }
}
