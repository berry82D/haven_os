import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/debt.dart';
import '../../models/transaction.dart';
import '../../services/app_state.dart';
import '../../services/firestore_service.dart';

class ZeroDebtScreen extends StatefulWidget {
  const ZeroDebtScreen({super.key});
  @override
  State<ZeroDebtScreen> createState() => _ZeroDebtScreenState();
}

class _ZeroDebtScreenState extends State<ZeroDebtScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zero-Debt Goal')),
      body: StreamBuilder<List<Debt>>(
        stream: FirestoreService().streamDebts(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final visible = all.where((d) => !d.isPaidOff).toList();
          final unknownCount = all.where((d) => d.balance == null).length;
          final totalOwed =
              all.fold<double>(0.0, (s, d) => s + (d.balance ?? 0));
          final knownOrig =
              all.where((d) => d.balance != null && d.originalBalance != null);
          final totalOrig = knownOrig
              .fold<double>(0.0, (s, d) => s + (d.originalBalance ?? 0));
          final double progress;
          if (all.isEmpty) {
            progress = 1.0;
          } else if (totalOrig <= 0) {
            progress = 0.0;
          } else {
            progress = ((totalOrig - totalOwed) / totalOrig).clamp(0.0, 1.0);
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('\$' + totalOwed.toStringAsFixed(2),
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text('Total owed',
                        style: TextStyle(color: Colors.grey)),
                    if (unknownCount > 0)
                      Text(
                          '$unknownCount debt${unknownCount == 1 ? '' : 's'} with unknown balance',
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 12)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                        value: progress.toDouble(), minHeight: 8),
                    const SizedBox(height: 4),
                    Text((progress * 100).toStringAsFixed(1) +
                        '% to debt-free'),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(all.isEmpty
                            ? 'No debts. Tap + to add one.'
                            : 'Debt-free!'))
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (c, i) {
                          final d = visible[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(d.creditor,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (d.balance == null)
                                    const Text('Balance unknown')
                                  else if (d.originalBalance != null)
                                    Text('Owes \$' +
                                        d.balance!.toStringAsFixed(2) +
                                        ' of \$' +
                                        d.originalBalance!.toStringAsFixed(2))
                                  else
                                    Text('Owes \$' +
                                        d.balance!.toStringAsFixed(2)),
                                  if (d.lastVerified != null)
                                    Text('Verified ' + _fmtDate(d.lastVerified!),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey)),
                                  if (d.status != 'active')
                                    Text('Status: ' + d.status,
                                        style: const TextStyle(
                                            color: Colors.orange)),
                                  if (d.settlementOffer != null)
                                    Text(
                                        'Settlement offer: \$' +
                                            d.settlementOffer!
                                                .toStringAsFixed(2),
                                        style: const TextStyle(
                                            color: Colors.green)),
                                  LinearProgressIndicator(
                                      value: d.progress, minHeight: 4),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.payment),
                                      tooltip: 'Mark payment',
                                      onPressed: () =>
                                          _markPayment(context, d)),
                                  IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _showDebtForm(context, existing: d)),
                                  IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          _confirmDelete(context, d)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _showDebtForm(context), child: const Icon(Icons.add)),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showDebtForm(BuildContext context, {Debt? existing}) {
    final appState = context.read<AppState>();
    final creditorCtrl = TextEditingController(text: existing?.creditor ?? '');
    final balanceCtrl = TextEditingController(
        text: existing?.balance == null
            ? ''
            : existing!.balance!.toStringAsFixed(2));
    final aprCtrl =
        TextEditingController(text: existing != null ? existing.apr.toString() : '');
    final payCtrl = TextEditingController(
        text: existing != null
            ? existing.monthlyPayment.toStringAsFixed(2)
            : '');
    final offerCtrl = TextEditingController(
        text: existing?.settlementOffer?.toStringAsFixed(2) ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String status = existing?.status ?? 'active';
    DateTime? dueDate = existing?.dueDate;
    DateTime? lastVerified = existing?.lastVerified;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Add Debt' : 'Edit Debt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: creditorCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Creditor *')),
                TextField(
                    controller: balanceCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Balance owed (blank if unknown)'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: aprCtrl,
                    decoration: const InputDecoration(
                        labelText: 'APR % (0 if none)'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: payCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Monthly payment'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: offerCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Settlement offer (optional)'),
                    keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: const [
                    'active',
                    'behind',
                    'settlement',
                    'charged_off',
                    'paid'
                  ]
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => status = v!),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100));
                    if (picked != null) setState(() => dueDate = picked);
                  },
                  child: Text(dueDate == null
                      ? 'Pick due date (optional)'
                      : 'Due: ' + _fmtDate(dueDate!)),
                ),
                TextButton(
                  onPressed: () => setState(() => lastVerified = DateTime.now()),
                  child: Text(lastVerified == null
                      ? 'Verified today'
                      : 'Verified ' + _fmtDate(lastVerified!)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final creditor = creditorCtrl.text.trim();
                      if (creditor.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text('Creditor is required')));
                        return;
                      }
                      final balanceText = balanceCtrl.text.trim();
                      final double? parsedBalance = balanceText.isEmpty
                          ? null
                          : double.tryParse(balanceText);
                      if (balanceText.isNotEmpty && parsedBalance == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text(
                                'Balance must be a number or blank')));
                        return;
                      }
                      double? finalBalance = parsedBalance;
                      if (status == 'paid') finalBalance = 0.0;

                      setState(() => saving = true);
                      try {
                        if (existing == null) {
                          final newDebt = Debt(
                            creditor: creditor,
                            balance: finalBalance,
                            originalBalance: finalBalance,
                            monthlyPayment:
                                double.tryParse(payCtrl.text) ?? 0.0,
                            apr: double.tryParse(aprCtrl.text) ?? 0.0,
                            settlementOffer:
                                double.tryParse(offerCtrl.text),
                            dueDate: dueDate,
                            status: status,
                            notes: notesCtrl.text.trim(),
                            householdId:
                                appState.currentUser?.householdId ?? '',
                            lastVerified: lastVerified,
                          );
                          await FirestoreService().saveDebt(newDebt);
                        } else {
                          double? orig = existing.originalBalance;
                          if (orig == null && finalBalance != null) {
                            orig = finalBalance;
                          }
                          final updated = existing.copyWith(
                            balance: finalBalance,
                            originalBalance: orig,
                            monthlyPayment:
                                double.tryParse(payCtrl.text) ?? 0.0,
                            apr: double.tryParse(aprCtrl.text) ?? 0.0,
                            settlementOffer:
                                double.tryParse(offerCtrl.text),
                            dueDate: dueDate,
                            status: status,
                            notes: notesCtrl.text.trim(),
                            lastVerified: lastVerified,
                          );
                          await FirestoreService().saveDebt(updated);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content:
                                  Text('Save failed: ' + e.toString())));
                          setState(() => saving = false);
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _markPayment(BuildContext context, Debt debt) {
    final appState = context.read<AppState>();
    final amtCtrl = TextEditingController();
    bool saving = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Payment to ' + debt.creditor),
          content: TextField(
              controller: amtCtrl,
              decoration: const InputDecoration(labelText: 'Amount paid'),
              keyboardType: TextInputType.number,
              autofocus: true),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final amt = double.tryParse(amtCtrl.text) ?? 0;
                      if (amt <= 0) return;
                      setState(() => saving = true);

                      double? newBalance;
                      if (debt.balance == null) {
                        newBalance = null;
                      } else {
                        final raw = debt.balance! - amt;
                        newBalance = raw < 0 ? 0.0 : raw;
                      }
                      final newStatus = (newBalance != null && newBalance <= 0)
                          ? 'paid'
                          : debt.status;
                      final updated = debt.copyWith(
                          balance: newBalance, status: newStatus);

                      final debtChanged = newBalance != debt.balance ||
                          newStatus != debt.status;
                      if (debtChanged) {
                        try {
                          await FirestoreService().saveDebt(updated);
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Could not save payment. Try again.')));
                            setState(() => saving = false);
                          }
                          return;
                        }
                      }

                      final tx = Transaction(
                        description: 'Payment: ' + debt.creditor,
                        date: DateTime.now(),
                        amount: amt,
                        isIncome: false,
                        category: 'Debts',
                        userId: appState.currentUser?.id ?? '',
                        householdId:
                            appState.currentUser?.householdId ?? '',
                      );
                      try {
                        await FirestoreService().saveTransaction(tx);
                        appState.addTransaction(tx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Debt updated, but the expense was not recorded. Add it manually.')));
                          setState(() => saving = false);
                        }
                        return;
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Debt debt) {
    bool saving = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Delete debt?'),
          content: Text('Remove "' +
              debt.creditor +
              '"? This cannot be undone.'),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      try {
                        await FirestoreService().deleteDebt(debt.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text('Delete failed')));
                          setState(() => saving = false);
                        }
                      }
                    },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}