// lib/services/farm_service.dart (or lib/domain/services/farm_service.dart)
import 'package:flutter/material.dart';

class FarmService {
  // Placeholder farm service – all methods return empty data

  int getTotalAnimals() => 0;

  double getTotalFeed() => 0.0;

  // ✅ FIXED: toString() on int values
  String getFeedStatus() {
    final total = getTotalFeed();
    return total.toStringAsFixed(2); // If you had an int, use .toString()
  }

  // Any other methods can be added here
}
