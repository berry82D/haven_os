// lib/models/transaction.dart
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// ---------- Types used by old screens ----------
enum TransactionType { income, expense }

enum ClearedStatus { reconciled, pending, uncleared, cleared }

class Account {
  final String name;
  const Account([this.name = 'Cash']);
}

// ---------- Main Transaction Model ----------
class Transaction {
  // ---------- All fields ----------
  late String id;
  late String description;
  late String place;
  late DateTime date;
  late double amount;
  late String notes;
  late bool isIncome;
  late String category;
  late String userId;
  late String account;
  late bool cleared;

  // ---------- Constructor: Accepts ALL parameter styles ----------
  Transaction({
    String? id, // <-- explicit
    String? description,
    String? name, // <-- explicit (alias for description)
    String? place,
    DateTime? date,
    double? amount,
    String? notes,
    String? note, // <-- explicit (alias for notes)
    bool? isIncome,
    String? category,
    String? userId,
    // These accept both types
    dynamic account,
    dynamic cleared,
    // Old-style type
    TransactionType? type,
    Account? accountObj,
    ClearedStatus? clearedStatus,
  }) {
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    this.description = description ?? name ?? '';
    this.place = place ?? '';
    this.date = date ?? DateTime.now();
    this.amount = amount ?? 0.0;
    this.notes = notes ?? note ?? '';
    this.isIncome = isIncome ??
        (type == TransactionType.income
            ? true
            : (type == TransactionType.expense ? false : false));
    this.category = category ?? 'General';
    this.userId = userId ?? '';

    // Account: accepts String OR Account object
    if (accountObj != null) {
      this.account = accountObj.name;
    } else if (account is Account) {
      this.account = account.name;
    } else if (account is String) {
      this.account = account;
    } else {
      this.account = 'Cash';
    }

    // Cleared: accepts bool OR ClearedStatus
    if (clearedStatus != null) {
      this.cleared = clearedStatus == ClearedStatus.reconciled ||
          clearedStatus == ClearedStatus.cleared;
    } else if (cleared is ClearedStatus) {
      this.cleared = cleared == ClearedStatus.reconciled ||
          cleared == ClearedStatus.cleared;
    } else if (cleared is bool) {
      this.cleared = cleared;
    } else {
      this.cleared = false;
    }
  }

  // ---------- Getters for old field names ----------
  TransactionType get type =>
      isIncome ? TransactionType.income : TransactionType.expense;
  String get note => notes;
  Account get accountObj => Account(account);
  ClearedStatus get clearedStatus =>
      cleared ? ClearedStatus.reconciled : ClearedStatus.pending;

  // ---------- JSON serialization ----------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'place': place,
      'date': date.toIso8601String(),
      'amount': amount,
      'notes': notes,
      'isIncome': isIncome,
      'category': category,
      'userId': userId,
      'account': account,
      'cleared': cleared,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      description: json['description'] ?? '',
      place: json['place'] ?? '',
      date: DateTime.parse(json['date']),
      amount: (json['amount'] ?? 0.0).toDouble(),
      notes: json['notes'] ?? '',
      isIncome: json['isIncome'] ?? false,
      category: json['category'] ?? 'General',
      userId: json['userId'] ?? '',
      account: json['account'] ?? 'Cash',
      cleared: json['cleared'] ?? false,
    );
  }

  // ---------- Display helpers ----------
  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
  String get formattedAmount =>
      (isIncome ? '+' : '-') + '\$${amount.toStringAsFixed(2)}';
  Color get amountColor => isIncome ? Colors.green : Colors.red;
}
