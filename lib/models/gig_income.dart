import 'package:intl/intl.dart';

enum GigPlatform { doordash, uberEats, spark, instacart, lyft, uber, other }

class GigIncome {
  late String id;
  late String userId;
  late String householdId;
  late DateTime date;
  late GigPlatform platform;
  late double basePay;
  late double tips;
  late double bonus;
  late double mileage;
  late double miles;
  late double totalAmount;
  late String notes;
  late String transactionId;

  GigIncome({
    String? id,
    String? userId,
    String? householdId,
    DateTime? date,
    GigPlatform? platform,
    double? basePay,
    double? tips,
    double? bonus,
    double? mileage,
    double? miles,
    double? totalAmount,
    String? notes,
    String? transactionId,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId = userId ?? '',
        householdId =
            (householdId?.isNotEmpty == true) ? householdId! : (userId ?? ''),
        date = date ?? DateTime.now(),
        platform = platform ?? GigPlatform.doordash,
        basePay = basePay ?? 0.0,
        tips = tips ?? 0.0,
        bonus = bonus ?? 0.0,
        mileage = mileage ?? 0.0,
        miles = miles ?? 0.0,
        totalAmount = totalAmount ?? 0.0,
        notes = notes ?? '',
        transactionId = transactionId ?? '' {
    if (this.totalAmount == 0.0) {
      this.totalAmount = this.basePay + this.tips + this.bonus;
    }
  }

  double get totalPay => basePay + tips + bonus;
  double get payPerMile => miles > 0 ? totalPay / miles : 0.0;
  double get tipPercent => totalPay > 0 ? (tips / totalPay) * 100 : 0.0;

  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
  String get platformName => platform.toString().split('.').last;
  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'householdId': householdId,
        'date': date.toIso8601String(),
        'platform': platform.toString().split('.').last,
        'basePay': basePay,
        'tips': tips,
        'bonus': bonus,
        'mileage': mileage,
        'miles': miles,
        'totalAmount': totalAmount,
        'notes': notes,
        'transactionId': transactionId,
      };

  factory GigIncome.fromJson(Map<String, dynamic> j) {
    GigPlatform parsePlatform(String? s) {
      switch (s?.toLowerCase()) {
        case 'doordash':
          return GigPlatform.doordash;
        case 'ubereats':
        case 'uber_eats':
          return GigPlatform.uberEats;
        case 'spark':
          return GigPlatform.spark;
        case 'instacart':
          return GigPlatform.instacart;
        case 'lyft':
          return GigPlatform.lyft;
        case 'uber':
          return GigPlatform.uber;
        default:
          return GigPlatform.other;
      }
    }

    return GigIncome(
      id: j['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: j['userId'] ?? '',
      householdId: j['householdId'] ?? j['userId'] ?? '',
      date: DateTime.parse(j['date']),
      platform: parsePlatform(j['platform']),
      basePay: (j['basePay'] ?? 0.0).toDouble(),
      tips: (j['tips'] ?? 0.0).toDouble(),
      bonus: (j['bonus'] ?? 0.0).toDouble(),
      mileage: (j['mileage'] ?? 0.0).toDouble(),
      miles: (j['miles'] ?? 0.0).toDouble(),
      totalAmount: (j['totalAmount'] ?? 0.0).toDouble(),
      notes: j['notes'] ?? '',
      transactionId: j['transactionId'] ?? '',
    );
  }
}
