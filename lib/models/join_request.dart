enum JoinRequestStatus { pending, approved, rejected }

class JoinRequest {
  final String id;
  final String requesterUserId;
  final String requesterName;
  final String householdId;
  final String householdName;
  final String? message;
  final JoinRequestStatus status;
  final DateTime createdAt;

  JoinRequest({
    required this.id,
    required this.requesterUserId,
    required this.requesterName,
    required this.householdId,
    required this.householdName,
    this.message,
    this.status = JoinRequestStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'requesterUserId': requesterUserId,
        'requesterName': requesterName,
        'householdId': householdId,
        'householdName': householdName,
        'message': message,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
      };

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['id'],
      requesterUserId: json['requesterUserId'],
      requesterName: json['requesterName'],
      householdId: json['householdId'],
      householdName: json['householdName'],
      message: json['message'],
      status: JoinRequestStatus.values[json['status'] ?? 0],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
