import '../../models/animal.dart';

class FarmService {
  // No constructor

  double calculateFeedCost(List<Animal> animals) {
    return animals.fold(0.0, (sum, a) => sum + a.feedCost);
  }

  double calculateRevenue(List<Animal> animals) {
    // If you have a real revenue field, use that; otherwise placeholder.
    return animals.fold(0.0, (sum, a) => sum + (a.count * 50.0));
  }

  double calculateProfit(List<Animal> animals) {
    return calculateRevenue(animals) - calculateFeedCost(animals);
  }

  Map<String, int> countHealth(List<Animal> animals) {
    final result = {'Good': 0, 'Fair': 0, 'Poor': 0};
    for (var a in animals) {
      result[a.health] = (result[a.health] ?? 0) + 1;
    }
    return result;
  }
}
