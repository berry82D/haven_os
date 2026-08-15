class BudgetTarget {
  String category;
  int target; // in cents

  BudgetTarget({required this.category, required this.target});

  Map<String, dynamic> toJson() => {'category': category, 'target': target};

  factory BudgetTarget.fromJson(Map<String, dynamic> json) =>
      BudgetTarget(category: json['category'], target: json['target']);
}
