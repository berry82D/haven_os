import 'package:flutter/material.dart';
import 'package:haven_os/models/animal.dart';
import 'package:haven_os/models/bill.dart';
import 'package:haven_os/models/task.dart';
import 'package:haven_os/models/transaction.dart';

class HealthScoreService {
  /// Calculates a household health score from 0-100
  ///
  /// Categories (each contributes its own points directly, summed
  /// to 100 — NOT compounded/decayed against each other):
  /// - Financial Health (0-40 points)
  /// - Task Management (0-20 points)
  /// - Bill Status (0-20 points)
  /// - Animal Health (0-20 points)
  HealthScore calculate({
    required List<Transaction> transactions,
    required List<Bill> bills,
    required List<Task> tasks,
    required List<Animal> animals,
  }) {
    final issues = <String>[];

    // 1. FINANCIAL HEALTH (0-40 points)
    final financialScore = _calculateFinancialScore(transactions, bills);
    if (financialScore < 20) {
      issues.add('⚠️ Financial health is critical');
    } else if (financialScore < 30) {
      issues.add('📊 Budget needs attention');
    }

    // 2. TASK MANAGEMENT (0-20 points)
    final taskScore = _calculateTaskScore(tasks);
    final overdueTasks = tasks
        .where((t) =>
            !t.isDone &&
            t.dueDate.isBefore(DateTime.now())) // ✅ removed null check and '!'
        .length;
    if (overdueTasks > 0) {
      issues.add('📋 $overdueTasks overdue tasks');
    }

    // 3. BILL STATUS (0-20 points)
    final billScore = _calculateBillScore(bills);
    final upcomingBills = bills.where(
        (b) => !b.isPaid && b.dueDate.difference(DateTime.now()).inDays <= 3);
    if (upcomingBills.isNotEmpty) {
      final total = upcomingBills.fold(0.0, (s, b) => s + b.amount);
      issues.add(
          '💰 ${upcomingBills.length} bills due soon: \$${total.toStringAsFixed(2)}');
    }

    // 4. ANIMAL HEALTH (0-20 points)
    final animalScore = _calculateAnimalScore(animals);
    final poorHealth = animals.where((a) => a.health == 'Poor');
    if (poorHealth.isNotEmpty) {
      issues.add('🐾 ${poorHealth.length} animals need care');
    }

    final score = financialScore + taskScore + billScore + animalScore;

    HealthLevel level;
    String message;

    if (score >= 80) {
      level = HealthLevel.excellent;
      message = '🌟 Your household is thriving!';
    } else if (score >= 60) {
      level = HealthLevel.good;
      message = '👍 Household is running well with a few things to check.';
    } else if (score >= 40) {
      level = HealthLevel.attention;
      message = '⚠️ Some areas need your attention.';
    } else {
      level = HealthLevel.critical;
      message = '🔴 Immediate action needed in your household.';
    }

    return HealthScore(
      score: score.clamp(0, 100),
      level: level,
      message: message,
      issues: issues,
      breakdown: {
        'financial': financialScore,
        'tasks': taskScore,
        'bills': billScore,
        'animals': animalScore,
      },
    );
  }

  int _calculateFinancialScore(
      List<Transaction> transactions, List<Bill> bills) {
    if (transactions.isEmpty) return 20;

    final totalIncome = transactions
        .where((t) => t.amount > 0)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpenses = transactions
        .where((t) => t.amount < 0)
        .fold(0.0, (s, t) => s + t.amount.abs());
    final balance = totalIncome - totalExpenses;

    final upcomingBillsTotal = bills
        .where((b) =>
            !b.isPaid && b.dueDate.difference(DateTime.now()).inDays <= 7)
        .fold(0.0, (s, b) => s + b.amount);

    final availableAfterBills = balance - upcomingBillsTotal;

    if (availableAfterBills < 0) return 0;
    if (availableAfterBills < 50) return 10;
    if (availableAfterBills < 200) return 20;
    if (availableAfterBills < 500) return 30;
    return 40;
  }

  int _calculateTaskScore(List<Task> tasks) {
    if (tasks.isEmpty) return 15;

    final total = tasks.length;
    final done = tasks.where((t) => t.isDone).length;
    final overdue = tasks
        .where((t) =>
            !t.isDone &&
            t.dueDate.isBefore(DateTime.now())) // ✅ removed null check and '!'
        .length;

    if (total == 0) return 20;

    final completionRate = done / total;
    final overduePenalty = (overdue / total) * 10;

    var score = (completionRate * 20).round();
    score = (score - overduePenalty).round();

    return score.clamp(0, 20);
  }

  int _calculateBillScore(List<Bill> bills) {
    if (bills.isEmpty) return 15;

    final total = bills.length;
    final paid = bills.where((b) => b.isPaid).length;
    final upcoming = bills
        .where((b) =>
            !b.isPaid && b.dueDate.difference(DateTime.now()).inDays <= 3)
        .length;

    if (upcoming > 0) return 0;

    final onTimeRate = paid / total;
    return (onTimeRate * 20).round().clamp(0, 20);
  }

  int _calculateAnimalScore(List<Animal> animals) {
    if (animals.isEmpty) return 15;

    final total = animals.length;
    final good = animals.where((a) => a.health == 'Good').length;
    final fair = animals.where((a) => a.health == 'Fair').length;
    final poor = animals.where((a) => a.health == 'Poor').length;

    if (poor > 0) return 0;
    if (fair > 2) return 5;
    if (fair > 0) return 10;
    if (good == total) return 20;

    return 15;
  }
}

class HealthScore {
  final int score;
  final HealthLevel level;
  final String message;
  final List<String> issues;
  final Map<String, int> breakdown;

  HealthScore({
    required this.score,
    required this.level,
    required this.message,
    required this.issues,
    required this.breakdown,
  });

  bool get isExcellent => level == HealthLevel.excellent;
  bool get isGood => level == HealthLevel.good;
  bool get needsAttention =>
      level == HealthLevel.attention || level == HealthLevel.critical;

  String get emoji {
    switch (level) {
      case HealthLevel.excellent:
        return '🌟';
      case HealthLevel.good:
        return '👍';
      case HealthLevel.attention:
        return '⚠️';
      case HealthLevel.critical:
        return '🔴';
    }
  }

  Color get color {
    switch (level) {
      case HealthLevel.excellent:
        return const Color(0xFF2E7D32);
      case HealthLevel.good:
        return const Color(0xFF4CAF50);
      case HealthLevel.attention:
        return const Color(0xFFFF9800);
      case HealthLevel.critical:
        return const Color(0xFFD32F2F);
    }
  }
}

enum HealthLevel {
  excellent,
  good,
  attention,
  critical,
}
