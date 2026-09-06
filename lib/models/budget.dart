class Budget {
  final String category;
  final double limit;
  final String month;
  final String userId;
  final String householdId;

  Budget({
    required this.category,
    required this.limit,
    required this.month,
    this.userId = '',
    String? householdId,
  }) : householdId = (householdId != null && householdId.isNotEmpty)
            ? householdId
            : userId;

  Map<String, dynamic> toJson() => {
        'category': category,
        'limit': limit,
        'month': month,
        'userId': userId,
        'householdId': householdId,
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        category: json['category'] ?? '',
        limit: (json['limit'] ?? 0.0).toDouble(),
        month: json['month'] ?? '',
        userId: json['userId'] ?? '',
        householdId: json['householdId'] ?? json['userId'] ?? '',
      );

  Budget copyWith(
      {String? category,
      double? limit,
      String? month,
      String? userId,
      String? householdId}) {
    return Budget(
      category: category ?? this.category,
      limit: limit ?? this.limit,
      month: month ?? this.month,
      userId: userId ?? this.userId,
      householdId: householdId ?? this.householdId,
    );
  }
}
