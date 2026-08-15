class Household {
  final String id;
  final String name;
  final DateTime createdAt;

  Household({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
