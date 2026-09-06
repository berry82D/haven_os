class Bill {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  bool isPaid;
  final String userId;
  final String householdId;
  final String category;

  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    this.userId = '',
    String? householdId,
    this.category = 'Utilities',
  }) : householdId = (householdId != null && householdId.isNotEmpty)
            ? householdId
            : userId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'isPaid': isPaid,
        'userId': userId,
        'householdId': householdId,
        'category': category,
      };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'],
        name: json['name'],
        amount: (json['amount'] as num).toDouble(),
        dueDate: DateTime.parse(json['dueDate']),
        isPaid: json['isPaid'],
        userId: json['userId'] ?? '',
        householdId: json['householdId'] ?? json['userId'] ?? '',
        category: json['category'] ?? 'Utilities',
      );
}
