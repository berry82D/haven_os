import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/debt.dart';
import '../../models/transaction.dart';
import '../../services/app_state.dart';
import '../../services/debt_payoff.dart';
import '../../services/firestore_service.dart';

/// Payoff Plan — map to debt-free from real numbers.
class DebtPayoffScreen extends StatefulWidget {
  const DebtPayoffScreen({super.key});

  @override
  State<DebtPayoffScreen> createState() => _DebtPayoffScreenState();
}

class _DebtPayoffScreenState extends State<DebtPayoffScreen> {
  final _extraCtrl = TextEditingController();
  bool _extraInit = false;
  bool _userPicked = false;
  PayoffStrategy _selected = PayoffStrategy.snowball;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void dispose() {
    _extraCtrl.dispose();
    super.dispose();
  }

  String _monthLabel(int monthIndex) {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month + monthIndex);
    return _monthNames[d.month - 1] + ' ' + d.year.toString();
  }

  double get _extra {
    final raw =
        _extraCtrl.text.replaceAll('\$', '').replaceAll(',', '').trim();
    final v = double.tryParse(raw) ?? 0;
    return v < 0 ? 0 : v;
  }

  /// Month income - expenses - unpaid bills due this month - $100 buffer.
  double _suggestedLeft(List<Transaction> txs) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    bool inMonth(DateTime d) => !d.isBefore(start) && d.isBefore(end);

    final incomes = txs
        .where((t) => t.isIncome && inMonth(t.date))
        .fold<double>(0.0, (s, t) => s + t.amount);
    final expenses = txs
        .where((t) => !t.isIncome && inMonth(t.date))
        .fold<double>(0.0, (s, t) => s + t.amount);

    var billsDue = 0.0;
    try {
      for (final b in context.read<AppState>().myBills) {
        if (b.isPaid) continue;
        if (inMonth(b.dueDate)) billsDue += b.amount;
      }
    } catch (_) {}

    final left = incomes - expenses - billsDue - 100.0;
    return left > 0 ? left : 0;
  }

  String _strategyName(PayoffStrategy s) {
    if (s == PayoffStrategy.minimums) return 'Minimums only';
    if (s == PayoffStrategy.snowball) return 'Snowball';
    return 'Avalanche';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payoff Plan')),
      body: StreamBuilder<List<Debt>>(
        stream: FirestoreService().streamDebts(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load debts: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final debts = snap.data!;
          return StreamBuilder<List<Transaction>>(
            stream: FirestoreService().streamTransactions(),
            builder: (context, txSnap) {
              var suggested = 0.0;
              if (txSnap.hasData) {
                suggested = _suggestedLeft(txSnap.data!);
                if (!_extraInit) {
                  _extraInit = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    if (_extraCtrl.text.isEmpty && suggested > 0) {
                      _extraCtrl.text = suggested.toStringAsFixed(0);
                    }
                    setState(() {});
                  });
                }
              }
              return _body(debts, suggested);
            },
          );
        },
      ),
    );
  }

  Widget _body(List<Debt> debts, double suggested) {
    final extra = _extra;
    final results = <PayoffStrategy, PayoffResult>{
      PayoffStrategy.minimums:
          planPayoff(debts, extra: 0, strategy: PayoffStrategy.minimums),
      PayoffStrategy.snowball:
          planPayoff(debts, extra: extra, strategy: PayoffStrategy.snowball),
      PayoffStrategy.avalanche:
          planPayoff(debts, extra: extra, strategy: PayoffStrategy.avalanche),
    };

    PayoffStrategy? best;
    for (final e in results.entries) {
      if (!e.value.ok) continue;
      if (best == null) {
        best = e.key;
        continue;
      }
      final b = results[best]!;
      if (e.value.months < b.months ||
          (e.value.months == b.months &&
              e.value.totalInterest < b.totalInterest)) {
        best = e.key;
      }
    }

    final shown = _userPicked ? _selected : (best ?? _selected);
    final sel = results[shown]!;
    final base = results[PayoffStrategy.minimums]!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Every set payment is paid in full, every month. This plan only '
          'aims freed money and your extra — it never skips a bill to fund '
          'another debt.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _extraCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Extra per month',
            prefixText: '\$ ',
            helperText: suggested > 0
                ? 'Filled from Left this month (~\$' +
                    suggested.toStringAsFixed(0) +
                    ' after bills and buffer). Change if you like.'
                : 'Payments alone until you add an extra.',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            for (final s in PayoffStrategy.values)
              ChoiceChip(
                label: Text(_strategyName(s) +
                    (results[s]!.ok
                        ? ' — ' + results[s]!.months.toString() + ' mo'
                        : '') +
                    (best == s ? ' · Best' : '')),
                selected: shown == s,
                onSelected: (_) => setState(() {
                  _userPicked = true;
                  _selected = s;
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (best != null &&
            shown == best &&
            base.ok &&
            sel.ok &&
            best != PayoffStrategy.minimums)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Best path: ' + _strategyName(best),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Debt-free by ' +
                        _monthLabel(sel.months) +
                        ' — ' +
                        (base.months - sel.months).toString() +
                        ' months sooner and \$' +
                        (base.totalInterest - sel.totalInterest)
                            .toStringAsFixed(2) +
                        ' less interest than minimums alone.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        if (!sel.ok) _problem(sel),
        if (sel.ok) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debt-free by ' + _monthLabel(sel.months),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sel.months.toString() +
                        ' months — total interest \$' +
                        sel.totalInterest.toStringAsFixed(2),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < sel.lines.length; i++)
            ListTile(
              leading: CircleAvatar(child: Text((i + 1).toString())),
              title: Text(sel.lines[i].creditor),
              subtitle: Text(
                'Clear by ' +
                    _monthLabel(sel.lines[i].payoffMonth) +
                    ' — interest \$' +
                    sel.lines[i].interestPaid.toStringAsFixed(2),
              ),
            ),
        ],
        if (sel.excludedUnknown > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              sel.excludedUnknown.toString() +
                  (sel.excludedUnknown == 1
                      ? ' debt is not counted yet — balance unknown.'
                      : ' debts are not counted yet — balances unknown.'),
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        for (final w in sel.warnings)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(w, style: const TextStyle(color: Colors.orange)),
          ),
      ],
    );
  }

  Widget _problem(PayoffResult r) {
    final String msg;
    if (r.reason == 'empty') {
      msg = 'Add a debt with a known balance and the plan will map itself.';
    } else if (r.reason == 'needsAmount') {
      msg = 'Type an extra above — even a small one — so the plan has free '
          'money to aim. Nothing is planned with money you did not approve.';
    } else {
      msg = 'At these payments, interest outruns the plan. Warnings below '
          'name the debt that needs a larger payment or more extra.';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(msg, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}