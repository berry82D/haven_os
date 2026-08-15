class Animal {
  final String id;
  final String name;
  final String type;
  final int count;
  final String health;
  final double feedCost;
  final double? revenue;
  final String userId; // NEW

  Animal({
    required this.id,
    required this.name,
    required this.type,
    required this.count,
    required this.health,
    required this.feedCost,
    this.revenue,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'count': count,
        'health': health,
        'feedCost': feedCost,
        'revenue': revenue,
        'userId': userId,
      };

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      count: json['count'],
      health: json['health'],
      feedCost: (json['feedCost'] as num).toDouble(),
      revenue:
          json['revenue'] != null ? (json['revenue'] as num).toDouble() : null,
      userId: json['userId'] ?? '',
    );
  }
}
