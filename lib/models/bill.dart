class Bill {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  bool isPaid;
  final String userId;
  final String category; // 👈 added

  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    this.userId = '',
    this.category = 'Utilities', // default
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'isPaid': isPaid,
        'userId': userId,
        'category': category,
      };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'],
        name: json['name'],
        amount: json['amount'],
        dueDate: DateTime.parse(json['dueDate']),
        isPaid: json['isPaid'],
        userId: json['userId'] ?? '',
        category: json['category'] ?? 'Utilities',
      );
}
