// lib/features/home/widgets/morning_briefing.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/services/app_state.dart';

class MorningBriefing extends StatelessWidget {
  const MorningBriefing({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final health = appState.healthScore;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sunny, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Good Morning!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              appState.briefing,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Health score display
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Health Score: ${health.score}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  health.level.isNotEmpty ? '(${health.level})' : '',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            if (health.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                health.message,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
            // ✅ FIXED: Check if issues exists and has items
            if (health.issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ ${health.issues.length} issues need attention',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
