import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/services/app_state.dart';

class TransactionsTab extends StatelessWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final transactions = appState.myTransactions;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'All Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: transactions.isEmpty
              ? const Center(child: Text('No transactions yet'))
              : ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return _buildTransactionTile(context, tx, appState);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(
      BuildContext context, Transaction tx, AppState appState) {
    final isIncome = tx.amount > 0;
    final color = isIncome ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
          ),
        ),
        title: Text(tx.description),
        subtitle: Text(
          '${tx.date.month}/${tx.date.day}/${tx.date.year} • ${tx.category}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () =>
                  _showEditTransactionDialog(context, appState, tx),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Transaction?'),
                    content: Text('Delete "${tx.description}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          appState.deleteTransaction(tx.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Transaction deleted')),
                          );
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTransactionDialog(
      BuildContext context, AppState appState, Transaction tx) {
    final descriptionController = TextEditingController(text: tx.description);
    final amountController =
        TextEditingController(text: tx.amount.abs().toString());
    String? selectedCategory = tx.category;
    Account? selectedAccount = tx.account;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Amount', prefixText: '\$'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'Food', child: Text('Food')),
                DropdownMenuItem(value: 'Salary', child: Text('Salary')),
                DropdownMenuItem(value: 'Farm', child: Text('Farm')),
                DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => selectedCategory = value,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Account>(
              value: selectedAccount,
              decoration: const InputDecoration(labelText: 'Account'),
              items: const [
                DropdownMenuItem(value: Account.cash, child: Text('Cash')),
                DropdownMenuItem(value: Account.bank, child: Text('Bank')),
                DropdownMenuItem(value: Account.farm, child: Text('Farm')),
              ],
              onChanged: (value) => selectedAccount = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final description = descriptionController.text.trim();
              final amount = double.tryParse(amountController.text);
              if (description.isNotEmpty &&
                  amount != null &&
                  selectedCategory != null &&
                  selectedAccount != null) {
                final isIncome = tx.amount > 0;
                appState.updateTransaction(
                  Transaction(
                    id: tx.id,
                    description: description,
                    amount: isIncome ? amount : -amount,
                    date: tx.date,
                    category: selectedCategory!,
                    account: selectedAccount!,
                    cleared: tx.cleared,
                    userId: tx.userId,
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction updated!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
