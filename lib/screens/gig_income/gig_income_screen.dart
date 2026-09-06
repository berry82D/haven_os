// lib/screens/gig_income/gig_income_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:haven_os/models/gig_income.dart';
import 'package:haven_os/services/app_state.dart';

class GigIncomeScreen extends StatelessWidget {
  const GigIncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Gig Income'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final items = List<GigIncome>.from(appState.myGigIncomes)
            ..sort((a, b) => b.date.compareTo(a.date));

          final now = DateTime.now();
          final monthItems = items
              .where(
                  (g) => g.date.year == now.year && g.date.month == now.month)
              .toList();
          final monthTotal =
              monthItems.fold<double>(0, (s, g) => s + g.totalAmount);
          final monthMiles = monthItems.fold<double>(0, (s, g) => s + g.miles);
          final monthAvgPayPerMile = monthMiles > 0
              ? monthItems.fold<double>(0, (s, g) => s + g.totalPay) /
                  monthMiles
              : 0.0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This month (${DateFormat('MMM yyyy').format(now)})',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryChip(
                                label: 'Total',
                                value: '\$${monthTotal.toStringAsFixed(2)}',
                              ),
                            ),
                            Expanded(
                              child: _SummaryChip(
                                label: 'Miles',
                                value: monthMiles.toStringAsFixed(1),
                              ),
                            ),
                            Expanded(
                              child: _SummaryChip(
                                label: '\$/mi',
                                value: monthAvgPayPerMile.toStringAsFixed(2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'No gig entries yet.\nTap + to add DoorDash, Uber, Spark…',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final g = items[index];
                          return Card(
                            color: const Color(0xFF1E1E1E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                '${g.platformName}  ${g.formattedTotal}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${g.formattedDate}'
                                '  •  ${g.miles.toStringAsFixed(1)} mi'
                                '  •  \$${g.payPerMile.toStringAsFixed(2)}/mi'
                                '  •  tip ${g.tipPercent.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.tealAccent, size: 20),
                                    onPressed: () => _openEditor(
                                      context,
                                      appState,
                                      existing: g,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.redAccent, size: 20),
                                    onPressed: () =>
                                        _confirmDelete(context, appState, g),
                                  ),
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
        backgroundColor: Colors.tealAccent[700],
        onPressed: () {
          final appState = context.read<AppState>();
          _openEditor(context, appState);
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState appState, GigIncome g) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            const Text('Delete entry?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove ${g.platformName} ${g.formattedTotal} on ${g.formattedDate}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appState.deleteGigIncome(g.id);
              Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _openEditor(
    BuildContext context,
    AppState appState, {
    GigIncome? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _GigIncomeEditor(
            existing: existing,
            onSave: (income) {
              if (existing == null) {
                appState.addGigIncome(income);
              } else {
                appState.updateGigIncome(income);
              }
              Navigator.pop(ctx);
            },
          ),
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.tealAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _GigIncomeEditor extends StatefulWidget {
  final GigIncome? existing;
  final void Function(GigIncome income) onSave;

  const _GigIncomeEditor({
    required this.existing,
    required this.onSave,
  });

  @override
  State<_GigIncomeEditor> createState() => _GigIncomeEditorState();
}

class _GigIncomeEditorState extends State<_GigIncomeEditor> {
  late GigPlatform _platform;
  late DateTime _date;
  final _baseCtrl = TextEditingController();
  final _tipsCtrl = TextEditingController();
  final _bonusCtrl = TextEditingController();
  final _milesCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _platform = e?.platform ?? GigPlatform.doordash;
    _date = e?.date ?? DateTime.now();
    _baseCtrl.text = e != null ? e.basePay.toStringAsFixed(2) : '';
    _tipsCtrl.text = e != null ? e.tips.toStringAsFixed(2) : '';
    _bonusCtrl.text = e != null ? e.bonus.toStringAsFixed(2) : '';
    _milesCtrl.text = e != null ? e.miles.toStringAsFixed(1) : '';
    _mileageCtrl.text = e != null ? e.mileage.toStringAsFixed(2) : '';
    _notesCtrl.text = e?.notes ?? '';
  }

  @override
  void dispose() {
    _baseCtrl.dispose();
    _tipsCtrl.dispose();
    _bonusCtrl.dispose();
    _milesCtrl.dispose();
    _mileageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0.0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final appState = context.read<AppState>();
    final user = appState.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No signed-in user. Sign in first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final base = _parse(_baseCtrl);
    final tips = _parse(_tipsCtrl);
    final bonus = _parse(_bonusCtrl);
    final total = base + tips + bonus;

    if (total <= 0 && _parse(_milesCtrl) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least base pay, tips, or bonus.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final income = GigIncome(
      id: widget.existing?.id,
      userId: user.id,
      householdId: user.householdId,
      date: _date,
      platform: _platform,
      basePay: base,
      tips: tips,
      bonus: bonus,
      miles: _parse(_milesCtrl),
      mileage: _parse(_mileageCtrl),
      totalAmount: total,
      notes: _notesCtrl.text.trim(),
      transactionId: widget.existing?.transactionId ?? '',
    );

    widget.onSave(income);
  }

  @override
  Widget build(BuildContext context) {
    final base = _parse(_baseCtrl);
    final tips = _parse(_tipsCtrl);
    final bonus = _parse(_bonusCtrl);
    final total = base + tips + bonus;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.existing == null ? 'Add gig income' : 'Edit gig income',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<GigPlatform>(
            initialValue: _platform,
            dropdownColor: const Color(0xFF2A2A2A),
            decoration: const InputDecoration(
              labelText: 'Platform',
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(color: Colors.white),
            items: GigPlatform.values
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.toString().split('.').last),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _platform = v);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date', style: TextStyle(color: Colors.white70)),
            subtitle: Text(
              DateFormat('MMM dd, yyyy').format(_date),
              style: const TextStyle(color: Colors.white),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.tealAccent),
              onPressed: _pickDate,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _numField(_baseCtrl, 'Base pay',
                    onChanged: (_) => setState(() {})),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numField(_tipsCtrl, 'Tips',
                    onChanged: (_) => setState(() {})),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _numField(_bonusCtrl, 'Bonus',
                    onChanged: (_) => setState(() {})),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numField(_milesCtrl, 'Miles'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _numField(_mileageCtrl, 'Mileage \$ (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Total: \$${total.toStringAsFixed(2)}  (base + tips + bonus)',
            style: const TextStyle(
              color: Colors.tealAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent[700],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              widget.existing == null ? 'Save' : 'Update',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField(
    TextEditingController ctrl,
    String label, {
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
