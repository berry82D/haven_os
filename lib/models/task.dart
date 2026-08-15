enum Priority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isDone;
  final Priority priority;
  final String category;
  final String userId;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.isDone,
    required this.priority,
    required this.category,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'isDone': isDone,
        'priority': priority.index,
        'category': category,
        'userId': userId,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      isDone: json['isDone'],
      priority: Priority.values[json['priority']],
      category: json['category'],
      userId: json['userId'] ?? '',
    );
  }
}
