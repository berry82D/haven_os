class Budget {
  final String category;
  final double limit;
  final String month; // format: "2026-06"
  final String userId;

  Budget({
    required this.category,
    required this.limit,
    required this.month,
    this.userId = '',
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'limit': limit,
        'month': month,
        'userId': userId,
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        category: json['category'] ?? '',
        limit: (json['limit'] ?? 0.0).toDouble(),
        month: json['month'] ?? '',
        userId: json['userId'] ?? '',
      );

  Budget copyWith(
      {String? category, double? limit, String? month, String? userId}) {
    return Budget(
      category: category ?? this.category,
      limit: limit ?? this.limit,
      month: month ?? this.month,
      userId: userId ?? this.userId,
    );
  }
}
