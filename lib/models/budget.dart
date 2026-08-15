class Budget {
  final String category;
  final double monthlyLimit;
  final String userId;
  final String? householdId;

  Budget({
    required this.category,
    required this.monthlyLimit,
    required this.userId,
    this.householdId,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'monthlyLimit': monthlyLimit,
        'userId': userId,
        'householdId': householdId,
      };

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      category: json['category'],
      monthlyLimit: json['monthlyLimit'],
      userId: json['userId'],
      householdId: json['householdId'],
    );
  }
}
