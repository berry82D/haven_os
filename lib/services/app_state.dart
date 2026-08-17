// lib/services/app_state.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import your models
import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/models/bill.dart';
import 'package:haven_os/models/animal.dart';
import 'package:haven_os/models/task.dart';
import 'package:haven_os/models/loan.dart';
import 'package:haven_os/models/feed_delivery.dart';
import 'package:haven_os/models/timeline_event.dart';
import 'package:haven_os/models/join_request.dart';

// Stub HealthScore class
class HealthScore {
  final int score;
  final String level;
  final String message;
  final List<String> issues;
  HealthScore(
      {required this.score,
      required this.level,
      required this.message,
      this.issues = const []});
}

class AppState extends ChangeNotifier {
  static const String _pinKey = 'app_pin';
  static const String _isChildKey = 'is_child';
  static const String _isTeenKey = 'is_teen';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isLocked = false;
  bool _pinVerified = false;
  bool _isChild = false;
  bool _isTeen = false;
  UserAccount? _currentUser;

  // --- Bills list ---
  List<Bill> _bills = [];
  List<Bill> get myBills => _bills;

  // --- Getters ---
  bool get isLocked => _isLocked;
  bool get isPinVerified => _pinVerified;
  bool get isChildAccount => _isChild;
  bool get isTeenAccount => _isTeen;
  UserAccount? get currentUser => _currentUser;

  // ✅ FIXED: removed UserRole.parent
  bool get isParentAccount => _currentUser?.role == UserRole.adult;

  bool get isPinEnabled => _pinVerified;
  bool get pinVerified => _pinVerified;
  bool get learningMode => _isChild;

  // Data getters – return empty lists
  List<Transaction> get myTransactions => [];
  List<Transaction> get transactions => [];
  List<Bill> get bills => _bills;
  List<Animal> get myAnimals => [];
  List<Animal> get animals => [];
  List<Task> get myTasks => [];
  List<Task> get tasks => [];
  List<Loan> get loans => [];
  List<FeedDelivery> get feedDeliveries => [];
  List<TimelineEvent> get timelineEvents => [];
  List<TimelineEvent> get myTimelineEvents => [];
  List<JoinRequest> get joinRequests => [];

  // Finance stub
  dynamic get finance => {
        'income': 0,
        'expenses': 0,
        'debt': 0,
        'savings': 0,
        'categories': <String, double>{},
      };
  String get briefing => 'Good morning! No updates.';

  // HealthScore
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

  // --- Initialize ---
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
    notifyListeners();
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

  // --- Set current user ---
  void setCurrentUser(UserAccount user) {
    _currentUser = user;
    notifyListeners();
  }

  // --- Lock / Pin ---
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

  bool needsPinReentry() {
    return _isLocked && !_pinVerified;
  }

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

  // --- BILL METHODS ---
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

  // --- DATA METHODS (stubs) ---
  void addTransaction(Transaction transaction) {}
  void updateTransaction(Transaction transaction) {}
  void deleteTransaction(String id) {}
  void addAnimal(Animal animal) {}
  void updateAnimal(Animal animal) {}
  void deleteAnimal(String id) {}
  void addTask(Task task) {}
  void toggleTaskDone(String id) {}
  void setLearningMode(bool value) {}
  void refresh() {}
  void resetAllData() {}
  void clearTimelineEvents() {}
  void approveJoinRequest(String id) {}
  void rejectJoinRequest(String id) {}
  void promoteToParent(String userId) {}
  List<UserAccount> getHouseholdMembers() => [];
}
