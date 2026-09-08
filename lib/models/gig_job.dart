import 'package:cloud_firestore/cloud_firestore.dart';

class GigJob {
  String id;
  String platform;
  DateTime date;
  double earnings;
  double miles;
  double expenses;
  int minutes;
  String notes;

  GigJob({
    required this.id,
    required this.platform,
    required this.date,
    this.earnings = 0,
    this.miles = 0,
    this.expenses = 0,
    this.minutes = 0,
    this.notes = '',
  });

  double get net => earnings - expenses;
  double get perHour => minutes > 0 ? (net / (minutes / 60)) : 0;
  double get perMile => miles > 0 ? (net / miles) : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'platform': platform,
        'date': date.toIso8601String(),
        'earnings': earnings,
        'miles': miles,
        'expenses': expenses,
        'minutes': minutes,
        'notes': notes,
      };

  factory GigJob.fromMap(Map<String, dynamic> map) => GigJob(
        id: map['id'] ?? '',
        platform: map['platform'] ?? 'Other',
        date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
        earnings: (map['earnings'] ?? 0).toDouble(),
        miles: (map['miles'] ?? 0).toDouble(),
        expenses: (map['expenses'] ?? 0).toDouble(),
        minutes: (map['minutes'] ?? 0).toInt(),
        notes: map['notes'] ?? '',
      );

  factory GigJob.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GigJob.fromMap(data);
  }
}
