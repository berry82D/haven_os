// lib/features/home/widgets/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/services/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏡 Home'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Morning Briefing
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      appState.briefing,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    // Health Score
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Health Score: ${appState.healthScore.score}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${appState.healthScore.level})',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    if (appState.healthScore.message.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        appState.healthScore.message,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Quick Stats
            const Text(
              '📊 Quick Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(Icons.attach_money, 'Balance', '\$0'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(Icons.pets, 'Animals', '0'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(Icons.receipt, 'Bills', '0'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(Icons.checklist, 'Tasks', '0'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Quick action hint
            const Text(
              '💡 Use the bottom tabs to navigate: CFO, Homestead, Haven',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal.shade700, size: 32),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
