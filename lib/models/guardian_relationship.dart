enum GuardianPermission {
  viewGoals,
  viewBudgetHealth,
  viewSavingsProgress,
  viewTransactions,
}

class GuardianRelationship {
  final String id;
  final String guardianId;
  final String teenId;
  final List<GuardianPermission> permissions;
  final DateTime createdAt;

  GuardianRelationship({
    required this.id,
    required this.guardianId,
    required this.teenId,
    required this.permissions,
    required this.createdAt,
  });

  bool get canViewGoals => permissions.contains(GuardianPermission.viewGoals);
  bool get canViewBudgetHealth =>
      permissions.contains(GuardianPermission.viewBudgetHealth);
  bool get canViewSavingsProgress =>
      permissions.contains(GuardianPermission.viewSavingsProgress);
  bool get canViewTransactions =>
      permissions.contains(GuardianPermission.viewTransactions);

  Map<String, dynamic> toJson() => {
        'id': id,
        'guardianId': guardianId,
        'teenId': teenId,
        'permissions': permissions.map((e) => e.index).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory GuardianRelationship.fromJson(Map<String, dynamic> json) {
    return GuardianRelationship(
      id: json['id'],
      guardianId: json['guardianId'],
      teenId: json['teenId'],
      permissions: (json['permissions'] as List)
          .map((e) => GuardianPermission.values[e])
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
