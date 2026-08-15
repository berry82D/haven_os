import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/animal.dart';
import 'package:haven_os/services/app_state.dart';

class HomesteadScreen extends StatefulWidget {
  const HomesteadScreen({super.key});

  @override
  State<HomesteadScreen> createState() => _HomesteadScreenState();
}

class _HomesteadScreenState extends State<HomesteadScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _feedCostController = TextEditingController();
  final TextEditingController _healthController = TextEditingController();

  void _addExampleAnimals() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.addAnimal(Animal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Pigs',
      type: '🐖',
      count: 5,
      health: 'Good',
      feedCost: 150.0,
      userId: appState.currentUser?.id ?? '',
    ));
    appState.addAnimal(Animal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Chickens',
      type: '🐓',
      count: 12,
      health: 'Good',
      feedCost: 60.0,
      userId: appState.currentUser?.id ?? '',
    ));
    appState.addAnimal(Animal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Goats',
      type: '🐐',
      count: 3,
      health: 'Fair',
      feedCost: 40.0,
      userId: appState.currentUser?.id ?? '',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Example animals added!')),
    );
  }

  void _showAddAnimalDialog() {
    final appState = Provider.of<AppState>(context, listen: false);
    _nameController.clear();
    _typeController.clear();
    _countController.clear();
    _feedCostController.clear();
    _healthController.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Animal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _typeController,
                decoration:
                    const InputDecoration(labelText: 'Type (🐖, 🐓, 🐐, etc.)'),
              ),
              TextField(
                controller: _countController,
                decoration: const InputDecoration(labelText: 'Count'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _feedCostController,
                decoration: const InputDecoration(labelText: 'Feed Cost (\$)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _healthController,
                decoration:
                    const InputDecoration(labelText: 'Health (Good/Fair/Poor)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final type = _typeController.text.trim();
              final count = int.tryParse(_countController.text.trim()) ?? 0;
              final feedCost =
                  double.tryParse(_feedCostController.text.trim()) ?? 0.0;
              final health = _healthController.text.trim().isEmpty
                  ? 'Good'
                  : _healthController.text.trim();

              if (name.isEmpty || type.isEmpty || count <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              appState.addAnimal(Animal(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                type: type,
                count: count,
                health: health,
                feedCost: feedCost,
                userId: appState.currentUser?.id ?? '',
              ));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added $name!')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showHealthUpdateDialog(Animal animal) {
    final appState = Provider.of<AppState>(context, listen: false);
    final controller = TextEditingController(text: animal.health);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Update Health: ${animal.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Health Status'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updatedAnimal = Animal(
                id: animal.id,
                name: animal.name,
                type: animal.type,
                count: animal.count,
                health: controller.text.trim(),
                feedCost: animal.feedCost,
                revenue: animal.revenue,
                userId: animal.userId,
              );
              appState.updateAnimal(updatedAnimal);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${animal.name} health updated!')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final animals = appState.myAnimals;

    final totalAnimals = animals.fold(0, (sum, a) => sum + a.count);
    final totalFeedCost = animals.fold(0.0, (sum, a) => sum + a.feedCost);

    return Scaffold(
      backgroundColor: HavenColors.cream,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Homestead',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: HavenColors.dark,
              ),
            ),
            const SizedBox(height: 16),

            // Stats row – responsive with LayoutBuilder
            LayoutBuilder(
              builder: (context, constraints) {
                // If screen width is less than 400, stack stats vertically
                final isNarrow = constraints.maxWidth < 400;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isNarrow
                      ? Column(
                          children: [
                            Row(
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
                          ],
                        )
                      : Row(
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
                );
              },
            ),
            const SizedBox(height: 16),

            // Action buttons – responsive: wrap on narrow screens
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 400;
                return isNarrow
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showAddAnimalDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Animal'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HavenColors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _addExampleAnimals,
                              icon: const Icon(Icons.science, size: 18),
                              label: const Text('Example Data'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: HavenColors.muted,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showAddAnimalDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Animal'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HavenColors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _addExampleAnimals,
                              icon: const Icon(Icons.science, size: 18),
                              label: const Text('Example Data'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: HavenColors.muted,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 16),

            // Animal list (no overflow)
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
                      'Welcome to your Homestead',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: HavenColors.dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start tracking your livestock by adding your first animal.',
                      style: TextStyle(
                        fontSize: 14,
                        color: HavenColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddAnimalDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Your First Animal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HavenColors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _addExampleAnimals,
                      child: const Text('+ Add example animals'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: animals.length,
                itemBuilder: (context, index) {
                  final animal = animals[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          // Animal emoji
                          Text(
                            animal.type,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          // Details – Expanded to take remaining space
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
                                  maxLines: 1,
                                ),
                                Text(
                                  '${animal.count} animals · ${animal.health} · \$${animal.feedCost.toStringAsFixed(0)}/mo feed',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: HavenColors.muted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          // Action buttons – use Wrap to prevent overflow
                          Wrap(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.health_and_safety,
                                    color: Colors.blue, size: 20),
                                onPressed: () =>
                                    _showHealthUpdateDialog(animal),
                                tooltip: 'Update Health',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                                onPressed: () {
                                  appState.deleteAnimal(animal.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('${animal.name} removed')),
                                  );
                                },
                                tooltip: 'Remove',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
