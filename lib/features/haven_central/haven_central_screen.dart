// lib/features/haven_central/haven_central_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../../models/transaction.dart';
import '../auth/presentation/sign_in_screen.dart';
import '../kitchen/kitchen_screen.dart';

// ============================================================
// LOAN MODEL
// ============================================================
class Loan {
  final String name;
  final double amount;
  final double interestRate;
  final int termMonths;
  final double monthlyPayment;
  Loan({
    required this.name,
    required this.amount,
    required this.interestRate,
    required this.termMonths,
    required this.monthlyPayment,
  });
  double get monthlyRate => interestRate / 100 / 12;

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'interestRate': interestRate,
        'termMonths': termMonths,
        'monthlyPayment': monthlyPayment,
      };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        name: json['name'],
        amount: json['amount'],
        interestRate: json['interestRate'],
        termMonths: json['termMonths'],
        monthlyPayment: json['monthlyPayment'],
      );
}

// ============================================================
// HAVEN TAB CONTENT (Loan Simulator with Edit/Delete Buttons)
// ============================================================
class HavenTabContent extends StatefulWidget {
  final List<Loan> loans;
  final Function(Loan) onAddLoan;
  final Function(int) onDeleteLoan;
  final Function(int, Loan) onEditLoan;

  const HavenTabContent({
    super.key,
    required this.loans,
    required this.onAddLoan,
    required this.onDeleteLoan,
    required this.onEditLoan,
  });

  @override
  State<HavenTabContent> createState() => _HavenTabContentState();
}

