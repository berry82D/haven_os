// lib/features/haven/widgets/haven_screen.dart
import 'package:flutter/material.dart';

// ---------- LOAN MODEL ----------
class Loan {
  final String name;
  final double amount;
  final double interestRate; // APR (e.g., 23.59)
  final int termMonths;
  final double monthlyPayment;

  Loan({
    required this.name,
    required this.amount,
    required this.interestRate,
    required this.termMonths,
    required this.monthlyPayment,
  });

  // Monthly interest rate as a decimal (e.g., 23.59% -> 0.019658)
  double get monthlyRate => interestRate / 100 / 12;
}

// ---------- HAVEN SCREEN ----------
class HavenScreen extends StatefulWidget {
  const HavenScreen({super.key});

  @override
  State<HavenScreen> createState() => _HavenScreenState();
}

class _HavenScreenState extends State<HavenScreen> {
  // List to store saved loans
  final List<Loan> _loans = [];

  // Text controllers for the form
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _termCtrl = TextEditingController();
  final _paymentCtrl = TextEditingController();

  // Where the calculation result is stored
  String _calculationResult = 'Enter loan details and tap "Calculate Impact"';

  // ---------- THE AMORTIZATION ENGINE (Bank Accurate) ----------
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

    // STEP 1: Apply missed payments FIRST (interest keeps growing)
    for (int i = 0; i < missedPayments; i++) {
      double interest = balance * monthlyRate;
      totalInterest += interest;
      balance += interest; // Unpaid interest gets added to principal
    }

    // STEP 2: Run the monthly payments
    double effectivePayment = monthlyPayment + extraPayment;

    while (balance > 0.01 && monthsPaid < 600) {
      double interest = balance * monthlyRate;
      totalInterest += interest;

      double principalPaid = effectivePayment - interest;

      // If payment is too low to cover interest, loan never pays off
      if (principalPaid <= 0) {
        monthsPaid = 999; // Infinity signal
        break;
      }

      balance -= principalPaid;
      totalPaid += effectivePayment;
      monthsPaid++;

      // Safety: don't run forever
      if (monthsPaid > maxMonths * 2) break;
    }

    // Fix: if balance is negative (overpaid), adjust total paid
    if (balance < 0) {
      totalPaid += balance; // balance is negative, so this subtracts
      balance = 0;
    }

