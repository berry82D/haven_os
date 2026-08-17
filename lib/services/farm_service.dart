// lib/services/farm_service.dart
class FarmService {
  // Placeholder farm service – all methods return empty data

  int getTotalAnimals() => 0;

  double getTotalFeed() => 0.0;

  // ✅ FIXED: toString() on int values
  String getFeedStatus() {
    final total = getTotalFeed();
    return total.toStringAsFixed(2);
  }
}
