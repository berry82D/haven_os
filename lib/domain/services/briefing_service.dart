import 'package:flutter/material.dart';
import 'package:haven_os/domain/services/finance_service.dart';
import 'package:haven_os/domain/services/farm_service.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/models/animal.dart';
import 'package:haven_os/models/bill.dart';
import 'package:haven_os/models/task.dart';

class BriefingService {
  final FinanceService _finance;
  final FarmService _farm;

  BriefingService(this._finance, this._farm);

  double calculateSafeToSpend({
    required List<Transaction> transactions,
    required List<Bill> bills,
    bool includeUpcomingBills = true,
  }) {
    final totalIncome = _finance.calculateTotalIncome(transactions);
    final totalExpenses = _finance.calculateTotalExpenses(transactions);
    final currentBalance = totalIncome - totalExpenses;

    if (!includeUpcomingBills) return currentBalance;

    final upcomingBills = bills.where(
        (b) => !b.isPaid && b.dueDate.difference(DateTime.now()).inDays <= 7);

    final upcomingTotal = upcomingBills.fold(0.0, (s, b) => s + b.amount);
    return currentBalance - upcomingTotal;
  }

  Map<String, dynamic> generate({
    required List<Transaction> transactions,
    required List<Animal> animals,
    required List<Bill> bills,
    required List<Task> tasks,
  }) {
    final totalIncome = _finance.calculateTotalIncome(transactions);
    final totalExpenses = _finance.calculateTotalExpenses(transactions);

    final safeToSpend = calculateSafeToSpend(
      transactions: transactions,
      bills: bills,
      includeUpcomingBills: true,
    );

    final rawBalance = totalIncome - totalExpenses;
    final feedCost = _farm.calculateFeedCost(animals);
    final health = _farm.countHealth(animals);
    final pendingTasks = tasks.where((t) => !t.isDone);
    final upcomingBills = bills.where(
        (b) => !b.isPaid && b.dueDate.difference(DateTime.now()).inDays <= 7);
    final upcomingBillsTotal = upcomingBills.fold(0.0, (s, b) => s + b.amount);

    return {
      'safeToSpend': safeToSpend,
      'rawBalance': rawBalance,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'feedCost': feedCost,
      'health': health,
      'totalAnimals': animals.length,
      'pendingTasks': pendingTasks.length,
      'upcomingBills': upcomingBills.length,
      'upcomingBillsTotal': upcomingBillsTotal,
      'status': _getStatus(safeToSpend, health, upcomingBills),
    };
  }

  Status _getStatus(
      double safeToSpend, Map<String, int> health, Iterable<Bill> bills) {
    final poor = health['Poor'] ?? 0;
    final billsDue =
        bills.where((b) => b.dueDate.difference(DateTime.now()).inDays <= 3);

    if (safeToSpend < 0) {
      return Status.warning('Your account may go negative. Review spending.');
    }
    if (poor > 0) {
      return Status.attention('$poor animals need care.');
    }
    if (billsDue.isNotEmpty) {
      final total = billsDue.fold(0.0, (s, b) => s + b.amount);
      return Status.attention(
          '${billsDue.length} bills totaling \$${total.toStringAsFixed(2)} due soon.');
    }
    if (safeToSpend < 50) {
      return Status.info(
          'You have \$${safeToSpend.toStringAsFixed(2)} available. Budget carefully.');
    }
    return Status.good('Everything is running smoothly.');
  }
}

class Status {
  final String message;
  final StatusType type;

  Status._(this.message, this.type);

  factory Status.good(String message) => Status._(message, StatusType.good);
  factory Status.info(String message) => Status._(message, StatusType.info);
  factory Status.attention(String message) =>
      Status._(message, StatusType.attention);
  factory Status.warning(String message) =>
      Status._(message, StatusType.warning);

  Color get color => switch (type) {
        StatusType.good => Colors.green,
        StatusType.info => Colors.blue,
        StatusType.attention => Colors.orange,
        StatusType.warning => Colors.red,
      };

  String get icon => switch (type) {
        StatusType.good => '🟢',
        StatusType.info => '🔵',
        StatusType.attention => '🟡',
        StatusType.warning => '🔴',
      };
}

enum StatusType { good, info, attention, warning }
