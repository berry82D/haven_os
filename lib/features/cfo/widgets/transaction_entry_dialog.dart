import 'package:flutter/material.dart';

class TransactionEntryDialog extends StatelessWidget {
  const TransactionEntryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      title: Text('Add Transaction'),
      content: Text('Transaction entry coming soon...'),
      actions: [
        TextButton(
          onPressed: null,
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: null,
          child: Text('Save'),
        ),
      ],
    );
  }
}
