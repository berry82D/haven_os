// lib/features/homestead/widgets/homestead_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/animal.dart';
import 'package:haven_os/services/app_state.dart';

class HomesteadScreen extends StatelessWidget {
  const HomesteadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final animals = appState.myAnimals;

    final totalAnimals = animals.fold(0, (sum, a) => sum + a.count);
    final totalFeedCost = animals.fold(0.0, (sum, a) => sum + a.feedCost);

    return Scaffold(
      backgroundColor: HavenColors.cream,
      body: RefreshIndicator(
        onRefresh: () async {
          await appState.initialize();
          appState.refresh();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Header ----
              const Text(
                'Homestead',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: HavenColors.dark,
                ),
              ),
              const SizedBox(height: 16),

              // ---- Stats Cards ----
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$totalAnimals',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: HavenColors.green,
                            ),
                          ),
                          const Text(
                            'Total Animals',
                            style: TextStyle(
                              fontSize: 12,
                              color: HavenColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '\$${totalFeedCost.toStringAsFixed(0)}/mo',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: HavenColors.green,
                            ),
                          ),
                          const Text(
                            'Feed Cost',
                            style: TextStyle(
                              fontSize: 12,
                              color: HavenColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ---- Animal List ----
              if (animals.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.pets,
                        size: 60,
                        color: HavenColors.lightMuted,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No animals yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: HavenColors.dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap "Animals" on the Home screen to add your first livestock.',
                        style: TextStyle(
                          fontSize: 14,
                          color: HavenColors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: animals
                      .map((animal) => _buildAnimalCard(animal))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Animal Card ----
  Widget _buildAnimalCard(Animal animal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Emoji
            Text(
              animal.type,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${animal.count} animals · ${animal.healthStatus} · \$${animal.feedCost.toStringAsFixed(0)}/mo feed',
                    style: const TextStyle(
                      fontSize: 12,
                      color: HavenColors.muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Health indicator (no interaction)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    _getHealthColor(animal.healthStatus).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                animal.healthStatus,
                style: TextStyle(
                  fontSize: 12,
                  color: _getHealthColor(animal.healthStatus),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getHealthColor(String health) {
    switch (health.toLowerCase()) {
      case 'good':
        return Colors.green;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