    return {
      'totalInterest': totalInterest,
      'totalPaid': totalPaid,
      'monthsPaid': monthsPaid,
      'finalBalance': balance,
    };
  }

  // ---------- CALCULATE IMPACT (The Main Function) ----------
  void _calculateImpact() {
    // Parse inputs
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    final rate = double.tryParse(_rateCtrl.text);
    final term = int.tryParse(_termCtrl.text);
    final payment = double.tryParse(_paymentCtrl.text);

    // Validation
    if (name.isEmpty ||
        amount == null ||
        rate == null ||
        term == null ||
        payment == null) {
      setState(() {
        _calculationResult = '⚠️ Please fill in all fields with valid numbers.';
      });
      return;
    }
    if (payment <= 0 || amount <= 0 || rate <= 0 || term <= 0) {
      setState(() {
        _calculationResult = '⚠️ All values must be greater than zero.';
      });
      return;
    }

    // Create the loan object
    final loan = Loan(
      name: name,
      amount: amount,
      interestRate: rate,
      termMonths: term,
      monthlyPayment: payment,
    );

    // --- 1. BASELINE (Pay Minimum) ---
    final baseline = _runAmortization(
      principal: amount,
      monthlyRate: loan.monthlyRate,
      monthlyPayment: payment,
      extraPayment: 0,
      missedPayments: 0,
      maxMonths: term,
    );

    // --- 2. SCENARIO: Pay Extra ($50) ---
    final extra50 = _runAmortization(
      principal: amount,
      monthlyRate: loan.monthlyRate,
      monthlyPayment: payment,
      extraPayment: 50,
      missedPayments: 0,
      maxMonths: term,
    );

    // --- 3. SCENARIO: Pay Extra ($100) ---
    final extra100 = _runAmortization(
      principal: amount,
      monthlyRate: loan.monthlyRate,
      monthlyPayment: payment,
      extraPayment: 100,
      missedPayments: 0,
      maxMonths: term,
    );

    // --- 4. SCENARIO: Miss 3 Payments ---
    final missed3 = _runAmortization(
      principal: amount,
      monthlyRate: loan.monthlyRate,
      monthlyPayment: payment,
      extraPayment: 0,
      missedPayments: 3,
      maxMonths: term,
    );

    // --- 5. BUILD THE "TEACHING" OUTPUT ---
    String result = '';

    // A. The Brutal Truth
    result += '📊 LOAN: $name\n';
    result += '💰 Total Paid: \$${baseline['totalPaid'].toStringAsFixed(2)}\n';
    result +=
        '🔥 Interest Burned: \$${baseline['totalInterest'].toStringAsFixed(2)}\n';
    result += '📅 Payoff Time: ${baseline['monthsPaid']} months\n\n';

    // B. Daily Drain (FIXED: added .toDouble())
    double avgDailyInterest =
        (baseline['totalInterest'] / (baseline['monthsPaid'] * 30.44))
            .toDouble();
    result += '⏰ DAILY DRAIN: ~\$${avgDailyInterest.toStringAsFixed(2)}/day\n';
    result +=
        '   (That\'s your lunch & coffee gone before you start the car!)\n\n';

    // C. Pay Extra Scenarios (FIXED: added .toDouble())
    result += '--- 💰 PAY EXTRA, SAVE BIG ---\n';

    double save50 =
        (baseline['totalInterest'] - extra50['totalInterest']).toDouble();
    int monthsSave50 = baseline['monthsPaid'] - extra50['monthsPaid'];
    result += 'Add \$50/mo → Saves \$${save50.toStringAsFixed(0)} interest, '
        'payoff ${monthsSave50} months earlier.\n';

    double save100 =
        (baseline['totalInterest'] - extra100['totalInterest']).toDouble();
    int monthsSave100 = baseline['monthsPaid'] - extra100['monthsPaid'];
    result += 'Add \$100/mo → Saves \$${save100.toStringAsFixed(0)} interest, '
        'payoff ${monthsSave100} months earlier.\n\n';

    // D. Miss Payments Penalty (FIXED: added .toDouble())
    result += '--- ⚠️ MISS PAYMENTS, PAY THE PRICE ---\n';
    double penaltyCost =
        (missed3['totalPaid'] - baseline['totalPaid']).toDouble();
    result +=
        'Miss 3 payments → Costs you an extra \$${penaltyCost.toStringAsFixed(0)}.\n';
    result += 'New total: \$${missed3['totalPaid'].toStringAsFixed(0)}.\n';
    result +=
        'Payoff pushed back ${missed3['monthsPaid'] - baseline['monthsPaid']} months.\n\n';

    // E. Household Health Impact (FIXED: added .toDouble())
    double healthScore =
        (90 - ((baseline['totalInterest'] / amount) * 15)).toDouble();
    if (healthScore < 30) healthScore = 30;
    if (healthScore > 90) healthScore = 90;
    result += '🏡 HOUSEHOLD HEALTH IMPACT: ${healthScore.toInt()}%\n';
    result +=
        '   (This loan is eating your future. Pay extra to recover faster!)';

    // Save the loan to the list
    setState(() {
      _loans.add(loan);
      _calculationResult = result;
    });
  }

  // ---------- BUILD THE UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Haven AI'),
        backgroundColor: Colors.deepPurple.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏦 Loan Simulator',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  'Enter your loan details to see the real impact on your life.',
                  style: TextStyle(color: Colors.grey.shade600)),
              SizedBox(height: 20),

              // --- FORM FIELDS ---
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Loan Name (e.g., Santander Outlander)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),

              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Loan Amount (e.g., 18539.93)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),

              TextField(
                controller: _rateCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Interest Rate % (e.g., 23.59)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),

              TextField(
                controller: _termCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Term (Months, e.g., 36)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),

              TextField(
                controller: _paymentCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monthly Payment (e.g., 648.84)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),

              // --- CALCULATE BUTTON ---
              Center(
                child: ElevatedButton.icon(
                  onPressed: _calculateImpact,
                  icon: Icon(Icons.calculate),
                  label:
                      Text('Calculate Impact', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // --- CALCULATION RESULT BOX ---
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _calculationResult,
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              SizedBox(height: 20),

              // --- SAVED LOANS LIST ---
              Text('📋 Saved Loans',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _loans.isEmpty
                  ? Text('No loans saved yet. Calculate one above!',
                      style: TextStyle(color: Colors.grey.shade600))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _loans.length,
                      itemBuilder: (context, index) {
                        final loan = _loans[index];
                        return Card(
                          child: ListTile(
                            title: Text(loan.name),
                            subtitle: Text(
                                '\$${loan.amount.toStringAsFixed(0)} at ${loan.interestRate}% for ${loan.termMonths} months'),
                            trailing: Text(
                                '\$${loan.monthlyPayment.toStringAsFixed(0)}/mo'),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
