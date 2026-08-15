import 'package:haven_os/models/loan.dart';

class LoanService {
  double calculateTotalMonthlyPayments(List<Loan> loans) {
    return loans.fold(0.0, (sum, loan) => sum + loan.monthlyPayment);
  }

  double calculateTotalRemainingBalance(List<Loan> loans) {
    return loans.fold(0.0, (sum, loan) => sum + loan.currentBalance);
  }

  double calculateTotalInterest(List<Loan> loans) {
    return loans.fold(0.0, (sum, loan) => sum + loan.totalInterest);
  }

  double calculateTotalPrincipal(List<Loan> loans) {
    return loans.fold(0.0, (sum, loan) => sum + loan.principal);
  }

  Map<String, dynamic> getSummary(List<Loan> loans) {
    return {
      'totalLoans': loans.length,
      'totalPrincipal': calculateTotalPrincipal(loans),
      'totalRemaining': calculateTotalRemainingBalance(loans),
      'totalInterest': calculateTotalInterest(loans),
      'totalMonthlyPayment': calculateTotalMonthlyPayments(loans),
      'trueCost': loans.isEmpty
          ? 0.0
          : calculateTotalPrincipal(loans) + calculateTotalInterest(loans),
    };
  }
}
