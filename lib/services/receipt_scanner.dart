import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptScanner {
  static final ImagePicker _picker = ImagePicker();
  static final TextRecognizer _textRecognizer = TextRecognizer();

  static Future<Map<String, dynamic>?> scanReceipt() async {
    // Pick image from camera
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return null;

    final inputImage = InputImage.fromFile(File(image.path));
    final recognizedText = await _textRecognizer.processImage(inputImage);

    // Extract full text
    String fullText = '';
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        fullText += line.text + '\n';
      }
    }

    // Try to find a merchant name (first line that's not "Total" etc.)
    String merchant = '';
    final lines = fullText.split('\n');
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.length > 3 &&
          !trimmed.contains('Total') &&
          !trimmed.contains('AMOUNT') &&
          !trimmed.contains('Date')) {
        merchant = trimmed;
        break;
      }
    }

    // Try to find a total (e.g., "Total: $XX.XX")
    double total = 0.0;
    final RegExp totalRegex = RegExp(
        r'(?:Total|TOTAL|Amount|AMOUNT|Due|DUE)\s*[:]?\s*\$?(\d+\.\d{2})');
    final match = totalRegex.firstMatch(fullText);
    if (match != null) {
      total = double.tryParse(match.group(1)!) ?? 0.0;
    }

    return {
      'merchant': merchant.isNotEmpty ? merchant : 'Unknown Store',
      'total': total,
      'fullText': fullText,
    };
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
