import 'package:intl/intl.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/models/bill.dart';
import 'package:haven_os/models/task.dart';
import 'package:haven_os/models/animal.dart';

class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final TimelineEventType type;
  final Map<String, dynamic>? metadata;
  final String userId; // NEW

  TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.metadata,
    required this.userId,
  });

  String get formattedTime => DateFormat('h:mm a').format(timestamp);
  String get formattedDate => DateFormat('MMM d').format(timestamp);
  String get timeAgo => _timeAgo(timestamp);

  String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 7) return DateFormat('MMM d').format(date);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return timestamp.year == yesterday.year &&
        timestamp.month == yesterday.month &&
        timestamp.day == yesterday.day;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'type': type.index,
        'metadata': metadata,
        'userId': userId,
      };

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      type: TimelineEventType.values[json['type']],
      metadata: json['metadata'],
      userId: json['userId'] ?? '',
    );
  }

  factory TimelineEvent.transactionAdded(Transaction tx) {
    final isIncome = tx.amount > 0;
    return TimelineEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      title: isIncome ? '💰 Income Added' : '💳 Expense Added',
      description:
          '${isIncome ? '+' : '-'}\$${tx.amount.abs().toStringAsFixed(2)} • ${tx.description}',
      timestamp: DateTime.now(),
      type: TimelineEventType.finance,
      metadata: {'transactionId': tx.id, 'amount': tx.amount},
      userId: tx.userId,
    );
  }

  factory TimelineEvent.billPaid(Bill bill) {
    return TimelineEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      title: '✅ Bill Paid',
      description: '${bill.name} • \$${bill.amount.toStringAsFixed(2)}',
      timestamp: DateTime.now(),
      type: TimelineEventType.bill,
      metadata: {'billId': bill.id},
      userId: bill.userId,
    );
  }

  factory TimelineEvent.taskCompleted(Task task) {
    return TimelineEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      title: '✅ Task Completed',
      description: task.title,
      timestamp: DateTime.now(),
      type: TimelineEventType.task,
      metadata: {'taskId': task.id},
      userId: task.userId,
    );
  }

  factory TimelineEvent.animalHealthUpdated(Animal animal) {
    return TimelineEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      title: '🐾 Health Update',
      description: '${animal.name} is now ${animal.health}',
      timestamp: DateTime.now(),
      type: TimelineEventType.animal,
      metadata: {'animalId': animal.id, 'health': animal.health},
      userId: animal.userId,
    );
  }

  factory TimelineEvent.systemEvent(String title, String description,
      {String? userId}) {
    return TimelineEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      timestamp: DateTime.now(),
      type: TimelineEventType.system,
      userId: userId ?? '',
    );
  }
}

enum TimelineEventType {
  finance,
  bill,
  task,
  animal,
  system,
}
