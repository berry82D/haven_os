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
// ✅ removed unused import: 'package:haven_os/models/guardian_relationship.dart';
import 'package:haven_os/models/join_request.dart';
import 'package:haven_os/domain/services/household_service.dart';
import 'package:haven_os/services/auth_service.dart';
import 'package:haven_os/core/enums/learning_mode.dart';

// ============================================================
// If Dart reports "AppState isn't a type" anywhere else in the
// project, the fix is always in THIS file, not the file with the
// error. Every screen that says that is just reporting that this
// class failed to parse. Confirm this file starts with the class
// declaration below and has a matching closing brace at the very
// end (no stray braces removed/added anywhere in between).
// ============================================================

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
  // ✅ removed unused field: _guardianRelationships
  List<JoinRequest> _joinRequests = [];

  // ---- Learning settings ----
  LearningMode _learningMode = LearningMode.standard;
  SchoolAgeGroup _schoolAgeGroup = SchoolAgeGroup.older;
  bool _allowFinalAnswers = false;

  // ---- Current User ----
  UserAccount? _currentUser;
  UserAccount? get currentUser => _currentUser;

  // ---- PIN cache (synchronous, for Settings switch) ----
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

  /// True only if the CURRENTLY selected user is the one who verified.
  bool get pinVerified =>
      _pinVerifiedForUserId && _verifiedUserId == _currentUser?.id;

  /// Call after sign_in_screen.dart's AuthService.verifyPin() succeeds.
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

  /// Call from main.dart's lifecycle observer on background/pause.
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
        if (elapsed > const Duration(minutes: 5)) return true;
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

  List<Task> get myTasks {
    if (_currentUser == null) return [];
    return _tasks.where((t) => t.userId == _currentUser!.id).toList();
  }

  List<TimelineEvent> get myTimelineEvents {
    if (_currentUser == null) return [];
    return _timelineEvents.where((e) => e.userId == _currentUser!.id).toList();
  }

  List<FeedDelivery> get myFeedDeliveries {
    if (_currentUser == null) return [];
    return _feedDeliveries.where((f) => f.userId == _currentUser!.id).toList();
  }

  List<Loan> get myLoans {
    if (_currentUser == null) return [];
    return _loans.where((l) => l.userId == _currentUser!.id).toList();
  }

  // ---- Unfiltered getters ----
  List<Transaction> get transactions => _transactions;
  List<Animal> get animals => _animals;
  List<Bill> get bills => _bills;
  List<Task> get tasks => _tasks;
  List<TimelineEvent> get timelineEvents => _timelineEvents;
  List<FeedDelivery> get feedDeliveries => _feedDeliveries;
  List<Loan> get loans => _loans;

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

  HealthScore get healthScore => healthScoreService.calculate(
        transactions: _transactions,
        bills: _bills,
        tasks: _tasks,
        animals: _animals,
      );

  // ---- State ----
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ---- Household & Join Requests ----
  List<Household> get households => _households;
  List<JoinRequest> get joinRequests => _joinRequests;

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

  /// All accounts in the current user's household (not just pending
  /// join requests). Used by HouseholdManagementScreen to show who
  /// can be promoted to Parent/Administrator.
  Future<List<UserAccount>> getHouseholdMembers() async {
    if (_currentUser == null) return [];
    final all = await AuthService.loadAccounts();
    return all
        .where((a) => a.householdId == _currentUser!.householdId)
        .toList();
  }

  /// Promotes another household member to Administrator. Only an
  /// existing Administrator/Parent can do this, and only for someone
  /// already in their household. This is the ONLY path to becoming
  /// Parent after the first account — deliberately not exposed on
  /// the public Create Account screen, to prevent self-escalation.
  Future<void> promoteToParent(String targetUserId) async {
    if (_currentUser == null || !_currentUser!.isParent) {
      throw Exception('Only an existing Parent can promote another account.');
    }
    final target = await AuthService.getUserById(targetUserId);
    if (target == null) throw Exception('Account not found.');
    if (target.householdId != _currentUser!.householdId) {
      throw Exception('Account is not in your household.');
    }

    final updated = UserAccount(
      id: target.id,
      householdId: target.householdId,
      name: target.name,
      type: AccountType.parent,
      role: UserRole.administrator,
      hasPin: target.hasPin,
      useBiometrics: target.useBiometrics,
      autoLogin: target.autoLogin,
      permissions: target.permissions,
    );
    await AuthService.updateUser(updated);
    notifyListeners();
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
      _learningMode = LearningMode.values[data['learningMode'] ?? 0];
      _schoolAgeGroup = SchoolAgeGroup.values[data['schoolAgeGroup'] ?? 1];
      _allowFinalAnswers = data['allowFinalAnswers'] ?? false;
    } else {
      _seedData();
    }

    await _refreshPinStatus();
    _isLoading = false;
    notifyListeners();
  }

  void _seedData() {
    final userId = _currentUser?.id ?? '';

    _transactions = [
      Transaction(
        id: '1',
        description: 'Coffee',
        amount: -4.50,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        category: 'Food',
        account: Account.cash,
        cleared: ClearedStatus.pending,
        userId: userId,
      ),
      Transaction(
        id: '2',
        description: 'Paycheck',
        amount: 1200.00,
        date: DateTime.now().subtract(const Duration(days: 1)),
        category: 'Salary',
        account: Account.bank,
        cleared: ClearedStatus.cleared,
        userId: userId,
      ),
      Transaction(
        id: '3',
        description: 'Farm Feed',
        amount: -150.00,
        date: DateTime.now().subtract(const Duration(days: 3)),
        category: 'Farm',
        account: Account.farm,
        cleared: ClearedStatus.pending,
        userId: userId,
      ),
    ];

    _animals = [
      Animal(
        id: '1',
        name: 'Pigs',
        type: '🐖',
        count: 5,
        health: 'Good',
        feedCost: 150.0,
        userId: userId,
      ),
      Animal(
        id: '2',
        name: 'Chickens',
        type: '🐓',
        count: 12,
        health: 'Good',
        feedCost: 60.0,
        userId: userId,
      ),
      Animal(
        id: '3',
        name: 'Goats',
        type: '🐐',
        count: 3,
        health: 'Fair',
        feedCost: 40.0,
        userId: userId,
      ),
    ];

    _bills = [];
    _tasks = [];
    _loans = [];
    _feedDeliveries = [];

    _timelineEvents = [
      TimelineEvent.systemEvent(
        '🏡 Welcome to Haven_OS',
        'Your household operating system is ready.',
        userId: userId,
      ),
    ];
    for (var tx in _transactions) {
      _timelineEvents.add(TimelineEvent.transactionAdded(tx));
    }

    _learningMode = LearningMode.standard;
    _schoolAgeGroup = SchoolAgeGroup.older;
    _allowFinalAnswers = false;

    _saveData();
  }

  void _migrateLegacyData() {
    final userId = _currentUser?.id ?? '';
    if (userId.isEmpty) return;

    bool changed = false;
    if (_transactions.any((t) => t.userId.isEmpty)) {
      _transactions = _transactions
          .map((t) => t.userId.isEmpty
              ? Transaction(
                  id: t.id,
                  description: t.description,
                  amount: t.amount,
                  date: t.date,
                  category: t.category,
                  account: t.account,
                  cleared: t.cleared,
                  userId: userId,
                )
              : t)
          .toList();
      changed = true;
    }
    if (_animals.any((a) => a.userId.isEmpty)) {
      _animals = _animals
          .map((a) => a.userId.isEmpty
              ? Animal(
                  id: a.id,
                  name: a.name,
                  type: a.type,
                  count: a.count,
                  health: a.health,
                  feedCost: a.feedCost,
                  revenue: a.revenue,
                  userId: userId,
                )
              : a)
          .toList();
      changed = true;
    }
    if (_bills.any((b) => b.userId.isEmpty)) {
      _bills = _bills
          .map((b) => b.userId.isEmpty
              ? Bill(
                  id: b.id,
                  name: b.name,
                  amount: b.amount,
                  dueDate: b.dueDate,
                  isPaid: b.isPaid,
                  category: b.category,
                  userId: userId,
                )
              : b)
          .toList();
      changed = true;
    }
    if (_tasks.any((t) => t.userId.isEmpty)) {
      _tasks = _tasks
          .map((t) => t.userId.isEmpty
              ? Task(
                  id: t.id,
                  title: t.title,
                  description: t.description,
                  dueDate: t.dueDate,
                  isDone: t.isDone,
                  priority: t.priority,
                  category: t.category,
                  userId: userId,
                )
              : t)
          .toList();
      changed = true;
    }
    if (_timelineEvents.any((e) => e.userId.isEmpty)) {
      _timelineEvents = _timelineEvents
          .map((e) => e.userId.isEmpty
              ? TimelineEvent(
                  id: e.id,
                  title: e.title,
                  description: e.description,
                  timestamp: e.timestamp,
                  type: e.type,
                  metadata: e.metadata,
                  userId: userId,
                )
              : e)
          .toList();
      changed = true;
    }
    if (_feedDeliveries.any((f) => f.userId.isEmpty)) {
      _feedDeliveries = _feedDeliveries
          .map((f) => f.userId.isEmpty
              ? FeedDelivery(
                  id: f.id,
                  date: f.date,
                  vendor: f.vendor,
                  fullWeight: f.fullWeight,
                  fullCost: f.fullCost,
                  splitPercent: f.splitPercent,
                  materialType: f.materialType,
                  notes: f.notes,
                  userId: userId,
                  assignedTo: f.assignedTo,
                  createdAt: f.createdAt,
                )
              : f)
          .toList();
      changed = true;
    }
    if (_loans.any((l) => l.userId.isEmpty)) {
      _loans = _loans
          .map((l) => l.userId.isEmpty
              ? Loan(
                  id: l.id,
                  name: l.name,
                  lender: l.lender,
                  principal: l.principal,
                  interestRate: l.interestRate,
                  monthlyPayment: l.monthlyPayment,
                  termMonths: l.termMonths,
                  startDate: l.startDate,
                  type: l.type,
                  remainingBalance: l.remainingBalance,
                  userId: userId,
                )
              : l)
          .toList();
      changed = true;
    }
    if (changed) _saveData();
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
      budgets: const [], // placeholder — no budget feature exists in AppState yet
      learningMode: _learningMode.index,
      schoolAgeGroup: _schoolAgeGroup.index,
      allowFinalAnswers: _allowFinalAnswers,
    );
  }

  // ---- Transaction CRUD ----
  void addTransaction(Transaction tx) {
    final newTx = Transaction(
      id: tx.id,
      description: tx.description,
      amount: tx.amount,
      date: tx.date,
      category: tx.category,
      account: tx.account,
      cleared: tx.cleared,
      userId: _currentUser?.id ?? '',
    );
    _transactions.add(newTx);
    addTimelineEvent(TimelineEvent.transactionAdded(newTx));
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
    final newAnimal = Animal(
      id: animal.id,
      name: animal.name,
      type: animal.type,
      count: animal.count,
      health: animal.health,
      feedCost: animal.feedCost,
      revenue: animal.revenue,
      userId: _currentUser?.id ?? '',
    );
    _animals.add(newAnimal);
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
      final oldHealth = _animals[index].health;
      _animals[index] = updated;
      if (oldHealth != updated.health) {
        addTimelineEvent(TimelineEvent.animalHealthUpdated(updated));
      }
      _saveData();
      notifyListeners();
    }
  }

  // ---- Bill CRUD ----
  void addBill(Bill bill) {
    final newBill = Bill(
      id: bill.id,
      name: bill.name,
      amount: bill.amount,
      dueDate: bill.dueDate,
      isPaid: bill.isPaid,
      category: bill.category,
      userId: _currentUser?.id ?? '',
    );
    _bills.add(newBill);
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
      final oldBill = _bills[index];
      _bills[index] = Bill(
        id: oldBill.id,
        name: oldBill.name,
        amount: oldBill.amount,
        dueDate: oldBill.dueDate,
        isPaid: !oldBill.isPaid,
        category: oldBill.category,
        userId: oldBill.userId,
      );
      if (_bills[index].isPaid) {
        addTimelineEvent(TimelineEvent.billPaid(_bills[index]));
      }
      _saveData();
      notifyListeners();
    }
  }

  // ---- Task CRUD ----
  void addTask(Task task) {
    final newTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      isDone: task.isDone,
      priority: task.priority,
      category: task.category,
      userId: _currentUser?.id ?? '',
    );
    _tasks.add(newTask);
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

  void toggleTaskDone(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final oldTask = _tasks[index];
      _tasks[index] = Task(
        id: oldTask.id,
        title: oldTask.title,
        description: oldTask.description,
        dueDate: oldTask.dueDate,
        isDone: !oldTask.isDone,
        priority: oldTask.priority,
        category: oldTask.category,
        userId: oldTask.userId,
      );
      if (_tasks[index].isDone) {
        addTimelineEvent(TimelineEvent.taskCompleted(_tasks[index]));
      }
      _saveData();
      notifyListeners();
    }
  }

  // ---- Feed Delivery CRUD ----
  void addFeedDelivery(FeedDelivery delivery) {
    final newDelivery = FeedDelivery(
      id: delivery.id,
      date: delivery.date,
      vendor: delivery.vendor,
      fullWeight: delivery.fullWeight,
      fullCost: delivery.fullCost,
      splitPercent: delivery.splitPercent,
      materialType: delivery.materialType,
      notes: delivery.notes,
      userId: _currentUser?.id ?? '',
      assignedTo: delivery.assignedTo,
      createdAt: delivery.createdAt,
    );
    _feedDeliveries.add(newDelivery);
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
    final newLoan = Loan(
      id: loan.id,
      name: loan.name,
      lender: loan.lender,
      principal: loan.principal,
      interestRate: loan.interestRate,
      monthlyPayment: loan.monthlyPayment,
      termMonths: loan.termMonths,
      startDate: loan.startDate,
      type: loan.type,
      remainingBalance: loan.remainingBalance,
      userId: _currentUser?.id ?? '',
    );
    _loans.add(newLoan);
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
  // Routes exclusively through AuthService, which owns both the
  // PinLock hash AND the UserAccount.hasPin flag together, so they
  // can't drift out of sync with each other.
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
    await _refreshPinStatus();
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
    await _refreshPinStatus();
    _saveData();
    notifyListeners();
  }

  // ---- Reset ----
  /// Wipes app data AND account/PIN storage. Previously this only
  /// called storage.clearAll(), which left AuthService's accounts,
  /// current-user-id, and PinLock hashes untouched — meaning Reset
  /// All Data in Settings did not actually let you test the
  /// create-account/login flow from scratch without uninstalling.
  Future<void> resetAllData() async {
    await storage.clearAll();
    await AuthService.clearAll();
    _currentUser = null;
    _pinVerifiedForUserId = false;
    _verifiedUserId = null;
    _sessionStartTime = null;
    _currentUserHasPin = false;
    _joinRequests = [];
    _households = [];
    _seedData();
    await _refreshPinStatus();
    notifyListeners();
  }

  // ---- Refresh ----
  void refresh() {
    notifyListeners();
  }
}
