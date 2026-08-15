import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/services/app_state.dart';

class TransactionEntryDialog extends StatefulWidget {
  final Transaction? transaction;
  const TransactionEntryDialog({super.key, this.transaction});

  @override
  State<TransactionEntryDialog> createState() => _TransactionEntryDialogState();
}

class _TransactionEntryDialogState extends State<TransactionEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  String _category = 'Other';
  Account _account = Account.bank;
  ClearedStatus _cleared = ClearedStatus.pending;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _descriptionController = TextEditingController(text: tx?.description ?? '');
    _amountController =
        TextEditingController(text: tx?.amount.abs().toString() ?? '');
    _selectedDate = tx?.date ?? DateTime.now();
    if (tx != null) {
      _category = tx.category;
      _account = tx.account;
      _cleared = tx.cleared;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final description = _descriptionController.text.trim();
    final isIncome = (widget.transaction?.amount ?? amount) >= 0;

    final tx = Transaction(
      id: widget.transaction?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      amount: isIncome ? amount.abs() : -amount.abs(),
      date: _selectedDate,
      category: _category,
      account: _account,
      cleared: _cleared,
      userId:
          Provider.of<AppState>(context, listen: false).currentUser?.id ?? '',
    );

    final appState = Provider.of<AppState>(context, listen: false);
    if (widget.transaction == null) {
      appState.addTransaction(tx);
    } else {
      appState.updateTransaction(tx);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.transaction == null ? 'Add Transaction' : 'Edit Transaction'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                    labelText: 'Amount', prefixText: '\$'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                items: _categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              DropdownButtonFormField<Account>(
                value: _account,
                items: Account.values
                    .map((acc) => DropdownMenuItem(
                          value: acc,
                          child: Text(acc.name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _account = val!),
                decoration: const InputDecoration(labelText: 'Account'),
              ),
              DropdownButtonFormField<ClearedStatus>(
                value: _cleared,
                items: ClearedStatus.values
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _cleared = val!),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HavenColors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _categories = [
    'Food',
    'Transport',
    'Housing',
    'Utilities',
    'Entertainment',
    'Healthcare',
    'Education',
    'Farm',
    'Other',
  ];
}
