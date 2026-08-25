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

  // Parsed data
  String _merchant = '';
  String _parsedDescription = '';
  double _parsedAmount = 0.0;
  DateTime _parsedDate = DateTime.now();
  List<String> _lineItems = [];

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

    // Try to find merchant (first line that looks like a store name)
    if (lines.isNotEmpty) {
      _merchant = lines
          .firstWhere(
            (l) =>
                !l.contains(RegExp(r'\d+\.\d{2}')) &&
                !l.contains(RegExp(r'\d{1,2}/\d{1,2}/\d{4}')) &&
                !l.contains(
                    RegExp(r'TOTAL|BALANCE|TAX|SALE', caseSensitive: false)),
            orElse: () => lines.first,
          )
          .trim();
      if (_merchant.length > 40) {
        _merchant = _merchant.substring(0, 40) + '...';
      }
    }

    // Try to find total amount
    final amountRegex = RegExp(
        r'(?:TOTAL|BALANCE|AMOUNT|TOTAL\s*PURCHASE)[\s:]*\$?(\d+\.\d{2})',
        caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch != null) {
      _parsedAmount = double.tryParse(amountMatch.group(1)!) ?? 0.0;
    } else {
      // Fallback: find any amount that looks like a total
      final fallbackRegex = RegExp(r'(?<!\.)\b(\d+\.\d{2})\b(?!\.)');
      final matches = fallbackRegex.allMatches(text);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        _parsedAmount = double.tryParse(lastMatch.group(1)!) ?? 0.0;
      }
    }

    // Try to find date
    final dateRegex = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{4})');
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      try {
        // Try various formats
        var dateStr = dateMatch.group(1)!;
        if (dateStr.contains('-')) {
          _parsedDate = DateFormat('yyyy-MM-dd').parse(dateStr);
        } else {
          _parsedDate = DateFormat('M/d/yyyy').parse(dateStr);
        }
      } catch (_) {}
    }

    // Find line items (between header and total)
    // For now, just use first few lines as description
    if (lines.isNotEmpty) {
      final descLines = lines.where((l) =>
          !l.contains(RegExp(r'\d+\.\d{2}')) &&
          !l.contains(RegExp(r'\d{1,2}/\d{1,2}/\d{4}')) &&
          !l.contains(RegExp(r'TOTAL|BALANCE|TAX|SALE|SUB TOTAL',
              caseSensitive: false)));
      _parsedDescription = descLines.take(3).join(' ');
      if (_parsedDescription.isEmpty) {
        _parsedDescription = _merchant;
      }
      if (_parsedDescription.length > 60) {
        _parsedDescription = _parsedDescription.substring(0, 60) + '...';
      }
    }

    // Line items for display
    _lineItems = lines
        .where((l) =>
            l.contains(RegExp(r'\d+\.\d{2}')) &&
            !l.contains(RegExp(r'TOTAL|BALANCE', caseSensitive: false)))
        .take(5)
        .toList();
  }

  void _showConfirmDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final descriptionController = TextEditingController(
      text: _parsedDescription.isNotEmpty ? _parsedDescription : _merchant,
    );
    final amountController = TextEditingController(
      text: _parsedAmount > 0 ? _parsedAmount.toStringAsFixed(2) : '',
    );
    DateTime selectedDate = _parsedDate;
    String selectedCategory = 'Food';
    TransactionType selectedType = TransactionType.expense;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Merchant preview
                if (_merchant.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
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
                    DropdownMenuItem(value: 'Food', child: Text('Food')),
                    DropdownMenuItem(value: 'Salary', child: Text('Salary')),
                    DropdownMenuItem(value: 'Farm', child: Text('Farm')),
                    DropdownMenuItem(
                        value: 'Utilities', child: Text('Utilities')),
                    DropdownMenuItem(value: 'Rent', child: Text('Rent')),
                    DropdownMenuItem(
                        value: 'Insurance', child: Text('Insurance')),
                    DropdownMenuItem(value: 'Loan', child: Text('Loan')),
                    DropdownMenuItem(
                        value: 'Subscriptions', child: Text('Subscriptions')),
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
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields correctly'),
                      backgroundColor: Colors.red,
                    ),
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
          // ✅ Save button – always visible
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _showConfirmDialog(context),
            tooltip: 'Create Transaction',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.imagePath),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            if (_isProcessing) ...[
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Recognizing text...'),
                  ],
                ),
              ),
            ],

            if (!_isProcessing && _extractedText.isNotEmpty) ...[
              // ✅ Clean display – parsed data
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Merchant
                    if (_merchant.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.store,
                              size: 16, color: HavenColors.muted),
                          const SizedBox(width: 8),
                          Text(
                            _merchant,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: HavenColors.dark,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                    ],
                    // Extracted fields in a clean grid
                    _buildInfoRow(
                        'Amount',
                        _parsedAmount > 0
                            ? '\$${_parsedAmount.toStringAsFixed(2)}'
                            : 'Not found'),
                    _buildInfoRow(
                        'Date', DateFormat('MMM d, yyyy').format(_parsedDate)),
                    _buildInfoRow(
                        'Description',
                        _parsedDescription.isNotEmpty
                            ? _parsedDescription
                            : 'Not found'),
                    if (_lineItems.isNotEmpty) ...[
                      const Divider(),
                      const Text(
                        'Items:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: HavenColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._lineItems.take(3).map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              item.trim(),
                              style: const TextStyle(fontSize: 13),
                            ),
                          )),
                      if (_lineItems.length > 3)
                        Text(
                          '+ ${_lineItems.length - 3} more items',
                          style: TextStyle(
                            fontSize: 12,
                            color: HavenColors.muted,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Raw text expandable
              ExpansionTile(
                title: const Text(
                  'Show raw text',
                  style: TextStyle(
                    fontSize: 14,
                    color: HavenColors.muted,
                  ),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _extractedText,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Save button (also at bottom)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showConfirmDialog(context),
                  icon: const Icon(Icons.save),
                  label: const Text('Create Transaction'),
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
            ],

            if (!_isProcessing && _extractedText.isEmpty) ...[
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No text found.',
                      style: TextStyle(color: HavenColors.muted),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Tap the Save icon in the top-right corner to manually create a transaction.',
                      style: TextStyle(color: HavenColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
