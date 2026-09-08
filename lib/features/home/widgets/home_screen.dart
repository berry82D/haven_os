// lib/features/home/widgets/home_screen.dart
import 'package:flutter/material.dart';
import '../../../models/transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Temporary list to hold transactions
  final List<Transaction> _transactions = [];

  // ---------- THE FORM (WITH TOGGLE INSIDE) ----------
  void _showAddTransaction(BuildContext context) {
    final _descCtrl = TextEditingController();
    final _placeCtrl = TextEditingController();
    final _amountCtrl = TextEditingController();
    final _notesCtrl = TextEditingController();
    DateTime _selectedDate = DateTime.now();

    // This is the toggle variable (true = Income, false = Expense)
    bool _isIncome = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- TOGGLE BUTTONS (Income / Expense) ----------
              Center(
                child: ToggleButtons(
                  isSelected: [_isIncome, !_isIncome],
                  onPressed: (index) {
                    setState(() {
                      _isIncome =
                          (index == 0); // true for Income, false for Expense
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: _isIncome ? Colors.green : Colors.red,
                  color: Colors.grey.shade700,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text('💰 Income'),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text('💸 Expense'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Description
              TextField(
                  controller: _descCtrl,
                  decoration: InputDecoration(labelText: 'Description')),
              SizedBox(height: 12),

              // Place
              TextField(
                  controller: _placeCtrl,
                  decoration:
                      InputDecoration(labelText: 'Place (e.g., Store name)')),
              SizedBox(height: 12),

              // Date Picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Amount
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount'),
              ),
              SizedBox(height: 12),

              // Notes
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'Notes (optional)'),
              ),
              SizedBox(height: 20),

              // Cancel / Save Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
                      if (amount <= 0 || _descCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Please enter a description and amount')),
                        );
                        return;
                      }

                      // ---------- FIXED NOTE BUILDING (No more null errors!) ----------
                      // Build the note string from Place + Notes
                      String noteText = '';
                      if (_placeCtrl.text.isNotEmpty) {
                        noteText += 'Place: ${_placeCtrl.text}\n';
                      }
                      if (_notesCtrl.text.isNotEmpty) {
                        noteText += 'Notes: ${_notesCtrl.text}';
                      }
                      // If noteText is empty, set it to null. Otherwise use it.
                      String? finalNote = noteText.isEmpty ? null : noteText;

                      // Create the transaction using the TOGGLE value (_isIncome)
                      final newTx = Transaction(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        amount: amount,
                        category: 'General',
                        date: _selectedDate,
                        note: finalNote, // <-- Perfectly safe, no errors.
                        type: _isIncome
                            ? TransactionType.income
                            : TransactionType.expense,
                        description: _descCtrl.text,
                        userId: 'user1',
                        account: Account('Default'),
                        cleared: ClearedStatus.uncleared,
                      );

                      setState(() {
                        _transactions.add(newTx);
                      });

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${_isIncome ? "Income" : "Expense"} added!')),
                      );
                    },
                    child: Text('Save'),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- THE HOME SCREEN UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Haven Central'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Household Health
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text('Household Health: ',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('90%',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ],
              ),
            ),
            SizedBox(height: 20),

            // ---------- SINGLE BUTTON ----------
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showAddTransaction(context),
                icon: Icon(Icons.add_circle_outline, size: 28),
                label: Text('Add Transaction',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Recent Transactions List
            Text('Recent Transactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              child: _transactions.isEmpty
                  ? Center(
                      child: Text(
                          'No transactions yet. Tap the big button above!',
                          style: TextStyle(color: Colors.grey.shade600)))
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final tx = _transactions[index];
                        return Material(type: MaterialType.transparency, child: ListTile(
                          title: Text(tx.description),
                          subtitle: Text(
                              '${tx.type.name} - \$${tx.amount.toStringAsFixed(2)} - ${tx.date.toLocal().toString().split(' ')[0]}'),
                          trailing: tx.type == TransactionType.income
                              ? Icon(Icons.arrow_upward, color: Colors.green)
                              : Icon(Icons.arrow_downward, color: Colors.red),
                        ),);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'CFO'),
          BottomNavigationBarItem(
              icon: Icon(Icons.agriculture), label: 'Homestead'),
          // ---------- FIXED ICON (psychology = brain) ----------
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Haven'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to tab $index (coming soon)')),
          );
        },
      ),
    );
  }
}
