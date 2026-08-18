// lib/services/app_state.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/models/bill.dart';
import 'package:haven_os/models/animal.dart';
import 'package:haven_os/models/task.dart';
import 'package:haven_os/models/loan.dart';
import 'package:haven_os/models/feed_delivery.dart';
import 'package:haven_os/models/timeline_event.dart';
import 'package:haven_os/models/join_request.dart';

// ===== ApprovalRequest model =====
class ApprovalRequest {
  final String id;
  final String description;
  final double amount;
  final String userId;
  final DateTime timestamp;
  final bool isIncome;

  ApprovalRequest({
    required this.id,
    required this.description,
    required this.amount,
    required this.userId,
    required this.timestamp,
    this.isIncome = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'isIncome': isIncome,
      };

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) =>
      ApprovalRequest(
        id: json['id'],
        description: json['description'],
        amount: json['amount'],
        userId: json['userId'],
        timestamp: DateTime.parse(json['timestamp']),
        isIncome: json['isIncome'] ?? false,
      );
}

// ===== Stub HealthScore =====
class HealthScore {
  final int score;
  final String level;
  final String message;
  final List<String> issues;
  HealthScore({
    required this.score,
    required this.level,
    required this.message,
    this.issues = const [],
  });
}

// ===== AppState =====
class AppState extends ChangeNotifier {
  static const String _pinKey = 'app_pin';
  static const String _isChildKey = 'is_child';
  static const String _isTeenKey = 'is_teen';
  static const String _transactionsKey = 'transactions';
  static const String _pendingRequestsKey = 'pending_requests';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isLocked = false;
  bool _pinVerified = false;
  bool _isChild = false;
  bool _isTeen = false;
  UserAccount? _currentUser;

  List<Transaction> _transactions = [];
  List<Bill> _bills = [];
  List<ApprovalRequest> _pendingRequests = [];

  // --- Getters ---
  bool get isLocked => _isLocked;
  bool get isPinVerified => _pinVerified;
  bool get isChildAccount => _isChild;
  bool get isTeenAccount => _isTeen;
  UserAccount? get currentUser => _currentUser;
  bool get isParentAccount => _currentUser?.role == UserRole.adult;
  bool get isPinEnabled => _pinVerified;
  bool get pinVerified => _pinVerified;
  bool get learningMode => _isChild;

  List<Transaction> get transactions => _transactions;
  List<Transaction> get myTransactions => _transactions;
  List<Bill> get bills => _bills;
  List<Bill> get myBills => _bills;
  List<ApprovalRequest> get pendingRequests => _pendingRequests;

  // --- Other stubs ---
  List<Animal> get myAnimals => [];
  List<Animal> get animals => [];
  List<Task> get myTasks => [];
  List<Task> get tasks => [];
  List<Loan> get loans => [];
  List<FeedDelivery> get feedDeliveries => [];
  List<TimelineEvent> get timelineEvents => [];
  List<TimelineEvent> get myTimelineEvents => [];
  List<JoinRequest> get joinRequests => [];

  dynamic get finance => {
        'income': 0,
        'expenses': 0,
        'debt': 0,
        'savings': 0,
        'categories': <String, double>{},
      };
  String get briefing => 'Good morning! No updates.';
  HealthScore get healthScore => HealthScore(
        score: 85,
        level: 'Good',
        message: 'Your household is doing well!',
        issues: [],
      );
  dynamic get learningService => null;
  dynamic get query => null;

  // --- Constructor ---
  AppState() {
    initialize();
  }

