/// A debt being paid down toward the Zero-Debt goal.
/// Separate from Loan (amortizing loans with a term). Amounts are never negative.
class Debt {
  final String id;
  final String creditor;
  final double originalBalance;
  final double balance;
  final double monthlyPayment;
  final double apr;
  final double? settlementOffer;
  final DateTime? dueDate;
  final String status;
  final String notes;
  final String householdId;
  final DateTime createdAt;

  Debt({
    String? id,
    required this.creditor,
    required double balance,
    double? originalBalance,
    this.monthlyPayment = 0.0,
    this.apr = 0.0,
    this.settlementOffer,
    this.dueDate,
    this.status = 'active',
    this.notes = '',
    this.householdId = '',
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        balance = balance < 0 ? 0.0 : balance,
        originalBalance = (originalBalance ?? balance) < 0
            ? 0.0
            : (originalBalance ?? balance),
        createdAt = createdAt ?? DateTime.now();

  bool get isPaidOff => balance <= 0;

  double get progress => originalBalance <= 0
      ? 1.0
      : ((originalBalance - balance) / originalBalance)
          .clamp(0.0, 1.0)
          .toDouble();

  Debt copyWith({
    double? balance,
    double? monthlyPayment,
    double? apr,
    double? settlementOffer,
    DateTime? dueDate,
    String? status,
    String? notes,
  }) =>
      Debt(
        id: id,
        creditor: creditor,
        balance: balance ?? this.balance,
        originalBalance: originalBalance,
        monthlyPayment: monthlyPayment ?? this.monthlyPayment,
        apr: apr ?? this.apr,
        settlementOffer: settlementOffer ?? this.settlementOffer,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        householdId: householdId,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'creditor': creditor,
        'originalBalance': originalBalance,
        'balance': balance,
        'monthlyPayment': monthlyPayment,
        'apr': apr,
        'settlementOffer': settlementOffer,
        'dueDate': dueDate?.toIso8601String(),
        'status': status,
        'notes': notes,
        'householdId': householdId,
        'createdAt': createdAt.toIso8601String(),
      };

  static double _d(dynamic v) =>
      v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory Debt.fromJson(Map<String, dynamic> j) => Debt(
        id: j['id']?.toString(),
        creditor: (j['creditor'] ?? '').toString(),
        balance: _d(j['balance']),
        originalBalance: j['originalBalance'] == null ? null : _d(j['originalBalance']),
        monthlyPayment: _d(j['monthlyPayment']),
        apr: _d(j['apr']),
        settlementOffer: j['settlementOffer'] == null ? null : _d(j['settlementOffer']),
        dueDate: _dt(j['dueDate']),
        status: (j['status'] ?? 'active').toString(),
        notes: (j['notes'] ?? '').toString(),
        householdId: (j['householdId'] ?? '').toString(),
        createdAt: _dt(j['createdAt']),
      );
}