import '../../models/transaction.dart';

class TransactionValidator {
  static String? validateDescription(String value) {
    if (value.trim().isEmpty) return 'Description is required';
    if (value.length > 200)
      return 'Description is too long (max 200 characters)';
    return null;
  }

  static String? validateAmount(String value) {
    final amount = double.tryParse(value);
    if (amount == null) return 'Enter a valid number';
    if (amount <= 0) return 'Amount must be greater than 0';
    return null;
  }

  static String? validateDate(DateTime? date) {
    if (date == null) return 'Date is required';
    if (date.isAfter(DateTime.now())) return 'Date cannot be in the future';
    return null;
  }

  static bool isValid(Transaction tx) {
    if (tx.description.trim().isEmpty) return false;
    if (tx.amount == 0) return false;
    if (tx.date.isAfter(DateTime.now())) return false;
    return true;
  }
}
