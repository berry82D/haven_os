class FeedDelivery {
  final String id;
  final DateTime date;
  final String vendor;
  final double fullWeight; // Total weight from ticket (lbs)
  final double fullCost; // Total cost from ticket ($)
  final double splitPercent; // Your share (0.5 = 50%)
  final String materialType; // "Field Corn", "Feed Mix", etc.
  final String? notes;
  final String userId;
  final String assignedTo; // "Pigs", "Pen A", "Chickens", etc.
  final DateTime createdAt;

  FeedDelivery({
    required this.id,
    required this.date,
    required this.vendor,
    required this.fullWeight,
    required this.fullCost,
    this.splitPercent = 0.5,
    this.materialType = 'Field Corn',
    this.notes,
    required this.userId,
    this.assignedTo = 'Pigs',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get yourWeight => fullWeight * splitPercent;
  double get yourCost => fullCost * splitPercent;
  double get costPerLb => fullWeight > 0 ? fullCost / fullWeight : 0.0;
  double get yourCostPerLb => yourWeight > 0 ? yourCost / yourWeight : 0.0;
  String get formattedDate => '${date.month}/${date.day}/${date.year}';
  String get vendorDisplay => vendor.isNotEmpty ? vendor : 'Unknown Vendor';

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'vendor': vendor,
        'fullWeight': fullWeight,
        'fullCost': fullCost,
        'splitPercent': splitPercent,
        'materialType': materialType,
        'notes': notes,
        'userId': userId,
        'assignedTo': assignedTo,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FeedDelivery.fromJson(Map<String, dynamic> json) {
    return FeedDelivery(
      id: json['id'],
      date: DateTime.parse(json['date']),
      vendor: json['vendor'] ?? '',
      fullWeight: (json['fullWeight'] as num).toDouble(),
      fullCost: (json['fullCost'] as num).toDouble(),
      splitPercent: (json['splitPercent'] as num?)?.toDouble() ?? 0.5,
      materialType: json['materialType'] ?? 'Field Corn',
      notes: json['notes'],
      userId: json['userId'] ?? '',
      assignedTo: json['assignedTo'] ?? 'Pigs',
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  factory FeedDelivery.fromTicket({
    required String vendor,
    required double fullWeight,
    required double fullCost,
    DateTime? date,
    double splitPercent = 0.5,
    String userId = '',
    String assignedTo = 'Pigs',
    String materialType = 'Field Corn',
  }) {
    return FeedDelivery(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: date ?? DateTime.now(),
      vendor: vendor,
      fullWeight: fullWeight,
      fullCost: fullCost,
      splitPercent: splitPercent,
      userId: userId,
      assignedTo: assignedTo,
      materialType: materialType,
    );
  }
}
