// lib/features/haven_central/scan_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> scanReceipt() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final inputImage = InputImage.fromFile(File(image.path));
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);
    await _textRecognizer.close();

    return recognizedText.text;
  }

  static Map<String, dynamic> parseText(String text) {
    final amountRegex = RegExp(r'\$?(\d+\.\d{2})');
    final dateRegex = RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4})');

    final amountMatch = amountRegex.firstMatch(text);
    final dateMatch = dateRegex.firstMatch(text);

    return {
      'amount':
          amountMatch != null ? double.tryParse(amountMatch.group(1)!) : null,
      'date': dateMatch != null ? dateMatch.group(1) : null,
      'raw': text,
    };
  }
}
