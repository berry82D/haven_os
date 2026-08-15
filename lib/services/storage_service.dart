import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/models/animal.dart';
import 'package:haven_os/models/bill.dart';
import 'package:haven_os/models/task.dart';
import 'package:haven_os/models/timeline_event.dart';
import 'package:haven_os/models/loan.dart';
import 'package:haven_os/models/feed_delivery.dart';
import 'package:haven_os/models/budget.dart';

class StorageService {
  static const String _key = 'haven_os_data';

  Future<void> migrateIfNeeded() async {}

  Future<Map<String, dynamic>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return {};
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveAll({
    required List<Transaction> transactions,
    required List<Animal> animals,
    required List<Bill> bills,
    required List<Task> tasks,
    required List<TimelineEvent> timelineEvents,
    required List<FeedDelivery> feedDeliveries,
    required List<Loan> loans,
    required List<Budget> budgets,
    required int learningMode,
    required int schoolAgeGroup,
    required bool allowFinalAnswers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'animals': animals.map((a) => a.toJson()).toList(),
      'bills': bills.map((b) => b.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'timelineEvents': timelineEvents.map((e) => e.toJson()).toList(),
      'feedDeliveries': feedDeliveries.map((f) => f.toJson()).toList(),
      'loans': loans.map((l) => l.toJson()).toList(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
      'learningMode': learningMode,
      'schoolAgeGroup': schoolAgeGroup,
      'allowFinalAnswers': allowFinalAnswers,
    };
    await prefs.setString(_key, jsonEncode(data));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
