// lib/domain/services/farm_service.dart
import 'package:haven_os/models/animal.dart';

class FarmService {
  double calculateFeedCost(List<Animal> animals) {
    return animals.fold(0.0, (s, a) => s + a.feedCost);
  }

  double calculateRevenue(List<Animal> animals) {
    return animals.fold(0.0, (s, a) => s + a.revenue);
  }

  double calculateProfit(List<Animal> animals) {
    return calculateRevenue(animals) - calculateFeedCost(animals);
  }

  Map<String, int> countHealth(List<Animal> animals) {
    return {
      'Good': animals.where((a) => a.health == 'Good').length,
      'Fair': animals.where((a) => a.health == 'Fair').length,
      'Poor': animals.where((a) => a.health == 'Poor').length,
    };
  }
}
