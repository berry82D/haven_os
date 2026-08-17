// lib/features/scan/presentation/scan_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String _result = '';
  bool _isScanning = false;

  Future<void> _scan() async {
    setState(() => _isScanning = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        setState(() => _isScanning = false);
        return;
      }

      final inputImage = InputImage.fromFile(File(image.path));
      final recognizer = TextRecognizer();
      final recognizedText = await recognizer.processImage(inputImage);
      await recognizer.close();

      setState(() {
        _result = recognizedText.text;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📷 Scan'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _scan,
              icon:
                  Icon(_isScanning ? Icons.hourglass_empty : Icons.camera_alt),
              label: Text(_isScanning ? 'Scanning...' : 'Scan Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _result.isEmpty ? 'Scanned text will appear here.' : _result,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
