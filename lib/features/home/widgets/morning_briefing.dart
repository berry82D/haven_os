import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/domain/services/health_score_service.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/models/task.dart';

class MorningBriefing extends StatelessWidget {
  const MorningBriefing({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final healthScore = appState.healthScore;
    final briefing = appState.briefing.generate(
      transactions: appState.myTransactions,
      animals: appState.myAnimals,
      bills: appState.myBills,
      tasks: appState.myTasks,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting
        Text(
          _getGreeting(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: HavenColors.dark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          briefing['timeMessage'] ?? _getTimeOfDayMessage(),
          style: TextStyle(
            fontSize: 14,
            color: HavenColors.muted,
          ),
        ),
        const SizedBox(height: 16),

        // Health Score
        GestureDetector(
          onTap: () => _showHealthDetailsDialog(context, healthScore),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getHealthGradient(healthScore.level),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${healthScore.score}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Household Health',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        healthScore.message,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      if (healthScore.issues.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          healthScore.issues.join(' • '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Stats
        Row(
          children: [
            _buildStatCard(
              icon: Icons.payments,
              label: 'Safe to Spend',
              value:
                  '\$${briefing['safeToSpend']?.toStringAsFixed(2) ?? '0.00'}',
              color: briefing['safeToSpend'] >= 0 ? Colors.green : Colors.red,
              onTap: () => _showSafeToSpendDialog(context, appState),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.assignment,
              label: 'Pending Tasks',
              value: '${briefing['pendingTasks'] ?? 0}',
              color: (briefing['pendingTasks'] ?? 0) > 0
                  ? Colors.orange
                  : Colors.green,
              onTap: () => _showPendingTasksDialog(context, appState),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.pets,
              label: 'Animals',
              value: '${briefing['totalAnimals'] ?? 0}',
              color: (briefing['health']?['Poor'] ?? 0) > 0
                  ? Colors.orange
                  : Colors.green,
              onTap: () => _showAnimalsDialog(context, appState),
            ),
          ],
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  String _getTimeOfDayMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Start your day with a clear view of your household.';
    if (hour < 17) return 'How\'s your household running today?';
    return 'Review what happened today before you rest.';
  }

  List<Color> _getHealthGradient(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent:
        return [const Color(0xFF2E7D32), const Color(0xFF4CAF50)];
      case HealthLevel.good:
        return [const Color(0xFF388E3C), const Color(0xFF66BB6A)];
      case HealthLevel.attention:
        return [const Color(0xFFF57C00), const Color(0xFFFFA726)];
      case HealthLevel.critical:
        return [const Color(0xFFC62828), const Color(0xFFEF5350)];
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: HavenColors.dark,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: HavenColors.muted,
                ),
                textAlign: TextAlign.center,
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right,
                    size: 16, color: HavenColors.lightMuted),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Dialogs ----

  void _showHealthDetailsDialog(BuildContext context, HealthScore healthScore) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Text(healthScore.emoji),
            const SizedBox(width: 8),
            const Text('Health Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score: ${healthScore.score}/100',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Breakdown:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            _buildBreakdownTile(
                '💰 Financial', healthScore.breakdown['financial'] ?? 0, 40),
            _buildBreakdownTile(
                '📋 Tasks', healthScore.breakdown['tasks'] ?? 0, 20),
            _buildBreakdownTile(
                '📄 Bills', healthScore.breakdown['bills'] ?? 0, 20),
            _buildBreakdownTile(
                '🐾 Animals', healthScore.breakdown['animals'] ?? 0, 20),
            const Divider(),
            Text('Status: ${healthScore.message}'),
            if (healthScore.issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Issues:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              ...healthScore.issues.map((issue) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $issue'),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownTile(String label, int score, int max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: score / max,
              backgroundColor: Colors.grey.shade200,
              color: score / max > 0.7
                  ? Colors.green
                  : (score / max > 0.4 ? Colors.orange : Colors.red),
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 8),
          Text('$score/$max'),
        ],
      ),
    );
  }

  void _showPendingTasksDialog(BuildContext context, AppState appState) {
    final pendingTasks = appState.myTasks.where((t) => !t.isDone).toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pending Tasks'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pendingTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('🎉 No pending tasks!'),
              )
            else
              ...pendingTasks.map((task) => ListTile(
                    leading: const Icon(Icons.check_box_outline_blank,
                        color: Colors.blue),
                    title: Text(task.title),
                    subtitle: Text(// ✅ removed null check and '!'
                        'Due: ${task.dueDate.month}/${task.dueDate.day}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () {
                        appState.toggleTaskDone(task.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task completed!')),
                        );
                      },
                      tooltip: 'Mark done',
                    ),
                  )),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showAddTaskDialog(context, appState);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HavenColors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
                    priority: Priority.medium,
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

  void _showSafeToSpendDialog(BuildContext context, AppState appState) {
    final totalIncome =
        appState.finance.calculateTotalIncome(appState.transactions);
    final totalExpenses =
        appState.finance.calculateTotalExpenses(appState.transactions);
    final balance = totalIncome - totalExpenses;
    final upcomingBills = appState.bills
        .where((b) =>
            !b.isPaid && b.dueDate.difference(DateTime.now()).inDays <= 7)
        .toList();
    final upcomingTotal = upcomingBills.fold(0.0, (s, b) => s + b.amount);
    final safeToSpend = balance - upcomingTotal;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Safe to Spend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💰 Income: \$${totalIncome.toStringAsFixed(2)}'),
            Text('💸 Expenses: \$${totalExpenses.toStringAsFixed(2)}'),
            Text('📊 Balance: \$${balance.toStringAsFixed(2)}'),
            const Divider(),
            if (upcomingBills.isNotEmpty) ...[
              const Text('📄 Upcoming Bills (7 days):'),
              ...upcomingBills.map((b) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                        '• ${b.name}: \$${b.amount.toStringAsFixed(2)} (due ${b.dueDate.month}/${b.dueDate.day})'),
                  )),
              Text('Total upcoming: \$${upcomingTotal.toStringAsFixed(2)}'),
              const Divider(),
            ],
            Text(
              '🟢 Safe to Spend: \$${safeToSpend.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: safeToSpend >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              safeToSpend >= 0
                  ? 'You have enough for upcoming bills.'
                  : '⚠️ You may need to reduce spending.',
              style: TextStyle(
                color: safeToSpend >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAnimalsDialog(BuildContext context, AppState appState) {
    final animals = appState.myAnimals;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.pets, color: Colors.purple),
            const SizedBox(width: 8),
            const Text('Animals'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (animals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No animals added yet.'),
              )
            else
              ...animals.map((animal) => ListTile(
                    leading:
                        Text(animal.type, style: const TextStyle(fontSize: 24)),
                    title: Text(animal.name),
                    subtitle: Text('Count: ${animal.count} • ${animal.health}'),
                    trailing: Text(
                      '\$${animal.feedCost.toStringAsFixed(2)}/mo',
                      style: const TextStyle(color: Colors.blue),
                    ),
                    dense: true,
                  )),
            if (animals.isNotEmpty) ...[
              const Divider(),
              Text(
                'Total Animals: ${animals.fold(0, (s, a) => s + a.count)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Feed Cost: \$${animals.fold(0.0, (s, a) => s + a.feedCost).toStringAsFixed(2)}/mo',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
