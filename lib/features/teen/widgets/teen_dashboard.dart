// lib/features/teen/widgets/teen_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/models/task.dart';
import 'package:intl/intl.dart';

class TeenDashboard extends StatelessWidget {
  const TeenDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final transactions = appState.myTransactions;
    final tasks = appState.myTasks;
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList();

    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = income - expenses;

    return Scaffold(
      backgroundColor: HavenColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                '👋 Welcome, ${appState.currentUser?.name ?? 'Teen'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: HavenColors.dark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 14,
                  color: HavenColors.muted,
                ),
              ),
              const SizedBox(height: 16),

              // Stats cards
              Row(
                children: [
                  _buildStatCard(
                    title: 'Balance',
                    value: '\$${balance.toStringAsFixed(2)}',
                    color: balance >= 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: 'Income',
                    value: '\$${income.toStringAsFixed(2)}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: 'Tasks',
                    value: '${pendingTasks.length}',
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),

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
                    label: 'Add Task',
                    color: Colors.blue,
                    onTap: () => _showAddTaskDialog(context, appState),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Recent transactions
              if (transactions.isNotEmpty) ...[
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HavenColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                ...transactions.reversed
                    .take(5)
                    .map((t) => _buildTransactionTile(t)),
              ],

              // Pending tasks
              if (pendingTasks.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Pending Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HavenColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                ...pendingTasks
                    .take(5)
                    .map((task) => _buildTaskTile(task, appState)),
              ],

              // Empty state
              if (transactions.isEmpty && pendingTasks.isEmpty) ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.celebration,
                          size: 64, color: HavenColors.lightMuted),
                      const SizedBox(height: 16),
                      Text(
                        'Nothing here yet!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: HavenColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add income, expenses, or tasks to get started.',
                        style: TextStyle(
                          fontSize: 14,
                          color: HavenColors.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      {required String title, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
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
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: HavenColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
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
                  fontSize: 10,
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

  Widget _buildTransactionTile(Transaction tx) {
    final isIncome = tx.type == TransactionType.income;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: isIncome ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  DateFormat('MMM d').format(tx.date),
                  style: TextStyle(fontSize: 12, color: HavenColors.muted),
                ),
              ],
            ),
          ),
          Text(
            '\$${tx.amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(Task task, AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (_) => appState.toggleTaskCompletion(task.id),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                // No dueDate in Task – show priority instead
                Text(
                  'Priority: ${task.priority}',
                  style: TextStyle(fontSize: 12, color: HavenColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getPriorityColor(task.priority).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              task.priority,
              style: TextStyle(
                fontSize: 10,
                color: _getPriorityColor(task.priority),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
                    type: TransactionType.income,
                    userId: appState.currentUser!.id,
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
                          Text('Please enter a valid amount and description')),
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
                    type: TransactionType.expense,
                    userId: appState.currentUser!.id,
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
                          Text('Please enter a valid amount and description')),
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
                    isCompleted: false,
                    priority: 'Medium',
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
}
