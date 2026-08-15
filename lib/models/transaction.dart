enum Account { cash, bank, farm }

enum ClearedStatus { cleared, pending, reconciled }

class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final Account account;
  final ClearedStatus cleared;
  final String userId;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.account,
    this.cleared = ClearedStatus.pending,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category,
        'account': account.index,
        'cleared': cleared.index,
        'userId': userId,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      category: json['category'],
      account: Account.values[json['account']],
      cleared: ClearedStatus.values[json['cleared'] ?? 0],
      userId: json['userId'] ?? '',
    );
  }
}
