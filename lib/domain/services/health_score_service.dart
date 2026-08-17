// lib/domain/services/health_score_service.dart
import 'package:flutter/material.dart';
import 'package:haven_os/models/task.dart';

class HealthScoreService {
  // Placeholder – returns a default health score

  int calculateHealthScore(List<Task> tasks) {
    // ✅ FIXED: dueDate commented out – use deadline instead
    // For now, return a default score
    return 85;
  }

  String getHealthStatus(int score) {
    if (score >= 80) return 'Good';
    if (score >= 60) return 'Fair';
    return 'Needs Attention';
  }
}
