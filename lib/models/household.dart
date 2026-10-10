class Household {
  final String id;
  final String name;
  final DateTime createdAt;

  /// Short code Candice (or others) types to join. e.g. HAVEN-AB12
  final String inviteCode;

  /// Firebase uid or local account id of the creator (first partner).
  final String ownerUserId;

  /// Account ids that belong to this household (partners).
  final List<String> memberIds;

  Household({
    required this.id,
    required this.name,
    required this.createdAt,
    this.inviteCode = '',
    this.ownerUserId = '',
    List<String>? memberIds,
  }) : memberIds = memberIds ?? const [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'inviteCode': inviteCode,
        'ownerUserId': ownerUserId,
        'memberIds': memberIds,
      };

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      inviteCode: json['inviteCode'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      memberIds: (json['memberIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Household copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? inviteCode,
    String? ownerUserId,
    List<String>? memberIds,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      inviteCode: inviteCode ?? this.inviteCode,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}
