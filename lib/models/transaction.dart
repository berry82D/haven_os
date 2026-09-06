import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

enum TransactionType { income, expense }

enum ClearedStatus { reconciled, pending, uncleared, cleared }

class Account {
  final String name;
  const Account([this.name = 'Cash']);
}

class Transaction {
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
  late String householdId;
  late String? gigIncomeId;

  Transaction(
      {String? id,
      String? description,
      String? name,
      String? place,
      DateTime? date,
      double? amount,
      String? notes,
      String? note,
      bool? isIncome,
      String? category,
      String? userId,
      dynamic account,
      dynamic cleared,
      TransactionType? type,
      Account? accountObj,
      ClearedStatus? clearedStatus,
      String? householdId,
      String? gigIncomeId})
      : householdId =
            (householdId?.isNotEmpty == true) ? householdId! : (userId ?? ''),
        id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        description = description ?? name ?? '',
        place = place ?? '',
        date = date ?? DateTime.now(),
        amount = amount ?? 0.0,
        notes = notes ?? note ?? '',
        isIncome = isIncome ??
            (type == TransactionType.income
                ? true
                : (type == TransactionType.expense ? false : false)),
        category = category ?? 'General',
        userId = userId ?? '' {
    if (this.isIncome == false && type == null) {
      final cat = this.category.toLowerCase();
      if (['paycheck', 'salary', 'income', 'deposit', 'wage', 'pay']
          .any((k) => cat.contains(k))) {
        this.isIncome = true;
      }
    }
    if (accountObj != null) {
      this.account = accountObj.name;
    } else if (account is Account) {
      this.account = account.name;
    } else if (account is String) {
      this.account = account;
    } else {
      this.account = 'Cash';
    }
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
    this.gigIncomeId = gigIncomeId;
  }

  TransactionType get type =>
      isIncome ? TransactionType.income : TransactionType.expense;
  String get note => notes;
  Account get accountObj => Account(account);
  ClearedStatus get clearedStatus =>
      cleared ? ClearedStatus.reconciled : ClearedStatus.pending;

  Map<String, dynamic> toJson() => {
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
        'householdId': householdId,
        'gigIncomeId': gigIncomeId
      };

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
      id: j['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      description: j['description'] ?? '',
      place: j['place'] ?? '',
      date: DateTime.parse(j['date']),
      amount: (j['amount'] ?? 0.0).toDouble(),
      notes: j['notes'] ?? '',
      isIncome: j['isIncome'] ?? false,
      category: j['category'] ?? 'General',
      userId: j['userId'] ?? '',
      account: j['account'] ?? 'Cash',
      cleared: j['cleared'] ?? false,
      householdId: j['householdId'] ?? j['userId'] ?? '',
      gigIncomeId: j['gigIncomeId']);

  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
  String get formattedAmount =>
      (isIncome ? '+' : '-') + '\$${amount.abs().toStringAsFixed(2)}';
  Color get amountColor => isIncome ? Colors.green : Colors.red;
}
