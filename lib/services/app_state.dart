// lib/services/app_state.dart
import 'package:flutter/material.dart';
import 'package:haven_os/core/storage/storage_service.dart';
import 'package:haven_os/domain/services/finance_service.dart';
import 'package:haven_os/domain/services/farm_service.dart';
import 'package:haven_os/domain/services/briefing_service.dart';
import 'package:haven_os/domain/services/query_service.dart';
import 'package:haven_os/domain/services/health_score_service.dart';
import 'package:haven_os/domain/services/learning_service.dart';
import 'package:haven_os/domain/services/loan_service.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/models/animal.dart';
import 'package:haven_os/models/bill.dart';
import 'package:haven_os/models/task.dart';
import 'package:haven_os/models/timeline_event.dart';
import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/models/feed_delivery.dart';
import 'package:haven_os/models/loan.dart';
import 'package:haven_os/models/household.dart';
import 'package:haven_os/models/guardian_relationship.dart';
import 'package:haven_os/models/join_request.dart';
import 'package:haven_os/models/budget.dart';
import 'package:haven_os/domain/services/household_service.dart';
import 'package:haven_os/services/auth_service.dart';
import 'package:haven_os/core/enums/learning_mode.dart';

class AppState extends ChangeNotifier {
  // ---- Data ----
  List<Transaction> _transactions = [];
  List<Animal> _animals = [];
  List<Bill> _bills = [];
  List<Task> _tasks = [];
  List<TimelineEvent> _timelineEvents = [];
  List<FeedDelivery> _feedDeliveries = [];
  List<Loan> _loans = [];
  List<Household> _households = [];
  List<GuardianRelationship> _guardianRelationships = [];
  List<JoinRequest> _joinRequests = [];
  List<Budget> _budgets = [];

  // ---- Learning settings ----
  LearningMode _learningMode = LearningMode.standard;
  SchoolAgeGroup _schoolAgeGroup = SchoolAgeGroup.older;
  bool _allowFinalAnswers = false;

  // ---- Current User ----
  UserAccount? _currentUser;
  UserAccount? get currentUser => _currentUser;

  // ---- PIN cache ----
  bool _currentUserHasPin = false;
  bool get isPinEnabled => _currentUserHasPin;

  Future<void> _refreshPinStatus() async {
    _currentUserHasPin = _currentUser != null
        ? await AuthService.hasPin(_currentUser!.id)
        : false;
    notifyListeners();
  }

  // ---- PIN & Session State ----
  bool _pinVerifiedForUserId = false;
  String? _verifiedUserId;
  DateTime? _sessionStartTime;

  bool get pinVerified =>
      _pinVerifiedForUserId && _verifiedUserId == _currentUser?.id;
  bool get isPinVerified => pinVerified;

  void setPinVerified(bool verified) {
    if (verified) {
      _pinVerifiedForUserId = true;
      _verifiedUserId = _currentUser?.id;
      _sessionStartTime = DateTime.now();
    } else {
      _pinVerifiedForUserId = false;
      _verifiedUserId = null;
      _sessionStartTime = null;
    }
    notifyListeners();
  }

  void lockApp() {
    _pinVerifiedForUserId = false;
    _verifiedUserId = null;
    _sessionStartTime = null;
    notifyListeners();
  }

  bool needsPinReentry() {
    if (_currentUser == null) return false;
    if (!isPinEnabled) return false;
    if (pinVerified) {
      if (_sessionStartTime != null) {
        final elapsed = DateTime.now().difference(_sessionStartTime!);
        if (elapsed > const Duration(minutes: 5)) {
          return true;
        }
      }
      return false;
    }
    return true;
  }

  // ---- User & Session ----
  void setCurrentUser(UserAccount user) {
    _currentUser = user;
    _pinVerifiedForUserId = false;
    _verifiedUserId = null;
    _sessionStartTime = null;
    _migrateLegacyData();
    _refreshPinStatus();
    loadHouseholdsAndRequests();
    notifyListeners();
  }

  void signIn(UserAccount user) {
    setCurrentUser(user);
    setPinVerified(true);
  }

  void unlockApp() {
    setPinVerified(true);
  }

  void logout() async {
    await AuthService.logout();
    _currentUser = null;
    _pinVerifiedForUserId = false;
    _verifiedUserId = null;
    _sessionStartTime = null;
    _currentUserHasPin = false;
    _joinRequests = [];
    _households = [];
    notifyListeners();
  }

  bool get isChildAccount => _currentUser?.role == UserRole.child;
  bool get isTeenAccount => _currentUser?.role == UserRole.teen;
  bool get isParentAccount =>
      _currentUser?.role == UserRole.administrator ||
      _currentUser?.role == UserRole.adult;

