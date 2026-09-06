class FeedDelivery {
  String id;
  String householdId;
  String type;
  double weight;
  String unit;
  double? quantity;
  String? quantityUnit;
  DateTime date;
  String notes;
  // Preserve extra data from ticket parsing without breaking schema
  double? cost;
  String? vendor;

  FeedDelivery(
      {String? id,
      required this.householdId,
      required this.type,
      required this.weight,
      this.unit = 'lb',
      this.quantity,
      this.quantityUnit = 'bags',
      DateTime? date,
      this.notes = '',
      this.cost,
      this.vendor})
      : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date = date ?? DateTime.now();

  // NEW FACTORY REQUIRED BY feed_parser.dart:64 - preserves original fields
  factory FeedDelivery.fromTicket({
    required String vendor,
    required double fullWeight,
    required double fullCost,
    required DateTime date,
    required double splitPercent,
    required String userId,
    required String materialType,
  }) {
    final splitWeight = fullWeight * splitPercent;
    final splitCost = fullCost * splitPercent;
    return FeedDelivery(
      householdId: userId,
      type: materialType,
      weight: splitWeight,
      unit: 'lb',
      quantity: null,
      quantityUnit: 'bags',
      date: date,
      notes:
          '$vendor - Original: ${fullWeight}lb \$$fullCost split ${(splitPercent * 100).toStringAsFixed(0)}%',
      cost: splitCost,
      vendor: vendor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'householdId': householdId,
        'type': type,
        'weight': weight,
        'unit': unit,
        'quantity': quantity,
        'quantityUnit': quantityUnit,
        'date': date.toIso8601String(),
        'notes': notes,
        'cost': cost,
        'vendor': vendor,
      };

  factory FeedDelivery.fromJson(Map<String, dynamic> j) => FeedDelivery(
        id: j['id'],
        householdId: j['householdId'] ?? j['userId'] ?? '',
        type: j['type'] ?? 'Feed',
        weight: (j['weight'] ?? 0).toDouble(),
        unit: j['unit'] ?? 'lb',
        quantity:
            j['quantity'] != null ? (j['quantity'] as num).toDouble() : null,
        quantityUnit: j['quantityUnit'] ?? 'bags',
        date: DateTime.parse(j['date']),
        notes: j['notes'] ?? '',
        cost: j['cost'] != null ? (j['cost'] as num).toDouble() : null,
        vendor: j['vendor'],
      );
}
