import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/domain/services/briefing_service.dart';
import 'package:haven_os/features/home/widgets/morning_briefing.dart';
import 'package:haven_os/features/home/widgets/timeline_widget.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/models/animal.dart';
import 'package:haven_os/models/task.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HavenColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Consumer<AppState>(
            builder: (context, appState, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and quick actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getFormattedDate(),
                        style: TextStyle(
                          fontSize: 14,
                          color: HavenColors.muted,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: () => appState.refresh(),
                            color: HavenColors.muted,
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.notifications_none, size: 20),
                            onPressed: () {
                              // TODO: Show notifications
                            },
                            color: HavenColors.muted,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Morning Briefing
                  const MorningBriefing(),
                  const SizedBox(height: 20),

                  // Timeline
                  const TimelineWidget(),
                  const SizedBox(height: 20),

                  // Quick actions
                  Row(
                    children: [
                      _buildQuickAction(
                        icon: Icons.add_circle_outline,
                        label: 'Add Income',
                        color: Colors.green,
                        onTap: () => _showAddIncomeDialog(context, appState),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        icon: Icons.remove_circle_outline,
                        label: 'Add Expense',
                        color: Colors.red,
                        onTap: () => _showAddExpenseDialog(context, appState),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        icon: Icons.checklist_outlined,
                        label: 'Tasks',
                        color: Colors.blue,
                        onTap: () => _showAddTaskDialog(context, appState),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        icon: Icons.pets,
                        label: 'Animals',
                        color: Colors.purple,
                        onTap: () => _showAddAnimalDialog(context, appState),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Daily story
                  _buildDailyStory(appState),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final day = _getDayOfWeek(now.weekday);
    return '$day, ${now.month}/${now.day}/${now.year}';
  }

  String _getDayOfWeek(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: HavenColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyStory(AppState appState) {
    final briefing = appState.briefing.generate(
      transactions: appState.myTransactions,
      animals: appState.myAnimals,
      bills: appState.myBills,
      tasks: appState.myTasks,
    );

    final status = briefing['status'] as Status;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                status.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.type == StatusType.good ? 'All Good' : 'Heads Up',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: status.color,
                  ),
                ),
                Text(
                  status.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: HavenColors.dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Dialogs ----

  void _showAddIncomeDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Income'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null &&
                  amount > 0 &&
                  descriptionController.text.isNotEmpty) {
                appState.addTransaction(
                  Transaction(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    description: descriptionController.text,
                    amount: amount,
                    date: DateTime.now(),
                    category: 'Income',
                    account: Account.bank,
                    cleared: ClearedStatus.pending,
                    userId: '',
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Income added!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Please enter valid amount and description')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null &&
                  amount > 0 &&
                  descriptionController.text.isNotEmpty) {
                appState.addTransaction(
                  Transaction(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    description: descriptionController.text,
                    amount: -amount,
                    date: DateTime.now(),
                    category: 'Expense',
                    account: Account.cash,
                    cleared: ClearedStatus.pending,
                    userId: '',
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense added!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Please enter valid amount and description')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Task title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                appState.addTask(
                  Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: controller.text,
                    dueDate: DateTime.now().add(const Duration(days: 3)),
                    priority: Priority.medium, // ✅ fixed
                    userId: '',
                    category: 'General',
                    isDone: false,
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddAnimalDialog(BuildContext context, AppState appState) {
    final nameController = TextEditingController();
    final countController = TextEditingController();
    final feedCostController = TextEditingController();
    String? selectedHealth = 'Good';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Animal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Animal Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Count',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: feedCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Feed Cost (\$)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedHealth,
              decoration: const InputDecoration(
                labelText: 'Health',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Good', child: Text('Good')),
                DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                DropdownMenuItem(value: 'Poor', child: Text('Poor')),
              ],
              onChanged: (value) => selectedHealth = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final count = int.tryParse(countController.text);
              final feedCost = double.tryParse(feedCostController.text);
              if (nameController.text.isNotEmpty &&
                  count != null &&
                  feedCost != null) {
                appState.addAnimal(
                  Animal(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    type: '🐾',
                    count: count,
                    health: selectedHealth ?? 'Good',
                    feedCost: feedCost,
                    userId: '',
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Animal added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
