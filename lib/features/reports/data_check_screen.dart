import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/gig_job.dart';
import '../../models/transaction.dart';
import '../../services/firestore_service.dart';

/// Read-only data check. Reads the same Firestore data the Finances tab
/// uses and prints totals, duplicate suspects and raw rows for fact-checking.
class DataCheckScreen extends StatefulWidget {
  const DataCheckScreen({super.key});

  @override
  State<DataCheckScreen> createState() => _DataCheckScreenState();
}

class _DataCheckScreenState extends State<DataCheckScreen> {
  String? _summary;
  String? _csv;
  String? _error;
  List<Transaction> _toDelete = [];
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final fs = FirestoreService();
      final txs = await fs.streamTransactions().first;
      final jobs = await fs.streamGigJobs().first;
      if (!mounted) return;
      setState(() {
        _summary = _buildSummary(txs, jobs);
        _csv = _buildCsv(txs);
        _toDelete = _findDuplicates(txs);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  static String _m(double v) => v.toStringAsFixed(2);

  static String _d(DateTime d) =>
      d.year.toString() +
      '-' +
      d.month.toString().padLeft(2, '0') +
      '-' +
      d.day.toString().padLeft(2, '0');

  static String _q(String s) => '"' + s.replaceAll('"', '""') + '"';

  String _buildSummary(List<Transaction> txs, List<GigJob> jobs) {
    final b = StringBuffer();
    b.writeln('HAVEN DATA CHECK (read-only, from Firestore)');
    b.writeln('Generated: ' + DateTime.now().toIso8601String());
    b.writeln('Transactions: ' + txs.length.toString());
    b.writeln('');

    double inc = 0;
    double exp = 0;
    final months = <int, List<double>>{};
    for (final t in txs) {
      final k = t.date.year * 100 + t.date.month;
      final m = months.putIfAbsent(k, () => [0.0, 0.0, 0.0]);
      if (t.isIncome) {
        inc += t.amount;
        m[0] += t.amount;
      } else {
        exp += t.amount;
        m[1] += t.amount;
      }
      m[2] += 1;
    }
    b.writeln('MONTH | INCOME | EXPENSE | NET | RUNNING | COUNT');
    double cum = 0;
    final keys = months.keys.toList()..sort();
    for (final k in keys) {
      final m = months[k]!;
      final net = m[0] - m[1];
      cum += net;
      b.writeln((k ~/ 100).toString() +
          '-' +
          (k % 100).toString().padLeft(2, '0') +
          ' | ' +
          _m(m[0]) +
          ' | ' +
          _m(m[1]) +
          ' | ' +
          _m(net) +
          ' | ' +
          _m(cum) +
          ' | ' +
          m[2].toInt().toString());
    }
    b.writeln('ALL TIME | ' + _m(inc) + ' | ' + _m(exp) + ' | ' + _m(inc - exp));

    final byGig = <String, List<Transaction>>{};
    final byKey = <String, List<Transaction>>{};
    for (final t in txs) {
      final g = t.gigIncomeId;
      if (g != null && g.isNotEmpty) {
        byGig.putIfAbsent(g, () => []).add(t);
      }
      final key = _d(t.date) +
          '|' +
          _m(t.amount) +
          '|' +
          (t.isIncome ? 'in' : 'out') +
          '|' +
          t.description.trim().toLowerCase();
      byKey.putIfAbsent(key, () => []).add(t);
    }

    String rows(List<Transaction> list) => list
        .map((t) => t.id + ' ' + _d(t.date) + ' ' + _m(t.amount))
        .join('; ');

    b.writeln('');
    b.writeln('DUPLICATE CHECK 1: same gigIncomeId more than once');
    var n1 = 0;
    byGig.forEach((g, list) {
      if (list.length > 1 && n1 < 40) {
        n1++;
        b.writeln(g + ' x' + list.length.toString() + ' -> ' + rows(list));
      }
    });
    if (n1 == 0) b.writeln('none');

    b.writeln('');
    b.writeln('DUPLICATE CHECK 2: same date + amount + type + description');
    var n2 = 0;
    byKey.forEach((k, list) {
      if (list.length > 1 && n2 < 40) {
        n2++;
        b.writeln(k + ' x' + list.length.toString() + ' -> ' + rows(list));
      }
    });
    if (n2 == 0) b.writeln('none');

    b.writeln('');
    b.writeln('LARGEST 15 INCOME ROWS');
    final incomes = txs.where((t) => t.isIncome).toList()
      ..sort((a, c) => c.amount.compareTo(a.amount));
    for (final t in incomes.take(15)) {
      b.writeln(_d(t.date) +
          ' | ' +
          _m(t.amount) +
          ' | ' +
          t.category +
          ' | ' +
          t.description);
    }

    b.writeln('');
    b.writeln('INCOME BY CATEGORY');
    final cats = <String, double>{};
    for (final t in incomes) {
      cats[t.category] = (cats[t.category] ?? 0) + t.amount;
    }
    final catKeys = cats.keys.toList()
      ..sort((a, c) => cats[c]!.compareTo(cats[a]!));
    for (final c in catKeys) {
      b.writeln(c + ' | ' + _m(cats[c]!));
    }

    b.writeln('');
    b.writeln('GIG JOBS: ' + jobs.length.toString());
    var missing = 0;
    for (final j in jobs) {
      final linked = txs.where((t) => t.gigIncomeId == j.id).length;
      if (linked == 0 && j.net > 0) {
        missing++;
        if (missing <= 30) {
          b.writeln('NO TRANSACTION: ' +
              j.id +
              ' ' +
              _d(j.date) +
              ' ' +
              j.platform +
              ' net ' +
              _m(j.net));
        }
      }
    }
    b.writeln('Gig jobs with net > 0 and no transaction: ' + missing.toString());
    return b.toString();
  }

  String _buildCsv(List<Transaction> txs) {
    final sorted = List<Transaction>.from(txs)
      ..sort((a, c) => a.date.compareTo(c.date));
    final b = StringBuffer();
    b.writeln('date,type,amount,category,description,place,id,gigIncomeId');
    for (final t in sorted) {
      b.writeln(_d(t.date) +
          ',' +
          (t.isIncome ? 'income' : 'expense') +
          ',' +
          _m(t.amount) +
          ',' +
          _q(t.category) +
          ',' +
          _q(t.description) +
          ',' +
          _q(t.place) +
          ',' +
          _q(t.id) +
          ',' +
          _q(t.gigIncomeId ?? ''));
    }
    return b.toString();
  }

  Future<void> _copy(String label, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(label + ' copied - paste it into the chat')));
  }

