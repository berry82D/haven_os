// lib/features/scan/presentation/preview_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:intl/intl.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  String _extractedText = '';
  bool _isProcessing = true;
  final TextRecognizer _textRecognizer = TextRecognizer();

  // ---- Clean parsed fields ----
  String _merchant = '';
  String _description = '';
  double _amount = 0.0;
  DateTime _date = DateTime.now();
  List<String> _items = [];

  @override
  void initState() {
    super.initState();
    _recognizeText();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _recognizeText() async {
    setState(() => _isProcessing = true);
    try {
      final inputImage = InputImage.fromFile(File(widget.imagePath));
      final recognizedText = await _textRecognizer.processImage(inputImage);
      setState(() {
        _extractedText = recognizedText.text;
        _isProcessing = false;
        _parseExtractedText(_extractedText);
      });
    } catch (e) {
      setState(() {
        _extractedText = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  void _parseExtractedText(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    // ---- Merchant ----
    final merchantCandidates = lines.where((l) =>
        l.trim().toUpperCase() == l.trim() &&
        !l.contains(RegExp(r'\d+\.\d{2}')) &&
        !l.contains(RegExp(r'\d{1,2}/\d{1,2}/\d{4}')) &&
        l.length > 3);
    _merchant = merchantCandidates.isNotEmpty
        ? merchantCandidates.first.trim()
        : 'Unknown Store';
    if (_merchant.length > 40) _merchant = _merchant.substring(0, 40) + '...';

    // ---- Date ----
    final dateRegex = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{4})');
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      try {
        final dateStr = dateMatch.group(1)!;
        if (dateStr.contains('-')) {
          _date = DateFormat('yyyy-MM-dd').parse(dateStr);
        } else {
          _date = DateFormat('M/d/yyyy').parse(dateStr);
        }
      } catch (_) {}
    }

    // ---- Amount ----
    final amountRegex = RegExp(
      r'(?:TOTAL|BALANCE|AMOUNT|TOTAL\s*PURCHASE)[\s:]*\$?(\d+\.\d{2})',
      caseSensitive: false,
    );
    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch != null) {
      _amount = double.tryParse(amountMatch.group(1)!) ?? 0.0;
    } else {
      final fallbackRegex = RegExp(r'(?<!\.)\b(\d+\.\d{2})\b(?!\.)');
      final matches = fallbackRegex.allMatches(text);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        _amount = double.tryParse(lastMatch.group(1)!) ?? 0.0;
      }
    }

    // ---- Items ----
    final itemRegex = RegExp(r'^(.+?)\s+(\d+\.\d{2})$');
    _items = lines
        .where((l) => itemRegex.hasMatch(l.trim()))
        .map((l) => l.trim())
        .take(5)
        .toList();

    // ---- Description ----
    _description = _merchant;
    if (_items.isNotEmpty) {
      _description += ' • ${_items.length} items';
    }
    if (_description.length > 40) {
      _description = _description.substring(0, 40) + '...';
    }
  }

  void _showConfirmDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    final descriptionController = TextEditingController(text: _description);
    final amountController = TextEditingController(
      text: _amount > 0 ? _amount.toStringAsFixed(2) : '',
    );
    DateTime selectedDate = _date;
    String selectedCategory = 'Groceries';
    TransactionType selectedType = TransactionType.expense;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Merchant badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.store, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _merchant,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                        value: TransactionType.income, label: Text('Income')),
                    ButtonSegment(
                        value: TransactionType.expense, label: Text('Expense')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (selection) {
                    setState(() => selectedType = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Groceries', child: Text('Groceries')),
                    DropdownMenuItem(value: 'Food', child: Text('Food')),
                    DropdownMenuItem(
                        value: 'Dining Out', child: Text('Dining Out')),
                    DropdownMenuItem(value: 'Salary', child: Text('Salary')),
                    DropdownMenuItem(value: 'Farm', child: Text('Farm')),
                    DropdownMenuItem(
                        value: 'Utilities', child: Text('Utilities')),
                    DropdownMenuItem(value: 'Rent', child: Text('Rent')),
                    DropdownMenuItem(
                        value: 'Insurance', child: Text('Insurance')),
                    DropdownMenuItem(value: 'Loan', child: Text('Loan')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Date: '),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null)
                          setState(() => selectedDate = picked);
                      },
                      child:
                          Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                    ),
                  ],
                ),
                // ---- Items preview ----
                if (_items.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Items:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  ..._items.take(3).map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(item, style: const TextStyle(fontSize: 13)),
                      )),
                  if (_items.length > 3)
                    Text(
                      '+ ${_items.length - 3} more',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final desc = descriptionController.text.trim();
                final amount = double.tryParse(amountController.text.trim());
                if (desc.isNotEmpty && amount != null && amount > 0) {
                  final finalAmount =
                      selectedType == TransactionType.income ? amount : -amount;
                  appState.addTransaction(
                    Transaction(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      description: desc,
                      amount: finalAmount,
                      date: selectedDate,
                      category: selectedCategory,
                      type: selectedType,
                      userId: appState.currentUser!.id,
                    ),
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Transaction saved!'),
                        backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please fill all fields'),
                        backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: HavenColors.dark,
        actions: [
          // ✅ Save button always visible
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isProcessing ? null : () => _showConfirmDialog(context),
            tooltip: 'Create Transaction',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Reading receipt...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.imagePath),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- CLEAN DATA CARD ----
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Extracted Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: HavenColors.dark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Store', _merchant),
                        _buildInfoRow(
                            'Amount',
                            _amount > 0
                                ? '\$${_amount.toStringAsFixed(2)}'
                                : 'Not found'),
                        _buildInfoRow(
                            'Date', DateFormat('MMM d, yyyy').format(_date)),
                        _buildInfoRow('Items', '${_items.length} found'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- Add Transaction button ----
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showConfirmDialog(context),
                      icon: const Icon(Icons.save),
                      label: const Text('Add Transaction'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HavenColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),

                  // ---- Raw text hidden by default ----
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text(
                      'Show raw text',
                      style: TextStyle(fontSize: 14, color: HavenColors.muted),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _extractedText,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: HavenColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: HavenColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
