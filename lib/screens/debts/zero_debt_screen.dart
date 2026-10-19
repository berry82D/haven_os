import 'package:flutter/material.dart';
import '../../models/debt.dart';
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
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final debts = snap.data!.where((d) => !d.isPaidOff).toList();
          final totalOwed = debts.fold(0.0, (s, d) => s + d.balance);
          final totalOrig = debts.fold(0.0, (s, d) => s + d.originalBalance);
          final progress = totalOrig <= 0 ? 1.0 : ((totalOrig - totalOwed) / totalOrig).clamp(0.0, 1.0);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('\$' + totalOwed.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text('Total owed', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress, minHeight: 8),
                    const SizedBox(height: 4),
                    Text((progress * 100).toStringAsFixed(1) + '% to debt-free'),
                  ],
                ),
              ),
              Expanded(
                child: debts.isEmpty
                    ? const Center(child: Text('No debts. Tap + to add one.'))
                    : ListView.builder(
                        itemCount: debts.length,
                        itemBuilder: (c, i) {
                          final d = debts[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(d.creditor, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Owes \$' + d.balance.toStringAsFixed(2) + ' of \$' + d.originalBalance.toStringAsFixed(2)),
                                  if (d.status != 'active') Text('Status: ' + d.status, style: const TextStyle(color: Colors.orange)),
                                  if (d.settlementOffer != null) Text('Settlement offer: \$' + d.settlementOffer!.toStringAsFixed(2), style: const TextStyle(color: Colors.green)),
                                  LinearProgressIndicator(value: d.progress, minHeight: 4),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.payment), tooltip: 'Mark payment', onPressed: () => _markPayment(context, d)),
                                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _showDebtForm(context, existing: d)),
                                  IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(context, d)),
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
      floatingActionButton: FloatingActionButton(onPressed: () => _showDebtForm(context), child: const Icon(Icons.add)),
    );
  }

  void _showDebtForm(BuildContext context, {Debt? existing}) {
    final creditorCtrl = TextEditingController(text: existing?.creditor ?? '');
    final balanceCtrl = TextEditingController(text: existing != null ? existing.balance.toStringAsFixed(2) : '');
    final aprCtrl = TextEditingController(text: existing != null ? existing.apr.toString() : '');
    final payCtrl = TextEditingController(text: existing != null ? existing.monthlyPayment.toStringAsFixed(2) : '');
    final offerCtrl = TextEditingController(text: existing?.settlementOffer?.toStringAsFixed(2) ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String status = existing?.status ?? 'active';
    DateTime? dueDate = existing?.dueDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Add Debt' : 'Edit Debt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: creditorCtrl, decoration: const InputDecoration(labelText: 'Creditor *')),
                TextField(controller: balanceCtrl, decoration: const InputDecoration(labelText: 'Balance owed *'), keyboardType: TextInputType.number),
                TextField(controller: aprCtrl, decoration: const InputDecoration(labelText: 'APR % (0 if none)'), keyboardType: TextInputType.number),
                TextField(controller: payCtrl, decoration: const InputDecoration(labelText: 'Monthly payment'), keyboardType: TextInputType.number),
                TextField(controller: offerCtrl, decoration: const InputDecoration(labelText: 'Settlement offer (optional)'), keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: const ['active', 'behind', 'settlement', 'charged_off', 'paid'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => status = v!),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: ctx, initialDate: dueDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setState(() => dueDate = picked);
                  },
                  child: Text(dueDate == null ? 'Pick due date (optional)' : 'Due: ' + dueDate!.toString().split(' ')[0]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final creditor = creditorCtrl.text.trim();
                final balance = double.tryParse(balanceCtrl.text) ?? -1;
                if (creditor.isEmpty || balance < 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Creditor and valid balance required')));
                  return;
                }
                final debt = Debt(
                  id: existing?.id,
                  creditor: creditor,
                  balance: balance,
                  originalBalance: existing?.originalBalance,
                  monthlyPayment: double.tryParse(payCtrl.text) ?? 0.0,
                  apr: double.tryParse(aprCtrl.text) ?? 0.0,
                  settlementOffer: double.tryParse(offerCtrl.text),
                  dueDate: dueDate,
                  status: status,
                  notes: notesCtrl.text.trim(),
                );
                await FirestoreService().saveDebt(debt);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _markPayment(BuildContext context, Debt debt) {
    final amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payment to ' + debt.creditor),
        content: TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: 'Amount paid'), keyboardType: TextInputType.number, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text) ?? 0;
              if (amt <= 0) return;
              final newBal = (debt.balance - amt).clamp(0.0, double.infinity);
              final updated = debt.copyWith(balance: newBal, status: newBal <= 0 ? 'paid' : debt.status);
              await FirestoreService().saveDebt(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Debt debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete debt?'),
        content: Text('Remove "' + debt.creditor + '" (\$' + debt.balance.toStringAsFixed(2) + ')? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirestoreService().deleteDebt(debt.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}