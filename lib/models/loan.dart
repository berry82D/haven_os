enum LoanType {
  car,
  personal,
  mortgage,
  student,
  creditCard,
  other,
}

class Loan {
  final String id;
  final String name;
  final String lender;
  final double principal;
  final double interestRate;
  final double monthlyPayment;
  final int termMonths;
  final DateTime startDate;
  final LoanType type;
  final double? remainingBalance;
  final String userId;

  Loan({
    required this.id,
    required this.name,
    required this.lender,
    required this.principal,
    required this.interestRate,
    required this.monthlyPayment,
    required this.termMonths,
    required this.startDate,
    this.type = LoanType.other,
    this.remainingBalance,
    required this.userId,
  });

  double get totalPaid => monthlyPayment * termMonths;
  double get totalInterest => totalPaid - principal;
  double get currentBalance => remainingBalance ?? principal;
  double get progressPercent =>
      principal == 0 ? 0 : ((principal - currentBalance) / principal) * 100;
  DateTime get payoffDate => startDate.add(Duration(days: termMonths * 30));
  String get interestRateDisplay => '${interestRate.toStringAsFixed(2)}%';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lender': lender,
        'principal': principal,
        'interestRate': interestRate,
        'monthlyPayment': monthlyPayment,
        'termMonths': termMonths,
        'startDate': startDate.toIso8601String(),
        'type': type.index,
        'remainingBalance': remainingBalance,
        'userId': userId,
      };

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      name: json['name'],
      lender: json['lender'],
      principal: (json['principal'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      monthlyPayment: (json['monthlyPayment'] as num).toDouble(),
      termMonths: json['termMonths'],
      startDate: DateTime.parse(json['startDate']),
      type: LoanType.values[json['type'] ?? 0],
      remainingBalance: json['remainingBalance'] != null
          ? (json['remainingBalance'] as num).toDouble()
          : null,
      userId: json['userId'] ?? '',
    );
  }
}
