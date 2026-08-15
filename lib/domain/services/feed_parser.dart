import 'package:haven_os/models/feed_delivery.dart';

class FeedParser {
  static FeedDelivery? parseBrooksTicket(String rawText, {String userId = ''}) {
    try {
      final datePattern = RegExp(r'(\d{2}/\d{2}/\d{4})');
      final dateMatch = datePattern.firstMatch(rawText);
      final date =
          dateMatch != null ? _parseDate(dateMatch.group(1)!) : DateTime.now();

      final weightPattern =
          RegExp(r'NET\s*(\d+)\s*lb|NT\s*(\d+)|(\d+)\s*lb\s*NET');
      final weightMatch = weightPattern.firstMatch(rawText);
      double? weight;
      if (weightMatch != null) {
        weight = double.tryParse(weightMatch.group(1) ??
            weightMatch.group(2) ??
            weightMatch.group(3) ??
            '0');
      }
      if (weight == null || weight == 0) {
        final lbPattern = RegExp(r'(\d+)\s*lb');
        final matches = lbPattern.allMatches(rawText);
        if (matches.isNotEmpty) {
          final numbers =
              matches.map((m) => double.tryParse(m.group(1)!) ?? 0).toList();
          weight = numbers.isNotEmpty
              ? numbers.reduce((a, b) => a > b ? a : b)
              : null;
        }
      }

      final costPattern = RegExp(r'\$?(\d+\.\d{2})');
      final costMatches = costPattern.allMatches(rawText);
      double? cost;
      if (costMatches.isNotEmpty) {
        final amounts =
            costMatches.map((m) => double.tryParse(m.group(1)!) ?? 0).toList();
        cost = amounts.reduce((a, b) => a > b ? a : b);
      }

      String vendor = 'Brooks Contractor';
      if (rawText.contains('Brooks'))
        vendor = 'Brooks Contractor';
      else if (rawText.contains('Cargill'))
        vendor = 'Cargill';
      else if (rawText.contains('Purina'))
        vendor = 'Purina';
      else if (rawText.contains('ADM')) vendor = 'ADM';

      String materialType = 'Field Corn';
      if (rawText.contains('Corn'))
        materialType = 'Field Corn';
      else if (rawText.contains('Soy'))
        materialType = 'Soybean Meal';
      else if (rawText.contains('Complete'))
        materialType = 'Complete Feed';
      else if (rawText.contains('Mineral')) materialType = 'Mineral Mix';

      if (weight == null || weight == 0 || cost == null || cost == 0) {
        return null;
      }

      return FeedDelivery.fromTicket(
        vendor: vendor,
        fullWeight: weight,
        fullCost: cost,
        date: date,
        splitPercent: 0.5,
        userId: userId,
        materialType: materialType,
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return DateTime.now();
  }

  static String generateSampleTicket() {
    return r'''
Brooks Contractor
Weighmaster License: 123456
Driver: John Doe
Date: 08/01/2026 09:56am

GR: 12080 lb
TARE: 4000 lb
NET: 8080 lb

CWA Corn
Total: $360.00

INVALID UNLESS SIGNED
JPC Form #1234
''';
  }
}
