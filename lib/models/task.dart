class Task {
  final String id;
  final String title;
  bool isCompleted;
  final String priority;
  bool isDone; // alias

  Task({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.priority,
    bool? isDone,
  }) : isDone = isDone ?? isCompleted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'priority': priority,
        'isDone': isDone,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        isCompleted: json['isCompleted'],
        priority: json['priority'] ?? 'Medium',
        isDone: json['isDone'] ?? json['isCompleted'],
      );
}
