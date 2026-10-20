/// A debt being paid down toward the Zero-Debt goal.
/// Separate from Loan (amortizing loans with a term). Amounts are never negative.
/// balance == null means "balance unknown".
class Debt {
  static const Object _nullSentinel = Object();

  final String id;
  final String creditor;
  final double? originalBalance;
  final double? balance;
  final double monthlyPayment;
  final double apr;
  final double? settlementOffer;
  final DateTime? dueDate;
  final String status;
  final String notes;
  final String householdId;
  final DateTime createdAt;
  final DateTime? lastVerified;

  Debt({
    String? id,
    required this.creditor,
    double? balance,
    double? originalBalance,
    this.monthlyPayment = 0.0,
    this.apr = 0.0,
    this.settlementOffer,
    this.dueDate,
    this.status = 'active',
    this.notes = '',
    this.householdId = '',
    DateTime? createdAt,
    this.lastVerified,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        balance = (balance == null) ? null : (balance < 0 ? 0.0 : balance),
        originalBalance = (originalBalance == null)
            ? null
            : (originalBalance < 0 ? 0.0 : originalBalance),
        createdAt = createdAt ?? DateTime.now();

  bool get isPaidOff => balance != null && balance! <= 0;

  double get progress {
    if (balance == null || originalBalance == null || originalBalance! <= 0) {
      return 0.0;
    }
    return ((originalBalance! - balance!) / originalBalance!)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  Debt copyWith({
    String? creditor,
    Object? balance = _nullSentinel,
    Object? originalBalance = _nullSentinel,
    double? monthlyPayment,
    double? apr,
    Object? settlementOffer = _nullSentinel,
    Object? dueDate = _nullSentinel,
    String? status,
    String? notes,
    Object? lastVerified = _nullSentinel,
  }) =>
      Debt(
        id: id,
        creditor: creditor ?? this.creditor,
        balance: identical(balance, _nullSentinel)
            ? this.balance
            : (balance as num?)?.toDouble(),
        originalBalance: identical(originalBalance, _nullSentinel)
            ? this.originalBalance
            : (originalBalance as num?)?.toDouble(),
        monthlyPayment: monthlyPayment ?? this.monthlyPayment,
        apr: apr ?? this.apr,
        settlementOffer: identical(settlementOffer, _nullSentinel)
            ? this.settlementOffer
            : (settlementOffer as num?)?.toDouble(),
        dueDate: identical(dueDate, _nullSentinel)
            ? this.dueDate
            : dueDate as DateTime?,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        householdId: householdId,
        createdAt: createdAt,
        lastVerified: identical(lastVerified, _nullSentinel)
            ? this.lastVerified
            : lastVerified as DateTime?,
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
        'lastVerified': lastVerified?.toIso8601String(),
      };

  static double _d(dynamic v) =>
      v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

  /// Nullable numeric helper: null for missing/unparseable; used only for
  /// balance, originalBalance and settlementOffer.
  static double? _dn(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  static DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory Debt.fromJson(Map<String, dynamic> j) => Debt(
        id: j['id']?.toString(),
        creditor: (j['creditor'] ?? '').toString(),
        balance: _dn(j['balance']),
        originalBalance: _dn(j['originalBalance']),
        monthlyPayment: _d(j['monthlyPayment']),
        apr: _d(j['apr']),
        settlementOffer: _dn(j['settlementOffer']),
        dueDate: _dt(j['dueDate']),
        status: (j['status'] ?? 'active').toString(),
        notes: (j['notes'] ?? '').toString(),
        householdId: (j['householdId'] ?? '').toString(),
        createdAt: _dt(j['createdAt']),
        lastVerified: _dt(j['lastVerified']),
      );
}