class _HavenTabContentState extends State<HavenTabContent> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _termCtrl = TextEditingController();
  final _paymentCtrl = TextEditingController();
  String _calculationResult = 'Enter loan details and tap "Calculate Impact"';
  int? _editingIndex;

  Map<String, dynamic> _runAmortization({
    required double principal,
    required double monthlyRate,
    required double monthlyPayment,
    required double extraPayment,
    required int missedPayments,
    required int maxMonths,
  }) {
    double balance = principal;
    double totalInterest = 0;
    int monthsPaid = 0;
    double totalPaid = 0;
    for (int i = 0; i < missedPayments; i++) {
      double interest = balance * monthlyRate;
      totalInterest += interest;
      balance += interest;
    }
    double effectivePayment = monthlyPayment + extraPayment;
    while (balance > 0.01 && monthsPaid < 600) {
      double interest = balance * monthlyRate;
      totalInterest += interest;
      double principalPaid = effectivePayment - interest;
      if (principalPaid <= 0) {
        monthsPaid = 999;
        break;
      }
      balance -= principalPaid;
      totalPaid += effectivePayment;
      monthsPaid++;
      if (monthsPaid > maxMonths * 2) break;
    }
    if (balance < 0) {
      totalPaid += balance;
      balance = 0;
    }
    return {
      'totalInterest': totalInterest,
      'totalPaid': totalPaid,
      'monthsPaid': monthsPaid,
      'finalBalance': balance,
    };
  }

  void _calculateImpact() {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    final rate = double.tryParse(_rateCtrl.text);
    final term = int.tryParse(_termCtrl.text);
    final payment = double.tryParse(_paymentCtrl.text);
    if (name.isEmpty ||
        amount == null ||
        rate == null ||
        term == null ||
        payment == null) {
      setState(() => _calculationResult =
          '⚠️ Please fill in all fields with valid numbers.');
      return;
    }
    if (payment <= 0 || amount <= 0 || rate <= 0 || term <= 0) {
      setState(() =>
          _calculationResult = '⚠️ All values must be greater than zero.');
      return;
    }
    final loan = Loan(
      name: name,
      amount: amount,
      interestRate: rate,
      termMonths: term,
      monthlyPayment: payment,
    );
    final baseline = _runAmortization(
      principal: amount,
      monthlyRate: loan.monthlyRate,
      monthlyPayment: payment,
      extraPayment: 0,
      missedPayments: 0,
      maxMonths: term,
    );
    final extra50 = _runAmortization(
      principal: amount,
      monthlyRate: loan.monthlyRate,
      monthlyPayment: payment,
      extraPayment: 50,
      missedPayments: 0,
      maxMonths: term,
    );
    final extra100 = _runAmortization(
      principal: amount,
      monthlyRate: loan.monthlyRate,
      monthlyPayment: payment,
      extraPayment: 100,
      missedPayments: 0,
      maxMonths: term,
    );
    final missed3 = _runAmortization(
      principal: amount,
      monthlyRate: loan.monthlyRate,
      monthlyPayment: payment,
      extraPayment: 0,
      missedPayments: 3,
      maxMonths: term,
    );
    String result = '';
    result += '📊 LOAN: $name\n';
    result += '💰 Total Paid: \$${baseline['totalPaid'].toStringAsFixed(2)}\n';
    result +=
        '🔥 Interest Burned: \$${baseline['totalInterest'].toStringAsFixed(2)}\n';
    result += '📅 Payoff Time: ${baseline['monthsPaid']} months\n\n';
    double avgDailyInterest =
        (baseline['totalInterest'] / (baseline['monthsPaid'] * 30.44))
            .toDouble();
    result += '⏰ DAILY DRAIN: ~\$${avgDailyInterest.toStringAsFixed(2)}/day\n';
    result +=
        '   (That\'s your lunch & coffee gone before you start the car!)\n\n';
    result += '--- 💰 PAY EXTRA, SAVE BIG ---\n';
    double save50 =
        (baseline['totalInterest'] - extra50['totalInterest']).toDouble();
    int monthsSave50 = baseline['monthsPaid'] - extra50['monthsPaid'];
    result +=
        'Add \$50/mo → Saves \$${save50.toStringAsFixed(0)} interest, payoff ${monthsSave50} months earlier.\n';
    double save100 =
        (baseline['totalInterest'] - extra100['totalInterest']).toDouble();
    int monthsSave100 = baseline['monthsPaid'] - extra100['monthsPaid'];
    result +=
        'Add \$100/mo → Saves \$${save100.toStringAsFixed(0)} interest, payoff ${monthsSave100} months earlier.\n\n';
    result += '--- ⚠️ MISS PAYMENTS, PAY THE PRICE ---\n';
    double penaltyCost =
        (missed3['totalPaid'] - baseline['totalPaid']).toDouble();
    result +=
        'Miss 3 payments → Costs you an extra \$${penaltyCost.toStringAsFixed(0)}.\n';
    result += 'New total: \$${missed3['totalPaid'].toStringAsFixed(0)}.\n';
    result +=
        'Payoff pushed back ${missed3['monthsPaid'] - baseline['monthsPaid']} months.\n\n';
    double healthScore =
        (90 - ((baseline['totalInterest'] / amount) * 15)).toDouble();
    if (healthScore < 30) healthScore = 30;
    if (healthScore > 90) healthScore = 90;
    result += '🏡 HOUSEHOLD HEALTH IMPACT: ${healthScore.toInt()}%\n';
    result +=
        '   (This loan is eating your future. Pay extra to recover faster!)';
    setState(() {
      if (_editingIndex != null) {
        widget.loans[_editingIndex!] = loan;
        widget.onEditLoan(_editingIndex!, loan);
        _editingIndex = null;
      } else {
        widget.loans.add(loan);
        widget.onAddLoan(loan);
      }
      _calculationResult = result;
      _clearFields();
    });
  }

  void _clearFields() {
    _nameCtrl.clear();
    _amountCtrl.clear();
    _rateCtrl.clear();
    _termCtrl.clear();
    _paymentCtrl.clear();
  }

  void _editLoan(int index) {
    final loan = widget.loans[index];
    _nameCtrl.text = loan.name;
    _amountCtrl.text = loan.amount.toString();
    _rateCtrl.text = loan.interestRate.toString();
    _termCtrl.text = loan.termMonths.toString();
    _paymentCtrl.text = loan.monthlyPayment.toString();
    setState(() {
      _editingIndex = index;
      _calculationResult =
          '✏️ Editing "${loan.name}" – tap Calculate to save changes.';
    });
  }

  void _deleteLoan(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Loan'),
        content: Text(
            'Are you sure you want to delete "${widget.loans[index].name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        widget.loans.removeAt(index);
        widget.onDeleteLoan(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🏦 Loan Simulator',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Enter your loan details to see the real impact on your life.',
              style: TextStyle(color: Colors.grey.shade600)),
          SizedBox(height: 20),
          TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: 'Loan Name (e.g., Santander Outlander)',
                  border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Loan Amount (e.g., 18539.93)',
                  border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(
              controller: _rateCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Interest Rate % (e.g., 23.59)',
                  border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(
              controller: _termCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Term (Months, e.g., 36)',
                  border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(
              controller: _paymentCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Monthly Payment (e.g., 648.84)',
                  border: OutlineInputBorder())),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _calculateImpact,
              icon: Icon(Icons.calculate),
              label: Text(
                  _editingIndex != null ? 'Update Loan' : 'Calculate Impact',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _editingIndex != null ? Colors.orange : Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(_calculationResult,
                style: TextStyle(fontSize: 14, height: 1.5)),
          ),
          SizedBox(height: 20),
          Text('📋 Saved Loans',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          widget.loans.isEmpty
              ? Text('No loans saved yet. Calculate one above!',
                  style: TextStyle(color: Colors.grey.shade600))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.loans.length,
                  itemBuilder: (context, index) {
                    final loan = widget.loans[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(loan.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    '\$${loan.amount.toStringAsFixed(0)} at ${loan.interestRate}% for ${loan.termMonths} months',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                                '\$${loan.monthlyPayment.toStringAsFixed(0)}/mo',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(Icons.edit,
                                  color: Colors.blue.shade700, size: 20),
                              onPressed: () => _editLoan(index),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors.red.shade700, size: 20),
                              onPressed: () => _deleteLoan(index),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// ============================================================
// MAIN HOME SCREEN – with collapsible farm, edit/delete buttons
// ============================================================
class HavenCentralScreen extends StatefulWidget {
  final String username;
  const HavenCentralScreen({super.key, required this.username});

  @override
  State<HavenCentralScreen> createState() => _HavenCentralScreenState();
}

class _HavenCentralScreenState extends State<HavenCentralScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  List<Transaction> _transactions = [];
  List<Loan> _loans = [];
  String _unit = 'kg';
  Map<String, double> _farmItems = {
    'Eggs': 5.0,
    'Milk': 2.0,
    'Tomatoes': 3.5,
    'Honey': 1.2,
  };

  String get _userPrefix => 'user_${widget.username}_';

  // ============================================================
  // DATA LOAD / SAVE
  // ============================================================
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _unit = prefs.getString('${_userPrefix}unit') ?? 'kg';
    final farmJson = prefs.getString('${_userPrefix}farmItems');
    if (farmJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(farmJson);
      _farmItems = decoded.map((key, value) => MapEntry(key, value.toDouble()));
    }
    final txJson = prefs.getString('${_userPrefix}transactions');
    if (txJson != null) {
      final List<dynamic> decoded = jsonDecode(txJson);
      _transactions = decoded.map((e) => Transaction.fromJson(e)).toList();
    }
    final loansJson = prefs.getString('${_userPrefix}loans');
    if (loansJson != null) {
      final List<dynamic> decoded = jsonDecode(loansJson);
      _loans = decoded.map((e) => Loan.fromJson(e)).toList();
    }
    setState(() {});
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _transactions.map((tx) => tx.toJson()).toList();
    await prefs.setString('${_userPrefix}transactions', jsonEncode(jsonList));
  }

  Future<void> _saveLoans() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _loans.map((loan) => loan.toJson()).toList();
    await prefs.setString('${_userPrefix}loans', jsonEncode(jsonList));
  }

  Future<void> _saveFarmItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_userPrefix}farmItems', jsonEncode(_farmItems));
  }

  Future<void> _saveUnit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_userPrefix}unit', _unit);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // FARM HELPERS
  // ============================================================
  double _getDisplayValue(double kgValue) {
    if (_unit == 'lb') return kgValue * 2.20462;
    return kgValue;
  }

  String _getUnitLabel() => _unit;

  void _updateFarmItem(String name, double delta) {
    setState(() {
      if (_farmItems.containsKey(name)) {
        double newValue = _farmItems[name]! + delta;
        if (newValue <= 0) {
          _farmItems.remove(name);
        } else {
          _farmItems[name] = newValue;
        }
      }
      _saveFarmItems();
    });
  }

  void _addFarmItem(String name, double quantity) {
    setState(() {
      if (_farmItems.containsKey(name)) {
        _farmItems[name] = _farmItems[name]! + quantity;
      } else {
        _farmItems[name] = quantity;
      }
      _saveFarmItems();
    });
  }

  // ============================================================
  // TRANSACTION HELPERS (with edit/delete)
  // ============================================================
  void _addTransaction(Transaction tx) {
    setState(() {
      _transactions.add(tx);
      _saveTransactions();
    });
  }

  void _editTransaction(int index, Transaction updatedTx) {
    setState(() {
      _transactions[index] = updatedTx;
      _saveTransactions();
    });
  }

  void _deleteTransaction(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Transaction'),
        content: Text(
            'Are you sure you want to delete "${_transactions[index].description}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _transactions.removeAt(index);
        _saveTransactions();
      });
    }
  }

  void _showEditTransactionForm(int index) {
    final tx = _transactions[index];
    final _descCtrl = TextEditingController(text: tx.description);
    final _placeCtrl = TextEditingController(text: tx.note ?? '');
    final _amountCtrl = TextEditingController(text: tx.amount.toString());
    final _notesCtrl = TextEditingController(text: tx.note ?? '');
    DateTime _selectedDate = tx.date;
    bool _isIncome = tx.type == TransactionType.income;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✏️ Edit Transaction',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Center(
                  child: ToggleButtons(
                    isSelected: [_isIncome, !_isIncome],
                    onPressed: (index) =>
                        setState(() => _isIncome = (index == 0)),
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: _isIncome ? Colors.green : Colors.red,
                    color: Colors.grey.shade700,
                    children: [
                      Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text('💰 Income')),
                      Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text('💸 Expense')),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                    controller: _descCtrl,
                    decoration: InputDecoration(labelText: 'Description')),
                SizedBox(height: 12),
                TextField(
                    controller: _placeCtrl,
                    decoration:
                        InputDecoration(labelText: 'Place (e.g., Store name)')),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                        Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Amount')),
                SizedBox(height: 12),
                TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: 'Notes (optional)')),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
                        if (amount <= 0 || _descCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Please enter a description and amount')),
                          );
                          return;
                        }
                        String noteText = '';
                        if (_placeCtrl.text.isNotEmpty)
                          noteText += 'Place: ${_placeCtrl.text}\n';
                        if (_notesCtrl.text.isNotEmpty)
                          noteText += 'Notes: ${_notesCtrl.text}';
                        String? finalNote = noteText.isEmpty ? null : noteText;
                        final updatedTx = Transaction(
                          id: tx.id,
                          amount: amount,
                          category: 'General',
                          date: _selectedDate,
                          note: finalNote,
                          type: _isIncome
                              ? TransactionType.income
                              : TransactionType.expense,
                          description: _descCtrl.text,
                          userId: tx.userId,
                          account: tx.account,
                          cleared: tx.cleared,
                        );
                        _editTransaction(index, updatedTx);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Transaction updated!')),
                        );
                      },
                      child: Text('Save Changes'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addLoan(Loan loan) {
    _saveLoans();
  }

  void _editLoan(int index, Loan updatedLoan) {
    setState(() {
      _loans[index] = updatedLoan;
      _saveLoans();
    });
  }

  void _deleteLoan(int index) {
    // The list is already updated in the child, just save
    _saveLoans();
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _secureStorage.delete(key: 'auth_username');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  // ============================================================
  // ADD TRANSACTION FORM
  // ============================================================
  void _showAddTransaction(BuildContext context) {
    final _descCtrl = TextEditingController();
    final _placeCtrl = TextEditingController();
    final _amountCtrl = TextEditingController();
    final _notesCtrl = TextEditingController();
    DateTime _selectedDate = DateTime.now();
    bool _isIncome = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ToggleButtons(
                    isSelected: [_isIncome, !_isIncome],
                    onPressed: (index) =>
                        setState(() => _isIncome = (index == 0)),
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: _isIncome ? Colors.green : Colors.red,
                    color: Colors.grey.shade700,
                    children: [
                      Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text('💰 Income')),
                      Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text('💸 Expense')),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                    controller: _descCtrl,
                    decoration: InputDecoration(labelText: 'Description')),
                SizedBox(height: 12),
                TextField(
                    controller: _placeCtrl,
                    decoration:
                        InputDecoration(labelText: 'Place (e.g., Store name)')),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                        Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Amount')),
                SizedBox(height: 12),
                TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: 'Notes (optional)')),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
                        if (amount <= 0 || _descCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Please enter a description and amount')),
                          );
                          return;
                        }
                        String noteText = '';
                        if (_placeCtrl.text.isNotEmpty)
                          noteText += 'Place: ${_placeCtrl.text}\n';
                        if (_notesCtrl.text.isNotEmpty)
                          noteText += 'Notes: ${_notesCtrl.text}';
                        String? finalNote = noteText.isEmpty ? null : noteText;
                        final newTx = Transaction(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          amount: amount,
                          category: 'General',
                          date: _selectedDate,
                          note: finalNote,
                          type: _isIncome
                              ? TransactionType.income
                              : TransactionType.expense,
                          description: _descCtrl.text,
                          userId: widget.username,
                          account: Account(id: 'default', name: 'Default'),
                          cleared: ClearedStatus.uncleared,
                        );
                        _addTransaction(newTx);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '${_isIncome ? "Income" : "Expense"} added!')),
                        );
                      },
                      child: Text('Save'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TAB 0: HOME (with collapsible farm + edit/delete buttons)
  // ============================================================
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('👋 Welcome, ${widget.username}!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Text('Household Health: ',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('90%',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text('e.g. "Add \$50 to groceries"',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text('📌 Hello! Type "Help" to see what I can do.',
              style: TextStyle(color: Colors.grey.shade700)),
          SizedBox(height: 16),
          Text('Financial Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddTransaction(context),
                icon: Icon(Icons.add_circle_outline, size: 24),
                label: Text('Add Transaction',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KitchenScreen(
                        onSaveTransaction: (tx) {
                          _addTransaction(tx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    '🧠 Kitchen Brain: Transaction saved!')),
                          );
                        },
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.camera_alt, size: 24),
                label: Text('📸 Scan Receipt',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // ---------- COLLAPSIBLE FARM STATUS ----------
          ExpansionTile(
            title: Text('Farm Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            leading: Icon(Icons.agriculture, color: Colors.green.shade700),
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: _farmItems.isEmpty
                    ? Center(
                        child: Text('No farm items.',
                            style: TextStyle(color: Colors.grey.shade600)))
                    : Column(
                        children: _farmItems.entries.map((entry) {
                          double displayValue = _getDisplayValue(entry.value);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key,
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                    '${displayValue.toStringAsFixed(1)} ${_getUnitLabel()}'),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              SizedBox(height: 8),
            ],
          ),

          SizedBox(height: 16),
          Text('Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          _transactions.isEmpty
              ? Center(
                  child: Text('No transactions yet.',
                      style: TextStyle(color: Colors.grey.shade600)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount:
                      _transactions.length > 10 ? 10 : _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions.reversed.toList()[index];
                    final realIndex = _transactions.length - 1 - index;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          children: [
                            // Income/Expense indicator
                            Icon(
                              tx.type == TransactionType.income
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: tx.type == TransactionType.income
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            // Details
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tx.description,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    '\$${tx.amount.toStringAsFixed(2)} - ${tx.date.toLocal().toString().split(' ')[0]}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            // Edit & Delete buttons
                            IconButton(
                              icon: Icon(Icons.edit,
                                  color: Colors.blue.shade700, size: 20),
                              onPressed: () =>
                                  _showEditTransactionForm(realIndex),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors.red.shade700, size: 20),
                              onPressed: () => _deleteTransaction(realIndex),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 1: CFO (unchanged)
  // ============================================================
  Widget _buildCfoTab() {
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in _transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    double net = totalIncome - totalExpense;

    List<Map<String, dynamic>> monthlyData = [];
    DateTime now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      double income = 0;
      double expense = 0;
      for (var tx in _transactions) {
        if (tx.date.year == month.year && tx.date.month == month.month) {
          if (tx.type == TransactionType.income) {
            income += tx.amount;
          } else {
            expense += tx.amount;
          }
        }
      }
      monthlyData.add({
        'month': month,
        'income': income,
        'expense': expense,
      });
    }

    Map<String, double> categoryTotals = {};
    for (var tx in _transactions) {
      if (tx.type == TransactionType.expense) {
        categoryTotals[tx.category] =
            (categoryTotals[tx.category] ?? 0) + tx.amount;
      }
    }

    double avgMonthlyNet = 0;
    int count = 0;
    for (var data in monthlyData) {
      double netMonth = data['income'] - data['expense'];
      if (netMonth != 0) {
        avgMonthlyNet += netMonth;
        count++;
      }
    }
    if (count > 0) avgMonthlyNet = avgMonthlyNet / count;
    double projection3Months = avgMonthlyNet * 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💰 CFO Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Income',
                            style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold)),
                        Text('\$${totalIncome.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Expenses',
                            style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold)),
                        Text('\$${totalExpense.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Net Balance',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '\$${net.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          net >= 0 ? Colors.blue.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          if (_transactions.isNotEmpty) ...[
            Text('Income vs Expenses (Last 6 Months)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: monthlyData.fold<double>(
                              0,
                              (max, data) => max > (data['income'] as double)
                                  ? max
                                  : data['income']) *
                          1.2 +
                      1,
                  groupsSpace: 10,
                  barGroups: monthlyData.asMap().entries.map((entry) {
                    int index = entry.key;
                    var data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['income'],
                          color: Colors.green.shade400,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: data['expense'],
                          color: Colors.red.shade400,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < monthlyData.length) {
                            return Text(
                              '${monthlyData[index]['month'].month}/${monthlyData[index]['month'].year}',
                              style: TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
          if (categoryTotals.isNotEmpty) ...[
            Text('Spending by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: PieChart(
                PieChartData(
                  sections: categoryTotals.entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value,
                      title:
                          '${entry.key}\n\$${entry.value.toStringAsFixed(0)}',
                      color: Colors.primaries[
                          categoryTotals.keys.toList().indexOf(entry.key) %
                              Colors.primaries.length],
                      radius: 80,
                      titleStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
          if (projection3Months != 0) ...[
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📈 3-Month Projection',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      'Based on your current average monthly net of \$${avgMonthlyNet.toStringAsFixed(2)}, you are projected to ${projection3Months >= 0 ? 'save' : 'lose'} \$${projection3Months.abs().toStringAsFixed(2)} over the next 3 months.',
                      style: TextStyle(fontSize: 16),
                    ),
                    if (projection3Months > 0)
                      Text('Keep up the good work! 🎉',
                          style: TextStyle(color: Colors.green.shade700))
                    else
                      Text('Try reducing expenses to improve your outlook. 📉',
                          style: TextStyle(color: Colors.red.shade700)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
          Text('Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          _transactions.isEmpty
              ? Center(
                  child: Text('No transactions yet.',
                      style: TextStyle(color: Colors.grey.shade600)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount:
                      _transactions.length > 5 ? 5 : _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions.reversed.toList()[index];
                    return ListTile(
                      leading: tx.type == TransactionType.income
                          ? Icon(Icons.arrow_upward, color: Colors.green)
                          : Icon(Icons.arrow_downward, color: Colors.red),
                      title: Text(tx.description),
                      subtitle:
                          Text(tx.date.toLocal().toString().split(' ')[0]),
                      trailing: Text(
                        '\$${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tx.type == TransactionType.income
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 2: HOMESTEAD (unchanged)
  // ============================================================
  Widget _buildHomesteadTab() {
    final _newItemNameCtrl = TextEditingController();
    final _newItemQtyCtrl = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🌱 Homestead',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Manage your farm inventory.',
              style: TextStyle(color: Colors.grey.shade600)),
          SizedBox(height: 20),
          Text('Current Inventory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _farmItems.isEmpty
                ? Center(
                    child: Text('No items. Add some below!',
                        style: TextStyle(color: Colors.grey.shade600)),
                  )
                : Column(
                    children: _farmItems.entries.map((entry) {
                      double displayValue = _getDisplayValue(entry.value);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(entry.key,
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                  '${displayValue.toStringAsFixed(1)} ${_getUnitLabel()}'),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline,
                                  color: Colors.red.shade400),
                              onPressed: () => _updateFarmItem(entry.key, -0.5),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline,
                                  color: Colors.green.shade400),
                              onPressed: () => _updateFarmItem(entry.key, 0.5),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Colors.grey.shade400),
                              onPressed: () {
                                setState(() {
                                  _farmItems.remove(entry.key);
                                  _saveFarmItems();
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          SizedBox(height: 20),
          Text('Add New Item',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _newItemNameCtrl,
                  decoration: InputDecoration(
                      labelText: 'Item name', border: OutlineInputBorder()),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _newItemQtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'Qty (kg)', border: OutlineInputBorder()),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final name = _newItemNameCtrl.text.trim();
                  final qty = double.tryParse(_newItemQtyCtrl.text);
                  if (name.isEmpty || qty == null || qty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Enter a valid name and quantity')),
                    );
                    return;
                  }
                  _addFarmItem(name, qty);
                  _newItemNameCtrl.clear();
                  _newItemQtyCtrl.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Added $name (${qty.toStringAsFixed(1)} kg)')),
                  );
                },
                child: Text('Add'),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 4: SETTINGS (unchanged)
  // ============================================================
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚙️ Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Logged in as: ${widget.username}',
              style: TextStyle(color: Colors.grey.shade600)),
          SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Units',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current unit: ${_unit.toUpperCase()}'),
                      ToggleButtons(
                        isSelected: [_unit == 'kg', _unit == 'lb'],
                        onPressed: (index) {
                          setState(() {
                            _unit = index == 0 ? 'kg' : 'lb';
                            _saveUnit();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Unit changed to ${_unit.toUpperCase()}')),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: Colors.teal.shade700,
                        color: Colors.grey.shade700,
                        children: [
                          Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text('KG')),
                          Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text('LB')),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👤 Account',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'Log out of your account. Your data stays safely on this device.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: Icon(Icons.logout, color: Colors.white),
                      label:
                          Text('Logout', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              'Haven OS v1.0.0',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD – SWIPEABLE PAGEVIEW
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Haven Central'),
        backgroundColor: Colors.teal.shade700,
        actions: [
          IconButton(
            icon: Text(_unit.toUpperCase()),
            onPressed: () {
              setState(() {
                _unit = (_unit == 'kg') ? 'lb' : 'kg';
                _saveUnit();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Unit changed to $_unit')),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildHomeTab(),
          _buildCfoTab(),
          _buildHomesteadTab(),
          HavenTabContent(
            loans: _loans,
            onAddLoan: _addLoan,
            onDeleteLoan: _deleteLoan,
            onEditLoan: _editLoan,
          ),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal.shade700,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'CFO'),
          BottomNavigationBarItem(
              icon: Icon(Icons.agriculture), label: 'Homestead'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Haven'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}