  // ---- Filtered Getters ----
  List<Transaction> get myTransactions {
    if (_currentUser == null) return [];
    return _transactions.where((t) => t.userId == _currentUser!.id).toList();
  }

  List<Animal> get myAnimals {
    if (_currentUser == null) return [];
    return _animals.where((a) => a.userId == _currentUser!.id).toList();
  }

  List<Bill> get myBills {
    if (_currentUser == null) return [];
    return _bills.where((b) => b.userId == _currentUser!.id).toList();
  }

  List<Task> get myTasks => _tasks;

  List<TimelineEvent> get myTimelineEvents => _timelineEvents;

  List<FeedDelivery> get myFeedDeliveries {
    if (_currentUser == null) return [];
    return _feedDeliveries.where((f) => f.userId == _currentUser!.id).toList();
  }

  List<Loan> get myLoans {
    if (_currentUser == null) return [];
    return _loans.where((l) => l.userId == _currentUser!.id).toList();
  }

  List<Budget> get myBudgets {
    if (_currentUser == null) return [];
    return _budgets.where((b) => b.userId == _currentUser!.id).toList();
  }

  // ---- Unfiltered getters ----
  List<Transaction> get transactions => _transactions;
  List<Animal> get animals => _animals;
  List<Bill> get bills => _bills;
  List<Task> get tasks => _tasks;
  List<TimelineEvent> get timelineEvents => _timelineEvents;
  List<FeedDelivery> get feedDeliveries => _feedDeliveries;
  List<Loan> get loans => _loans;
  List<Household> get households => _households;
  List<JoinRequest> get joinRequests => _joinRequests;
  List<GuardianRelationship> get guardianRelationships =>
      _guardianRelationships;
  List<Budget> get budgets => _budgets;

  // ---- Learning ----
  LearningMode get learningMode => _learningMode;
  SchoolAgeGroup get schoolAgeGroup => _schoolAgeGroup;
  bool get allowFinalAnswers => _allowFinalAnswers;

  void setLearningMode(LearningMode mode) {
    _learningMode = mode;
    _saveData();
    notifyListeners();
  }

  void setSchoolAgeGroup(SchoolAgeGroup ageGroup) {
    _schoolAgeGroup = ageGroup;
    _saveData();
    notifyListeners();
  }

  void setAllowFinalAnswers(bool allow) {
    _allowFinalAnswers = allow;
    _saveData();
    notifyListeners();
  }

  // ---- Services ----
  final FinanceService finance = FinanceService();
  final FarmService farm = FarmService();
  final StorageService storage = StorageService();
  final HealthScoreService healthScoreService = HealthScoreService();
  final LoanService loanService = LoanService();

  BriefingService get briefing => BriefingService(finance, farm);
  QueryService get query => const QueryService();
  LearningService get learningService => LearningService(
        ageGroup: _schoolAgeGroup,
        allowFinalAnswers: _allowFinalAnswers,
      );

  // ---- State ----
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ---- Household & Join Requests ----
  Future<void> loadHouseholdsAndRequests() async {
    _households = await HouseholdService.loadHouseholds();
    _joinRequests = await HouseholdService.loadRequests();
    notifyListeners();
  }

  Future<void> createHousehold(String name) async {
    if (_currentUser == null) return;
    await HouseholdService.createHousehold(name, _currentUser!.id);
    await loadHouseholdsAndRequests();
  }

  Future<void> requestJoinHousehold({
    required String householdName,
    String? message,
  }) async {
    if (_currentUser == null) return;
    final household = await HouseholdService.getHouseholdByName(householdName);
    if (household == null) {
      throw Exception('Household not found');
    }
    await HouseholdService.createRequest(
      requesterUserId: _currentUser!.id,
      requesterName: _currentUser!.name,
      householdId: household.id,
      householdName: household.name,
      message: message,
    );
    await loadHouseholdsAndRequests();
  }

  Future<void> approveJoinRequest(String requestId) async {
    if (_currentUser == null || !_currentUser!.isParent) return;
    await HouseholdService.approveRequest(requestId, _currentUser!.id);
    await loadHouseholdsAndRequests();
  }

  Future<void> rejectJoinRequest(String requestId) async {
    if (_currentUser == null || !_currentUser!.isParent) return;
    await HouseholdService.rejectRequest(requestId);
    await loadHouseholdsAndRequests();
  }

  // ---- Initialization ----
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await storage.migrateIfNeeded();
    final data = await storage.loadAll();

