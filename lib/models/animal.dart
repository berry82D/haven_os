class Animal {
  final String id;
  final String name;
  final String type;
  final int count;
  final String healthStatus;
  final int health; // added
  final double feedCost; // added
  final double revenue; // added
  final String userId; // added

  Animal({
    required this.id,
    required this.name,
    required this.type,
    required this.count,
    required this.healthStatus,
    this.health = 100,
    this.feedCost = 0.0,
    this.revenue = 0.0,
    this.userId = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'count': count,
        'healthStatus': healthStatus,
        'health': health,
        'feedCost': feedCost,
        'revenue': revenue,
        'userId': userId,
      };

  factory Animal.fromJson(Map<String, dynamic> json) => Animal(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        count: json['count'],
        healthStatus: json['healthStatus'],
        health: json['health'] ?? 100,
        feedCost: json['feedCost']?.toDouble() ?? 0.0,
        revenue: json['revenue']?.toDouble() ?? 0.0,
        userId: json['userId'] ?? '',
      );
}
