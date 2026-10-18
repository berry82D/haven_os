import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gig_income.dart';
import '../../models/gig_job.dart';
import '../../models/transaction.dart';
import '../../services/app_state.dart';
import '../../services/firestore_service.dart';

class GigIncomeScreen extends StatefulWidget {
  const GigIncomeScreen({super.key});
  @override
  State<GigIncomeScreen> createState() => _GigIncomeScreenState();
}

/// One row in the gig list: a GigIncome (full detail) or a standalone
/// gig Transaction (from Import / Scan / Finances) with no GigIncome.
class _GigRow {
  final DateTime date;
  final double amount;
  final String title;
  final String subtitle;
  final double miles;
  final GigIncome? gig;
  final Transaction? tx;
  _GigRow({
    required this.date,
    required this.amount,
    required this.title,
    required this.subtitle,
    this.miles = 0,
    this.gig,
    this.tx,
  });
}

class _GigIncomeScreenState extends State<GigIncomeScreen> {
  Map<String, GigJob> _jobs = {};
  String? _month; // 'yyyy-MM', 'y:yyyy' (full year), or null = current month

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await FirestoreService().streamGigJobs().first;
      if (!mounted) return;
      setState(() {
        _jobs = {for (final j in jobs) j.id: j};
      });
    } catch (e) {
      debugPrint('Gig jobs load failed: ' + e.toString());
    }
  }

  static String _cap(String s) {
    final v = s.trim();
    return v.isEmpty ? '' : (v[0].toUpperCase() + v.substring(1));
  }

  /// All gigs: GigIncome entries + gig Transactions, deduped by link.
  List<_GigRow> _buildRows(AppState appState) {
    final rows = <_GigRow>[];
    final gigIds = <String>{};
    for (final g in appState.myGigIncomes) {
      gigIds.add(g.id);
      rows.add(_GigRow(
        date: g.date,
        amount: g.totalAmount,
        title: '${g.platformName} • ${g.formattedTotal}',
        subtitle:
            '${g.formattedDate} • ${g.miles.toStringAsFixed(1)} mi • \$${g.payPerMile.toStringAsFixed(2)}/mi',
        gig: g,
        miles: g.miles,
      ));
    }
    for (final t in appState.myTransactions) {
      if (!t.isIncome) continue;
      final isGig = t.category == 'Gig Income' ||
          (t.gigIncomeId != null && t.gigIncomeId!.isNotEmpty);
      if (!isGig) continue;
      if (t.gigIncomeId != null && gigIds.contains(t.gigIncomeId)) continue;
      final job = t.gigIncomeId == null ? null : _jobs[t.gigIncomeId];
      final jp = job == null ? '' : _cap(job.platform);
      final platform =
          jp.isNotEmpty ? jp : _platformFromDescription(t.description);
      final miles = job?.miles ?? 0.0;
      final perMile = miles > 0 ? t.amount / miles : 0.0;
      rows.add(_GigRow(
        date: t.date,
        amount: t.amount,
        title: '$platform • \$${t.amount.toStringAsFixed(2)}',
        subtitle: miles > 0
            ? '${t.date.month}/${t.date.day}/${t.date.year} • ${miles.toStringAsFixed(1)} mi • \$${perMile.toStringAsFixed(2)}/mi'
            : '${t.date.month}/${t.date.day}/${t.date.year} • from ${t.category}',
        tx: t,
        miles: miles,
      ));
    }
    rows.sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }

  String _platformFromDescription(String desc) {
    final d = desc.trim();
    if (d.isEmpty) return 'Gig';
    if (d.endsWith(' Gig Job')) {
      final p = d.substring(0, d.length - ' Gig Job'.length).trim();
      if (p.isNotEmpty) return p;
    }
    return d.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gig Income')),
      body: Consumer<AppState>(builder: (context, appState, _) {
        final allRows = _buildRows(appState);
        if (allRows.isEmpty) {
          return const Center(child: Text('No gig income yet'));
        }
        final now = DateTime.now();
        String keyOf(DateTime d) =>
            d.year.toString() + '-' + d.month.toString().padLeft(2, '0');
        final keySet = <String>{keyOf(now)};
        for (final r in allRows) {
          keySet.add(keyOf(r.date));
        }
        final keys = keySet.toList()..sort((a, b) => b.compareTo(a));
        final years = keySet.map((k) => k.substring(0, 4)).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
        final validSel = <String>{...keys, ...years.map((y) => 'y:' + y)};
        final sel = (_month != null && validSel.contains(_month))
            ? _month!
            : keyOf(now);
        final isYear = sel.startsWith('y:');
        final selYear = isYear ? sel.substring(2) : sel.substring(0, 4);
        final rows = isYear
            ? allRows.where((r) => r.date.year.toString() == selYear).toList()
            : allRows.where((r) => keyOf(r.date) == sel).toList();
        final totalMonth = rows.fold<double>(0, (s, r) => s + r.amount);
        final totalYear = allRows
            .where((r) => r.date.year.toString() == selYear)
            .fold<double>(0, (s, r) => s + r.amount);
        final totalMiles = rows.fold<double>(0, (s, r) => s + r.miles);
        final avg = totalMiles > 0 ? totalMonth / totalMiles : 0.0;
        String label(String k) => k.startsWith('y:')
            ? ('Year ' + k.substring(2))
            : (k.substring(5) + '/' + k.substring(0, 4));
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(children: [
              const Text('Show: ', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: sel,
                dropdownColor: const Color(0xFF1E1E1E),
                items: [
                  for (final y in years) ...[
                    DropdownMenuItem(
                        value: 'y:' + y, child: Text('Full year ' + y)),
                    for (final k in keys.where((k) => k.startsWith(y)))
                      DropdownMenuItem(value: k, child: Text(label(k))),
                  ],
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _month = v);
                },
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _sum(label(sel), '\$${totalMonth.toStringAsFixed(2)}'),
                    _sum('Year ' + selYear, '\$${totalYear.toStringAsFixed(2)}'),
                    _sum('Miles', totalMiles.toStringAsFixed(1)),
                    _sum('Avg/mi', '\$${avg.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final r = rows[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: Material(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      title: Text(r.title),
                      subtitle: Text(r.subtitle),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (r.gig != null)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _show(context, existing: r.gig),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => r.gig != null
                                ? _deleteGigTx(r.gig!.id)
                                : _deleteTx(r.tx!.id),
                          ),
                        ],
                      ),
                      onTap: r.gig == null && r.tx != null
                          ? () => _showTxDetail(context, r.tx!)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ]);
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _show(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _sum(String l, String v) => Column(children: [
        Text(l, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]);

  void _show(BuildContext context, {GigIncome? existing}) {
    final appState = context.read<AppState>();
    final isEdit = existing != null;
    GigPlatform plat = existing?.platform ?? GigPlatform.doordash;
    DateTime dt = existing?.date ?? DateTime.now();
    final base =
        TextEditingController(text: existing?.basePay.toString() ?? '');
    final tips =
        TextEditingController(text: existing?.tips.toString() ?? '');
    final bonus =
        TextEditingController(text: existing?.bonus.toString() ?? '');
    final miles =
        TextEditingController(text: existing?.miles.toString() ?? '');
    final mile =
        TextEditingController(text: existing?.mileage.toString() ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          double b = double.tryParse(base.text) ?? 0;
          double t = double.tryParse(tips.text) ?? 0;
          double bo = double.tryParse(bonus.text) ?? 0;
          double tot = b + t + bo;
          return AlertDialog(
            title: Text(isEdit ? 'Edit Gig Income' : 'Add Gig Income'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<GigPlatform>(
                    initialValue: plat,
                    items: GigPlatform.values.map((p) {
                      final tmp = GigIncome(
                          id: 't',
                          userId: '',
                          householdId: '',
                          date: DateTime.now(),
                          platform: p,
                          basePay: 0,
                          tips: 0,
                          bonus: 0,
                          mileage: 0,
                          miles: 0,
                          totalAmount: 0);
                      return DropdownMenuItem(
                          value: p, child: Text(tmp.platformName));
                    }).toList(),
                    onChanged: (v) => setSt(() => plat = v ?? plat),
                    decoration:
                        const InputDecoration(labelText: 'Platform'),
                  ),
                  Row(children: [
                    Text('${dt.month}/${dt.day}/${dt.year}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final pk = await showDatePicker(
                            context: ctx,
                            initialDate: dt,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)));
                        if (pk != null) setSt(() => dt = pk);
                      },
                      child: const Text('Pick Date'),
                    ),
                  ]),
                  TextField(
                      controller: base,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Base Pay'),
                      onChanged: (_) => setSt(() {})),
                  TextField(
                      controller: tips,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Tips'),
                      onChanged: (_) => setSt(() {})),
                  TextField(
                      controller: bonus,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Bonus'),
                      onChanged: (_) => setSt(() {})),
                  TextField(
                      controller: miles,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Miles')),
                  TextField(
                      controller: mile,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Mileage Rate')),
                  TextField(
                      controller: notes,
                      decoration:
                          const InputDecoration(labelText: 'Notes')),
                  Text('Total: \$${tot.toStringAsFixed(2)}',
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () {
                    final uid = appState.currentUser?.id ??
                        appState.currentUser?.householdId ??
                        'unknown';
                    final hid =
                        appState.currentUser?.householdId ?? uid;
                    final g = GigIncome(
                        id: existing?.id ??
                            DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                        userId: existing?.userId ?? uid,
                        householdId: existing?.householdId ?? hid,
                        date: dt,
                        platform: plat,
                        basePay: double.tryParse(base.text) ?? 0,
                        tips: double.tryParse(tips.text) ?? 0,
                        bonus: double.tryParse(bonus.text) ?? 0,
                        mileage: double.tryParse(mile.text) ?? 0,
                        miles: double.tryParse(miles.text) ?? 0,
                        totalAmount: tot,
                        notes: notes.text,
                        transactionId: existing?.transactionId);
                    if (isEdit) {
                      appState.updateGigIncome(g);
                    } else {
                      appState.addGigIncome(g);
                    }
                    _syncGigTx(g);
                    Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'Update' : 'Save')),
            ],
          );
        });
      },
    );
  }

  Future<void> _syncGigTx(GigIncome g) async {
    final appState = context.read<AppState>();
    for (final t in appState.myTransactions) {
      if (t.gigIncomeId == g.id) {
        await FirestoreService().saveTransaction(t);
        break;
      }
    }
  }

  Future<void> _deleteGigTx(String gigId) async {
    final appState = context.read<AppState>();
    String? txId;
    for (final t in appState.myTransactions) {
      if (t.gigIncomeId == gigId) {
        txId = t.id;
        break;
      }
    }
    appState.deleteGigIncome(gigId);
    if (txId != null) await FirestoreService().deleteTransaction(txId);
  }

  Future<void> _deleteTx(String txId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this gig entry?'),
        content: const Text(
            'This entry came from import or scan. Deleting removes it from Finances too.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final appState = context.read<AppState>();
    appState.deleteTransaction(txId);
    await FirestoreService().deleteTransaction(txId);
  }

  void _showTxDetail(BuildContext context, Transaction t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            t.description.trim().isEmpty ? 'Gig' : t.description.trim()),
        content: Text(
          'Amount: \$${t.amount.toStringAsFixed(2)}\n' +
              'Date: ${t.date.month}/${t.date.day}/${t.date.year}\n' +
              'Category: ${t.category}' +
              (t.notes.trim().isNotEmpty
                  ? '\nNotes: ${t.notes.trim()}'
                  : ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}