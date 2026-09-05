// lib/features/receipt_scanner/receipt_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import '../../models/transaction.dart';

class ReceiptScannerScreen extends StatefulWidget {
  final void Function(Transaction) onSaveTransaction;

  const ReceiptScannerScreen({
    super.key,
    required this.onSaveTransaction,
  });

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  XFile? _imageFile;
  String _extractedText = 'Scan a receipt to extract text.';
  bool _isScanning = false;

  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<String> _groceryItems = [];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;
    setState(() {
      _imageFile = pickedFile;
      _extractedText = 'Scanning...';
    });
    await _scanReceipt(pickedFile);
  }

  Future<void> _scanReceipt(XFile imageFile) async {
    setState(() => _isScanning = true);
    try {
      final inputImage = InputImage.fromFile(File(imageFile.path));
      final textDetector = TextRecognizer();
      final RecognizedText recognizedText =
          await textDetector.processImage(inputImage);
      await textDetector.close();
      String fullText = recognizedText.text;
      setState(() {
        _extractedText = fullText;
        _isScanning = false;
      });
      _parseReceiptText(fullText);
    } catch (e) {
      setState(() {
        _extractedText = 'Error scanning: $e';
        _isScanning = false;
      });
    }
  }

  void _parseReceiptText(String text) {
    RegExp amountRegex = RegExp(r'\$?(\d+\.\d{2})');
    final matches = amountRegex.allMatches(text);
    if (matches.isNotEmpty) {
      final lastMatch = matches.last;
      String amountStr = lastMatch.group(1) ?? '';
      if (amountStr.isNotEmpty) {
        double amount = double.tryParse(amountStr) ?? 0.0;
        if (amount > 0) {
          _amountCtrl.text = amount.toStringAsFixed(2);
        }
      }
    }

    List<String> lines = text.split('\n');
    for (String line in lines) {
      String trimmed = line.trim();
      if (trimmed.isNotEmpty && trimmed.length > 3 && trimmed.length < 50) {
        _descCtrl.text = trimmed;
        break;
      }
    }

    _groceryItems.clear();
    for (String line in lines) {
      String trimmed = line.trim();
      if (trimmed.isNotEmpty && RegExp(r'\d+\.\d{2}').hasMatch(trimmed)) {
        if (!trimmed.contains('TOTAL') &&
            !trimmed.contains('Total') &&
            !trimmed.contains('total')) {
          _groceryItems.add(trimmed);
        }
      }
    }
    if (_groceryItems.length > 5) {
      _groceryItems = _groceryItems.sublist(0, 5);
    }
    setState(() {});
  }

  void _saveTransaction() {
    final description = _descCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (description.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description and amount')),
      );
      return;
    }

    // ✅ CORRECT: No 'id' or 'name' – auto-generates
    final newTx = Transaction(
      amount: amount,
      category: 'Groceries',
      date: _selectedDate,
      note: 'Scanned from receipt\n${_groceryItems.join('\n')}',
      type: TransactionType.expense,
      description: description,
      userId: '',
      account: Account('default'),
      cleared: ClearedStatus.uncleared,
    );

    widget.onSaveTransaction(newTx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📸 Scan Receipt'),
        backgroundColor: Colors.teal.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isScanning
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('📸 Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isScanning
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('🖼️ Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_imageFile != null) ...[
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_imageFile!.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Extracted Text:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _extractedText,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_groceryItems.isNotEmpty) ...[
                const Text(
                  '🛒 Detected Items:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: _groceryItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                '📋 Confirm / Edit Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (e.g., Store name)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (\$)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedDate
                                .toLocal()
                                .toString()
                                .split(' ')[0]),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveTransaction,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    '✅ Save as Grocery Expense',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
