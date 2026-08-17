// lib/models/timeline_event.dart
enum TimelineEventType {
  task,
  transaction,
  bill,
  animal,
  general,
}

class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final TimelineEventType type;

  TimelineEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.timestamp,
    this.type = TimelineEventType.general,
  });

  // ---- JSON helpers ----
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
      };

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      type: TimelineEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TimelineEventType.general,
      ),
    );
  }
}
