import 'package:haven_os/models/transaction.dart';

class FinanceService {
  // Core calculations
  double calculateTotalIncome(List<Transaction> transactions) {
    return transactions
        .where((t) => t.amount > 0)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double calculateTotalExpenses(List<Transaction> transactions) {
    return transactions
        .where((t) => t.amount < 0)
        .fold(0.0, (s, t) => s + t.amount.abs());
  }

  double calculateBalance(List<Transaction> transactions) {
    return calculateTotalIncome(transactions) -
        calculateTotalExpenses(transactions);
  }

  // Convenience aliases (used by older code)
  double getIncome(List<Transaction> transactions) =>
      calculateTotalIncome(transactions);
  double getExpenses(List<Transaction> transactions) =>
      calculateTotalExpenses(transactions);
  double getBalance(List<Transaction> transactions) =>
      calculateBalance(transactions);
}
