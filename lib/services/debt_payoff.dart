import '../models/debt.dart';

/// Path-to-debt-free planner (Rocky + Grok pass, Oct 21 2026).
///
/// Hard rules (David):
/// - Every debt's set monthly payment is paid in full, every month.
/// - Only free money is aimed: payments freed when a debt clears, plus user extra.
/// - Data only. Unknown balances are counted and left out, never guessed.
enum PayoffStrategy { minimums, snowball, avalanche }

class PayoffLine {
  final String creditor;
  final int payoffMonth; // 1-based month index from plan start
  final double interestPaid;
  const PayoffLine(this.creditor, this.payoffMonth, this.interestPaid);
}

class PayoffResult {
  final bool ok;
  final String reason; // '' | 'empty' | 'needsAmount' | 'stalled'
  final int months;
  final double totalInterest;
  final List<PayoffLine> lines;
  final int excludedUnknown;
  final List<String> warnings;

  const PayoffResult({
    required this.ok,
    this.reason = '',
    this.months = 0,
    this.totalInterest = 0,
    this.lines = const [],
    this.excludedUnknown = 0,
    this.warnings = const [],
  });
}

class _SimDebt {
  final String creditor;
  double bal;
  final double apr;
  final double pay;
  double interest = 0;
  int? off;
  _SimDebt(this.creditor, this.bal, this.apr, this.pay);
}

PayoffResult planPayoff(
  List<Debt> debts, {
  required double extra,
  required PayoffStrategy strategy,
}) {
  final safeExtra = extra < 0 ? 0.0 : extra;
  final rollFreed = strategy != PayoffStrategy.minimums;

  final included = debts
      .where((d) => !d.isPaidOff && d.status != 'paid')
      .toList();
  final unknown = included.where((d) => d.balance == null).length;
  final known = included
      .where((d) => d.balance != null && d.balance! > 0)
      .toList();

  if (known.isEmpty) {
    return PayoffResult(
        ok: false, reason: 'empty', excludedUnknown: unknown);
  }

  final pool0 =
      known.fold<double>(0.0, (s, d) => s + d.monthlyPayment) + safeExtra;
  if (pool0 <= 0) {
    return PayoffResult(
        ok: false, reason: 'needsAmount', excludedUnknown: unknown);
  }

  final warnings = <String>[];
  final st = known.map((d) {
    final firstInterest = d.balance! * d.apr / 1200.0;
    if (d.monthlyPayment + 0.0001 < firstInterest) {
      warnings.add(
        d.creditor +
            ': payment does not cover monthly interest (~\$' +
            firstInterest.toStringAsFixed(2) +
            ') — balance grows until surplus reaches it.',
      );
    }
    return _SimDebt(d.creditor, d.balance!, d.apr, d.monthlyPayment);
  }).toList();

  int cmp(_SimDebt a, _SimDebt b) {
    if (strategy == PayoffStrategy.avalanche) {
      final c = b.apr.compareTo(a.apr);
      if (c != 0) return c;
      return a.bal.compareTo(b.bal);
    }
    final c = a.bal.compareTo(b.bal);
    if (c != 0) return c;
    return b.apr.compareTo(a.apr);
  }

  var month = 0;
  var stalled = false;
  while (st.any((s) => s.bal > 0)) {
    month++;
    if (month > 1200) {
      stalled = true;
      break;
    }

    for (final s in st) {
      if (s.bal > 0) {
        final i = s.bal * s.apr / 1200.0;
        s.bal += i;
        s.interest += i;
      }
    }

    var p = rollFreed
        ? pool0
        : st.where((s) => s.bal > 0).fold<double>(0.0, (sum, s) => sum + s.pay) +
            safeExtra;

    for (final s in st) {
      if (s.bal > 0) {
        final amt = s.pay < s.bal ? s.pay : s.bal;
        s.bal -= amt;
        p -= amt;
      }
    }

    while (p > 0.0001 && st.any((s) => s.bal > 0)) {
      final act = st.where((s) => s.bal > 0).toList()..sort(cmp);
      final t = act.first;
      final amt = p < t.bal ? p : t.bal;
      t.bal -= amt;
      p -= amt;
    }

    for (final s in st) {
      if (s.bal <= 0.0001 && s.off == null) {
        s.bal = 0;
        s.off = month;
      }
    }
  }

  if (stalled) {
    return PayoffResult(
      ok: false,
      reason: 'stalled',
      excludedUnknown: unknown,
      warnings: warnings,
    );
  }

  final lines = st
      .map((s) => PayoffLine(s.creditor, s.off ?? month, s.interest))
      .toList()
    ..sort((a, b) => a.payoffMonth.compareTo(b.payoffMonth));

  return PayoffResult(
    ok: true,
    months: month,
    totalInterest: st.fold<double>(0.0, (s, x) => s + x.interest),
    lines: lines,
    excludedUnknown: unknown,
    warnings: warnings,
  );
}