    if (data.isNotEmpty) {
      _transactions = (data['transactions'] as List?)
              ?.map((j) => Transaction.fromJson(j))
              .toList() ??
          [];
      _animals =
          (data['animals'] as List?)?.map((j) => Animal.fromJson(j)).toList() ??
              [];
      _bills =
          (data['bills'] as List?)?.map((j) => Bill.fromJson(j)).toList() ?? [];
      _tasks =
          (data['tasks'] as List?)?.map((j) => Task.fromJson(j)).toList() ?? [];
      _timelineEvents = (data['timelineEvents'] as List?)
              ?.map((j) => TimelineEvent.fromJson(j))
              .toList() ??
          [];
      _feedDeliveries = (data['feedDeliveries'] as List?)
              ?.map((j) => FeedDelivery.fromJson(j))
              .toList() ??
          [];
      _loans =
          (data['loans'] as List?)?.map((j) => Loan.fromJson(j)).toList() ?? [];
      _budgets =
          (data['budgets'] as List?)?.map((j) => Budget.fromJson(j)).toList() ??
              [];
      _households = (data['households'] as List?)
              ?.map((j) => Household.fromJson(j))
              .toList() ??
          [];
      _guardianRelationships = (data['guardianRelationships'] as List?)
              ?.map((j) => GuardianRelationship.fromJson(j))
              .toList() ??
          [];
      _joinRequests = (data['joinRequests'] as List?)
              ?.map((j) => JoinRequest.fromJson(j))
              .toList() ??
          [];
      _learningMode = LearningMode.values[data['learningMode'] ?? 0];
      _schoolAgeGroup = SchoolAgeGroup.values[data['schoolAgeGroup'] ?? 1];
      _allowFinalAnswers = data['allowFinalAnswers'] ?? false;
    } else {
      _seedData();
    }

