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

  String _parsedDescription = '';
  double _parsedAmount = 0.0;
  DateTime _parsedDate = DateTime.now();

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
    final amountRegex = RegExp(r'(\d+\.\d{2})');
    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch != null) {
      _parsedAmount = double.tryParse(amountMatch.group(1)!) ?? 0.0;
    }

    final dateRegex = RegExp(r'(\d{1,2}/\d{1,2}/\d{4})');
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      try {
        _parsedDate = DateFormat('M/d/yyyy').parse(dateMatch.group(1)!);
      } catch (_) {}
    }

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      _parsedDescription = lines
          .firstWhere(
            (l) =>
                !l.contains(RegExp(r'\d+\.\d{2}')) &&
                !l.contains(RegExp(r'\d{1,2}/\d{1,2}/\d{4}')),
            orElse: () => lines.first,
          )
          .trim();
    }
    if (_parsedDescription.length > 50) {
      _parsedDescription = _parsedDescription.substring(0, 50) + '...';
    }
  }

  void _showConfirmDialog(BuildContext context, {bool prefill = true}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final descriptionController = TextEditingController(
      text: prefill ? _parsedDescription : '',
    );
    final amountController = TextEditingController(
      text: prefill ? _parsedAmount.toStringAsFixed(2) : '',
    );
    DateTime selectedDate = prefill ? _parsedDate : DateTime.now();
    String selectedCategory = 'Other';
    TransactionType selectedType = prefill && _parsedAmount >= 0
        ? TransactionType.income
        : TransactionType.expense;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              onPressed: () {
                Navigator.pop(context);
              },
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
          // ✅ SAVE BUTTON – ALWAYS VISIBLE
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () =>
                _showConfirmDialog(context, prefill: _extractedText.isNotEmpty),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.imagePath),
                height: 200,
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
              const Text(
                'Extracted Text:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: HavenColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  _extractedText,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showConfirmDialog(context, prefill: true),
                  icon: const Icon(Icons.save),
                  label: const Text('Create Transaction from Receipt'),
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
}
