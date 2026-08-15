class Bill {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final String? category;
  final String userId; // NEW

  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.category,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'isPaid': isPaid,
        'category': category,
        'userId': userId,
      };

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate']),
      isPaid: json['isPaid'] ?? false,
      category: json['category'],
      userId: json['userId'] ?? '',
    );
  }
}
