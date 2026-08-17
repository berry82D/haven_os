enum TransactionType { income, expense }

class Account {
  final String id;
  final String name;
  Account({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Account.fromJson(Map<String, dynamic> json) =>
      Account(id: json['id'], name: json['name']);
}

enum ClearedStatus { uncleared, cleared, reconciled }

class Transaction {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final TransactionType type;
  final String description; // added
  final String userId; // added
  final Account account; // added
  final ClearedStatus cleared; // added

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    required this.type,
    this.description = '',
    this.userId = '',
    Account? account,
    ClearedStatus? cleared,
  })  : account = account ?? Account(id: 'default', name: 'Default'),
        cleared = cleared ?? ClearedStatus.uncleared;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
        'type': type.name,
        'description': description,
        'userId': userId,
        'account': account.toJson(),
        'cleared': cleared.name,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      note: json['note'],
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      description: json['description'] ?? '',
      userId: json['userId'] ?? '',
      account: Account.fromJson(json['account']),
      cleared:
          ClearedStatus.values.firstWhere((e) => e.name == json['cleared']),
    );
  }
}