    _refreshPinStatus();
    _isLoading = false;
    notifyListeners();
  }

  void _seedData() {
    _transactions = [];
    _animals = [];
    _bills = [];
    _tasks = [];
    _loans = [];
    _feedDeliveries = [];
    _budgets = [];
    _households = [];
    _guardianRelationships = [];
    _joinRequests = [];
    _timelineEvents = [];
    _learningMode = LearningMode.standard;
    _schoolAgeGroup = SchoolAgeGroup.older;
    _allowFinalAnswers = false;
    _saveData();
  }

  void _migrateLegacyData() {
    // No-op – kept for compatibility
  }

  Future<void> _saveData() async {
    await storage.saveAll(
      transactions: _transactions,
      animals: _animals,
      bills: _bills,
      tasks: _tasks,
      timelineEvents: _timelineEvents,
      feedDeliveries: _feedDeliveries,
      loans: _loans,
      budgets: _budgets,
      learningMode: _learningMode.index,
      schoolAgeGroup: _schoolAgeGroup.index,
      allowFinalAnswers: _allowFinalAnswers,
    );
  }

  // ---- Transaction CRUD ----
  void addTransaction(Transaction tx) {
    _transactions.add(tx);
    _saveData();
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    _saveData();
    notifyListeners();
  }

  void updateTransaction(Transaction updated) {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _transactions[index] = updated;
      _saveData();
      notifyListeners();
    }
  }

  // ---- Animal CRUD ----
  void addAnimal(Animal animal) {
    _animals.add(animal);
    _saveData();
    notifyListeners();
  }

  void deleteAnimal(String id) {
    _animals.removeWhere((a) => a.id == id);
    _saveData();
    notifyListeners();
  }

  void updateAnimal(Animal updated) {
    final index = _animals.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _animals[index] = updated;
      _saveData();
      notifyListeners();
    }
  }

  // ---- Bill CRUD ----
  void addBill(Bill bill) {
    _bills.add(bill);
    _saveData();
    notifyListeners();
  }

  void deleteBill(String id) {
    _bills.removeWhere((b) => b.id == id);
    _saveData();
    notifyListeners();
  }

  void updateBill(Bill updated) {
    final index = _bills.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      _bills[index] = updated;
      _saveData();
      notifyListeners();
    }
  }

  void toggleBillPaid(String id) {
    final index = _bills.indexWhere((b) => b.id == id);
    if (index != -1) {
      final old = _bills[index];
      _bills[index] = Bill(
        id: old.id,
        name: old.name,
        amount: old.amount,
        dueDate: old.dueDate,
        isPaid: !old.isPaid,
        category: old.category,
        userId: old.userId,
      );
      _saveData();
      notifyListeners();
    }
  }

  // ---- Task CRUD ----
  void addTask(Task task) {
    _tasks.add(task);
    _saveData();
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _saveData();
    notifyListeners();
  }

  void updateTask(Task updated) {
    final index = _tasks.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _tasks[index] = updated;
      _saveData();
      notifyListeners();
    }
  }

  void toggleTaskCompletion(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final old = _tasks[index];
      _tasks[index] = Task(
        id: old.id,
        title: old.title,
        isCompleted: !old.isCompleted,
        priority: old.priority,
        isDone: !old.isDone,
      );
      _saveData();
      notifyListeners();
    }
  }

  // ---- Feed Delivery CRUD ----
  void addFeedDelivery(FeedDelivery delivery) {
    _feedDeliveries.add(delivery);
    _saveData();
    notifyListeners();
  }

  void deleteFeedDelivery(String id) {
    _feedDeliveries.removeWhere((f) => f.id == id);
    _saveData();
    notifyListeners();
  }

  void updateFeedDelivery(FeedDelivery updated) {
    final index = _feedDeliveries.indexWhere((f) => f.id == updated.id);
    if (index != -1) {
      _feedDeliveries[index] = updated;
      _saveData();
      notifyListeners();
    }
  }

  // ---- Loan CRUD ----
  void addLoan(Loan loan) {
    _loans.add(loan);
    _saveData();
    notifyListeners();
  }

  void deleteLoan(String id) {
    _loans.removeWhere((l) => l.id == id);
    _saveData();
    notifyListeners();
  }

  void updateLoan(Loan updated) {
    final index = _loans.indexWhere((l) => l.id == updated.id);
    if (index != -1) {
      _loans[index] = updated;
      _saveData();
      notifyListeners();
    }
  }

  // ---- Budget CRUD ----
  double getCategorySpent(String category) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return _transactions
        .where((t) =>
            t.category == category &&
            t.userId == _currentUser?.id &&
            t.date.isAfter(startOfMonth) &&
            t.date.isBefore(endOfMonth) &&
            t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  void addBudget(Budget budget) {
    _budgets.add(budget);
    _saveData();
    notifyListeners();
  }

  void updateBudget(Budget updated) {
    final index = _budgets.indexWhere(
        (b) => b.category == updated.category && b.userId == updated.userId);
    if (index != -1) {
      _budgets[index] = updated;
      _saveData();
      notifyListeners();
    }
  }

  void deleteBudget(String category) {
    _budgets.removeWhere(
        (b) => b.category == category && b.userId == _currentUser?.id);
    _saveData();
    notifyListeners();
  }

  // ---- Timeline ----
  void addTimelineEvent(TimelineEvent event) {
    _timelineEvents.insert(0, event);
    if (_timelineEvents.length > 100) {
      _timelineEvents = _timelineEvents.take(100).toList();
    }
    _saveData();
    notifyListeners();
  }

  void clearTimelineEvents() {
    _timelineEvents.clear();
    _saveData();
    notifyListeners();
  }

  // ---- PIN Management ----
  Future<void> enablePin(String pin) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }
    await AuthService.setPin(_currentUser!.id, pin);
    final updatedUser = await AuthService.getCurrentUser();
    if (updatedUser != null) {
      _currentUser = updatedUser;
    }
    _pinVerifiedForUserId = false;
    _verifiedUserId = null;
    _sessionStartTime = null;
    _refreshPinStatus();
    _saveData();
    notifyListeners();
  }

  Future<void> disablePin() async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }
    await AuthService.removePin(_currentUser!.id);
    final updatedUser = await AuthService.getCurrentUser();
    if (updatedUser != null) {
      _currentUser = updatedUser;
    }
    _pinVerifiedForUserId = false;
    _verifiedUserId = null;
    _sessionStartTime = null;
    _refreshPinStatus();
    _saveData();
    notifyListeners();
  }

  // ---- Reset ----
  Future<void> resetAllData() async {
    await storage.clearAll();
    await AuthService.clearAll();
    _seedData();
    _refreshPinStatus();
    notifyListeners();
  }

  // ---- Restore from Backup ----
  Future<void> restoreFromBackup(Map<String, dynamic> data) async {
    _saveData();
    notifyListeners();
  }

  // ---- Refresh ----
  void refresh() {
    notifyListeners();
  }

  // ---- Additional methods ----
  Future<List<UserAccount>> getHouseholdMembers(String householdId) async {
    final accounts = await AuthService.loadAccounts();
    return accounts.where((a) => a.householdId == householdId).toList();
  }

  Future<void> promoteToParent(String userId) async {
    final user = await AuthService.getUserById(userId);
    if (user != null) {
      final updated = UserAccount(
        id: user.id,
        householdId: user.householdId,
        name: user.name,
        type: AccountType.parent,
        role: UserRole.administrator,
        hasPin: user.hasPin,
        useBiometrics: user.useBiometrics,
        autoLogin: user.autoLogin,
        permissions: user.permissions,
      );
      await AuthService.updateUser(updated);
      notifyListeners();
    }
  }
}