  static List<Transaction> _findDuplicates(List<Transaction> txs) {
    final byKey = <String, List<Transaction>>{};
    for (final t in txs) {
      final key = _d(t.date) +
          '|' +
          _m(t.amount) +
          '|' +
          (t.isIncome ? 'in' : 'out') +
          '|' +
          t.description.trim().toLowerCase();
      byKey.putIfAbsent(key, () => []).add(t);
    }
    final toDelete = <Transaction>[];
    byKey.forEach((k, list) {
      if (list.length > 1) {
        list.sort((a, b) => a.id.compareTo(b.id));
        toDelete.addAll(list.sublist(1));
      }
    });
    return toDelete;
  }

  Future<void> _confirmDelete() async {
    final toDelete = _toDelete;
    if (toDelete.isEmpty) return;
    final total = toDelete.fold<double>(0, (s, t) => s + t.amount);
    final lines = toDelete
        .map((t) =>
            _d(t.date) + ' | ' + _m(t.amount) + ' | ' + t.description.trim())
        .join('\n');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${toDelete.length} duplicates?'),
        content: SingleChildScrollView(
          child: Text(
            'These will be permanently deleted from Firestore:\n\n' +
                lines +
                '\n\nTotal: \$' +
                _m(total),
          ),
        ),
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
    if (confirmed == true) await _deleteDuplicates();
  }

  Future<void> _deleteDuplicates() async {
    final toDelete = List<Transaction>.from(_toDelete);
    if (toDelete.isEmpty) return;
    setState(() => _deleting = true);
    try {
      final fs = FirestoreService();
      for (final t in toDelete) {
        await fs.deleteTransaction(t.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${toDelete.length} duplicates')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final csv = _csv;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text('Reports & Data Check')),
      body: _error != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText('Could not load: ' + _error!,
                  style: const TextStyle(color: Colors.redAccent)))
          : (summary == null || csv == null)
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(
                          child: ElevatedButton.icon(
                              onPressed: () => _copy('Summary', summary),
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy summary'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: ElevatedButton.icon(
                              onPressed: () => _copy('All rows', csv),
                              icon: const Icon(Icons.table_rows),
                              label: const Text('Copy all rows'))),
                    ]),
                  ),
                  if (_toDelete.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _deleting ? null : _confirmDelete,
                          icon: const Icon(Icons.delete_forever),
                          label: Text(_deleting
                              ? 'Deleting...'
                              : 'Remove duplicates (${_toDelete.length})'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                        ),
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(summary,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'monospace',
                              fontSize: 12)),
                    ),
                  ),
                ]),
    );
  }
}
