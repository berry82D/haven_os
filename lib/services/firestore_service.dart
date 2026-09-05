import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

// ---------- Loan Model ----------
class Loan {
  String id;
  String name;
  double principal;
  double annualRate;
  int months;
  double extraPayment;
  double missedPaymentPenalty;
  DateTime startDate;

  Loan({
    required this.id,
    required this.name,
    required this.principal,
    required this.annualRate,
    required this.months,
    this.extraPayment = 0,
    this.missedPaymentPenalty = 0,
    required this.startDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'principal': principal,
        'annualRate': annualRate,
        'months': months,
        'extraPayment': extraPayment,
        'missedPaymentPenalty': missedPaymentPenalty,
        'startDate': startDate.toIso8601String(),
      };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        id: json['id'],
        name: json['name'],
        principal: json['principal'].toDouble(),
        annualRate: json['annualRate'].toDouble(),
        months: json['months'],
        extraPayment: json['extraPayment']?.toDouble() ?? 0,
        missedPaymentPenalty: json['missedPaymentPenalty']?.toDouble() ?? 0,
        startDate: DateTime.parse(json['startDate']),
      );
}

// ---------- Task Model ----------
class Task {
  String id;
  String title;
  bool isDone;
  DateTime dueDate;

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    DateTime? dueDate,
  }) : dueDate = dueDate ?? DateTime.now().add(const Duration(days: 1));

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'dueDate': dueDate.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        isDone: json['isDone'] ?? false,
        dueDate: DateTime.parse(json['dueDate']),
      );
}

// ---------- Firestore Service ----------
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String> _getUserId() async {
    final username = await _storage.read(key: 'auth_username');
    if (username == null || username.isEmpty) {
      throw Exception('User not logged in');
    }
    return username;
  }

  // ---------- TRANSACTIONS ----------
  Future<void> saveTransaction(Transaction tx) async {
    final userId = await _getUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(tx.id)
        .set(tx.toJson());
  }

  Stream<List<Transaction>> streamTransactions() async* {
    final userId = await _getUserId();
    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Transaction.fromJson(doc.data()))
            .toList());
  }

  Future<void> deleteTransaction(String txId) async {
    final userId = await _getUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(txId)
        .delete();
  }

  // ---------- BUDGETS ----------
  Future<void> saveBudget(Budget budget) async {
    final userId = await _getUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budget.category)
        .set(budget.toJson());
  }

  Stream<List<Budget>> streamBudgets(String month) async* {
    final userId = await _getUserId();
    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Budget.fromJson(doc.data())).toList());
  }

  Future<void> deleteBudget(String category) async {
    final userId = await _getUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(category)
        .delete();
  }

  // ---------- LOANS ----------
  Future<void> saveLoan(Loan loan) async {
    final userId = await _getUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('loans')
        .doc(loan.id)
        .set(loan.toJson());
  }

  Stream<List<Loan>> streamLoans() async* {
    final userId = await _getUserId();
    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('loans')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Loan.fromJson(doc.data())).toList());
  }

  Future<void> deleteLoan(String loanId) async {
    final userId = await _getUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('loans')
        .doc(loanId)
        .delete();
  }

  // ---------- FARM ITEMS ----------
  Future<void> saveFarmItem(Map<String, dynamic> item) async {
    final userId = await _getUserId();
    final id = item['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('farmItems')
        .doc(id)
        .set(item);
  }

  Stream<List<Map<String, dynamic>>> streamFarmItems() async* {
    final userId = await _getUserId();
    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('farmItems')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> deleteFarmItem(String itemId) async {
    final userId = await _getUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('farmItems')
        .doc(itemId)
        .delete();
  }

  // ---------- TASKS ----------
  Future<void> saveTask(Task task) async {
    final userId = await _getUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id)
        .set(task.toJson());
  }

  Stream<List<Task>> streamTasks() async* {
    final userId = await _getUserId();
    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromJson(doc.data())).toList());
  }

  Future<void> deleteTask(String taskId) async {
    final userId = await _getUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // ---------- UNIT ----------
  Future<void> saveUnit(String unit) async {
    final userId = await _getUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .set({'unit': unit}, firestore.SetOptions(merge: true));
  }

  Stream<String> streamUnit() async* {
    final userId = await _getUserId();
    yield* _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => (doc.data()?['unit'] as String?) ?? 'KG');
  }
}
