import '../../models/transaction.dart';

class FinanceService {
  double calculateMonthlyExpenses(Map<DateTime, double> expenses) {
    return expenses.values.fold(0.0, (sum, v) => sum + v);
  }

  double calculateSafeToSpend(double income, double expenses) {
    return income - expenses;
  }

  double calculateTotalIncome(List<Transaction> transactions) {
    return transactions
        .where((t) => t.amount > 0)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double calculateTotalExpenses(List<Transaction> transactions) {
    return transactions
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
  }
}