  // --- Initialization ---
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isChild = prefs.getBool(_isChildKey) ?? false;
    _isTeen = prefs.getBool(_isTeenKey) ?? false;
    _currentUser = UserAccount(
      id: '1',
      name: 'Test User',
      householdId: 'household_1',
      role: UserRole.adult,
    );
    await _loadTransactions();
    await _loadPendingRequests();
    notifyListeners();
  }

  // --- Transaction persistence ---
  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_transactionsKey);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _transactions =
            decoded.map((item) => Transaction.fromJson(item)).toList();
      } catch (_) {
        _transactions = [];
      }
    } else {
      _transactions = [];
    }
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _transactions.map((tx) => tx.toJson()).toList();
    await prefs.setString(_transactionsKey, jsonEncode(jsonList));
  }

  // --- Transaction CRUD ---
  void addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction);
    _saveTransactions();
    notifyListeners();
  }

  void updateTransaction(Transaction transaction) {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      _saveTransactions();
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    _saveTransactions();
    notifyListeners();
  }

  // --- Pending requests persistence ---
  Future<void> _loadPendingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_pendingRequestsKey);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _pendingRequests =
            decoded.map((item) => ApprovalRequest.fromJson(item)).toList();
      } catch (_) {
        _pendingRequests = [];
      }
    } else {
      _pendingRequests = [];
    }
  }

  Future<void> _savePendingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _pendingRequests.map((req) => req.toJson()).toList();
    await prefs.setString(_pendingRequestsKey, jsonEncode(jsonList));
  }

  // --- Pending requests CRUD (FIXED) ---
  void addPendingRequest(ApprovalRequest request) {
    _pendingRequests.insert(0, request);
    _savePendingRequests();
    notifyListeners();
  }

  void approveRequest(String id) {
    final oldLength = _pendingRequests.length;
    _pendingRequests.removeWhere((req) => req.id == id);
    if (_pendingRequests.length != oldLength) {
      _savePendingRequests();
      notifyListeners();
    }
  }

  void rejectRequest(String id) {
    final oldLength = _pendingRequests.length;
    _pendingRequests.removeWhere((req) => req.id == id);
    if (_pendingRequests.length != oldLength) {
      _savePendingRequests();
      notifyListeners();
    }
  }

  // --- Bills ---
  void addBill(Bill bill) {
    _bills.insert(0, bill);
    notifyListeners();
  }

  void deleteBill(String id) {
    _bills.removeWhere((bill) => bill.id == id);
    notifyListeners();
  }

  void toggleBillPaid(String id) {
    final index = _bills.indexWhere((bill) => bill.id == id);
    if (index != -1) {
      final bill = _bills[index];
      _bills[index] = Bill(
        id: bill.id,
        name: bill.name,
        amount: bill.amount,
        dueDate: bill.dueDate,
        isPaid: !bill.isPaid,
        userId: bill.userId,
        category: bill.category,
      );
      notifyListeners();
    }
  }

  // --- Sign In ---
  Future<bool> signIn(String email, String password, String role) async {
    if (role == 'Child') {
      _isChild = true;
      _isTeen = false;
    } else if (role == 'Teen') {
      _isChild = false;
      _isTeen = true;
    } else {
      _isChild = false;
      _isTeen = false;
    }
    UserRole userRole;
    if (role == 'Child') {
      userRole = UserRole.child;
    } else if (role == 'Teen') {
      userRole = UserRole.teen;
    } else {
      userRole = UserRole.adult;
    }
    _currentUser = UserAccount(
      id: '1',
      name: 'Test User',
      householdId: 'household_1',
      role: userRole,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isChildKey, _isChild);
    await prefs.setBool(_isTeenKey, _isTeen);
    notifyListeners();
    return true;
  }

  // --- User & PIN methods ---
  void setCurrentUser(UserAccount user) {
    _currentUser = user;
    notifyListeners();
  }

  void lockApp() {
    _isLocked = true;
    _pinVerified = false;
    notifyListeners();
  }

  Future<void> unlockApp(String pin) async {
    final storedPin = await _secureStorage.read(key: _pinKey);
    if (storedPin != null && storedPin == pin) {
      _pinVerified = true;
      _isLocked = false;
      notifyListeners();
    }
  }

  bool needsPinReentry() => _isLocked && !_pinVerified;

  void setPinVerified(bool value) {
    _pinVerified = value;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
  }

  Future<bool> hasPin() async {
    final pin = await _secureStorage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> enablePin(String pin) async {
    await setPin(pin);
    _pinVerified = true;
    notifyListeners();
  }

  Future<void> disablePin() async {
    await _secureStorage.delete(key: _pinKey);
    _pinVerified = false;
    notifyListeners();
  }

  void logout() {
    _isLocked = false;
    _pinVerified = false;
    notifyListeners();
  }

  // --- Strong password validation helper ---
  static String? validatePassword(String password) {
    if (password.length < 8) return 'Minimum 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Need 1 uppercase';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'Need 1 lowercase';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Need 1 number';
    return null;
  }

  // --- Stubs ---
  void setLearningMode(bool value) {}
  void refresh() {}
  void resetAllData() {}
  void clearTimelineEvents() {}
  void approveJoinRequest(String id) {}
  void rejectJoinRequest(String id) {}
  Future<void> promoteToParent(String userId) async {
    notifyListeners();
  }

  List<UserAccount> getHouseholdMembers() => [];
}
