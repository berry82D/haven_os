// lib/features/homestead/widgets/homestead_screen.dart
import 'package:flutter/material.dart';

class HomesteadScreen extends StatelessWidget {
  const HomesteadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌾 Homestead'),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏠 Your Farm',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.pets,
                    label: 'Animals',
                    value: '0',
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    icon: Icons.grass,
                    label: 'Feed Stock',
                    value: '0 kg',
                    color: Colors.brown.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.local_shipping,
                    label: 'Deliveries',
                    value: '0',
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    icon: Icons.health_and_safety,
                    label: 'Health',
                    value: 'Good',
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '📋 Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('No recent activity'),
                subtitle: Text('Your farm is quiet right now'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '💡 Add animals, track feed, and manage deliveries',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
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
