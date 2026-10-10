import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/gig_job.dart';

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

  // ---------- DATA ROOT (household sharing) ----------
  static const List<String> _syncCollections = [
    'transactions',
    'budgets',
    'loans',
    'farmItems',
    'tasks',
    'gig_jobs',
  ];

  String? _rootKey;
  Future<firestore.DocumentReference<Map<String, dynamic>>>? _rootFuture;

  /// Where this user's data lives. If the phone has a household_id (saved at
  /// sign-in), data lives in households/{id} so every member sees the same
  /// thing, after a one-time MERGE of the old users/{username} folder into
  /// it. If anything fails the app keeps using users/{username}, so data
  /// never disappears from the screen. The old folder is never deleted.
  Future<firestore.DocumentReference<Map<String, dynamic>>>
      _dataRoot() async {
    final userId = await _getUserId();
    final hid = (await _storage.read(key: 'household_id')) ?? '';
    final key = '$userId|$hid';
    if (_rootKey != key || _rootFuture == null) {
      _rootKey = key;
      _rootFuture = _resolveRoot(userId, hid);
    }
    return _rootFuture!;
  }

  Future<firestore.DocumentReference<Map<String, dynamic>>> _resolveRoot(
      String userId, String hid) async {
    final own = _firestore.collection('users').doc(userId);
    if (hid.isEmpty) return own;
    try {
      final shared = _firestore.collection('households').doc(hid);
      await _mergeIntoHousehold(own, shared, hid);
      return shared;
    } catch (e) {
      debugPrint('household merge failed, using personal folder: $e');
      return own;
    }
  }

  /// Copies documents the household does not have yet. Never overwrites,
  /// never deletes. Recorded on users/{username}.mergedInto so it runs once.
  Future<void> _mergeIntoHousehold(
      firestore.DocumentReference<Map<String, dynamic>> own,
      firestore.DocumentReference<Map<String, dynamic>> shared,
      String hid) async {
    final ownSnap = await own.get();
    final done = (ownSnap.data()?['mergedInto'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    if (done.contains(hid)) return;

    for (final sub in _syncCollections) {
      final src = await own.collection(sub).get();
      if (src.docs.isEmpty) continue;
      final dst = await shared.collection(sub).get();
      final have = dst.docs.map((d) => d.id).toSet();
      var batch = _firestore.batch();
      var n = 0;
      for (final d in src.docs) {
        if (have.contains(d.id)) continue;
        batch.set(shared.collection(sub).doc(d.id), d.data());
        n++;
        if (n >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          n = 0;
        }
      }
      if (n > 0) await batch.commit();
    }

    await own.set({
      'mergedInto': firestore.FieldValue.arrayUnion([hid]),
    }, firestore.SetOptions(merge: true));
  }

  // ---------- TRANSACTIONS ----------
  Future<void> saveTransaction(Transaction tx) async {
    final root = await _dataRoot();
    await root
        .collection('transactions')
        .doc(tx.id)
        .set(tx.toJson());
  }

  Stream<List<Transaction>> streamTransactions() async* {
    final root = await _dataRoot();
    yield* root
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Transaction.fromJson(doc.data()))
            .toList());
  }

  Future<void> deleteTransaction(String txId) async {
    final root = await _dataRoot();
    await root
        .collection('transactions')
        .doc(txId)
        .delete();
  }

  // ---------- BUDGETS ----------
  Future<void> saveBudget(Budget budget) async {
    final root = await _dataRoot();
    await root
        .collection('budgets')
        .doc(budget.category)
        .set(budget.toJson());
  }

  Stream<List<Budget>> streamBudgets(String month) async* {
    final root = await _dataRoot();
    yield* root
        .collection('budgets')
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Budget.fromJson(doc.data())).toList());
  }

  Future<void> deleteBudget(String category) async {
    final root = await _dataRoot();
    await root
        .collection('budgets')
        .doc(category)
        .delete();
  }

  // ---------- LOANS ----------
  Future<void> saveLoan(Loan loan) async {
    final root = await _dataRoot();
    await root
        .collection('loans')
        .doc(loan.id)
        .set(loan.toJson());
  }

  Stream<List<Loan>> streamLoans() async* {
    final root = await _dataRoot();
    yield* root
        .collection('loans')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Loan.fromJson(doc.data())).toList());
  }

  Future<void> deleteLoan(String loanId) async {
    final root = await _dataRoot();
    await root
        .collection('loans')
        .doc(loanId)
        .delete();
  }

  // ---------- FARM ITEMS ----------
  Future<void> saveFarmItem(Map<String, dynamic> item) async {
    final root = await _dataRoot();
    final id = item['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await root
        .collection('farmItems')
        .doc(id)
        .set(item);
  }

  Stream<List<Map<String, dynamic>>> streamFarmItems() async* {
    final root = await _dataRoot();
    yield* root
        .collection('farmItems')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> deleteFarmItem(String itemId) async {
    final root = await _dataRoot();
    await root
        .collection('farmItems')
        .doc(itemId)
        .delete();
  }

  // ---------- TASKS ----------
  Future<void> saveTask(Task task) async {
    final root = await _dataRoot();
    await root
        .collection('tasks')
        .doc(task.id)
        .set(task.toJson());
  }

  Stream<List<Task>> streamTasks() async* {
    final root = await _dataRoot();
    yield* root
        .collection('tasks')
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Task.fromJson(doc.data())).toList());
  }

  Future<void> deleteTask(String taskId) async {
    final root = await _dataRoot();
    await root
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

  // ---------- GIG JOBS – Phase 4a – Law 11/13 ----------
  Future<void> saveGigJob(GigJob job) async {
    final root = await _dataRoot();
    await root
        .collection('gig_jobs')
        .doc(job.id)
        .set(job.toMap());
  }

  Stream<List<GigJob>> streamGigJobs() async* {
    final root = await _dataRoot();
    yield* root
        .collection('gig_jobs')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GigJob.fromMap(doc.data())).toList());
  }

  Future<void> deleteGigJob(String jobId) async {
    final root = await _dataRoot();
    await root
        .collection('gig_jobs')
        .doc(jobId)
        .delete();
  }
}
