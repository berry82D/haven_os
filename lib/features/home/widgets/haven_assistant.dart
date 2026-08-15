import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/services/app_state.dart';

class HavenAssistant extends StatefulWidget {
  const HavenAssistant({super.key});

  @override
  State<HavenAssistant> createState() => _HavenAssistantState();
}

class _HavenAssistantState extends State<HavenAssistant> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final tasks = appState.myTasks; // ✅ Get tasks
        final transactions = appState.myTransactions;
        final bills = appState.myBills;
        final animals = appState.myAnimals;

        final totalBalance = transactions.fold(0.0, (sum, t) => sum + t.amount);
        final pendingTasks = tasks
            .where((t) => !t.isDone)
            .toList(); // ✅ Safe – t is not nullable
        final now = DateTime.now();
        final upcomingBills = bills
            .where((b) =>
                !b.isPaid &&
                b.dueDate.isAfter(now) &&
                b.dueDate.isBefore(now.add(const Duration(days: 7))))
            .toList();
        final attentionAnimals =
            animals.where((a) => a.health != 'Good').toList();

        final hour = DateTime.now().hour;
        String greeting;
        if (hour < 12)
          greeting = 'Good morning';
        else if (hour < 17)
          greeting = 'Good afternoon';
        else
          greeting = 'Good evening';

        String summary = '$greeting, ${appState.currentUser?.name ?? 'User'}!';
        final List<String> summaryParts = [];
        if (pendingTasks.isNotEmpty) {
          summaryParts.add(
              '${pendingTasks.length} task${pendingTasks.length > 1 ? 's' : ''} pending');
        }
        if (upcomingBills.isNotEmpty) {
          summaryParts.add(
              '${upcomingBills.length} bill${upcomingBills.length > 1 ? 's' : ''} due soon');
        }
        if (attentionAnimals.isNotEmpty) {
          summaryParts.add(
              '${attentionAnimals.length} animal${attentionAnimals.length > 1 ? 's' : ''} need care');
        }
        if (summaryParts.isEmpty) {
          summary += ' Everything looks great!';
        } else {
          summary += ' You have ${summaryParts.join(', ')}.';
        }

        Widget expandedBody = const SizedBox.shrink();
        if (_expanded) {
          expandedBody = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              if (transactions.isNotEmpty) ...[
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                ...transactions.reversed.take(3).map((t) => ListTile(
                      dense: true,
                      leading: Icon(
                        t.amount > 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: t.amount > 0 ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      title: Text(t.description,
                          style: const TextStyle(fontSize: 13)),
                      trailing: Text(
                        '\$${t.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: t.amount > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
              if (upcomingBills.isNotEmpty) ...[
                const Text(
                  'Upcoming Bills',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                ...upcomingBills.map((b) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.receipt, size: 16),
                      title: Text(b.name, style: const TextStyle(fontSize: 13)),
                      trailing: Text(
                        '\$${b.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
              if (attentionAnimals.isNotEmpty) ...[
                const Text(
                  'Animal Health Alerts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                ...attentionAnimals.map((a) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.pets, size: 16),
                      title: Text('${a.name} (${a.health})',
                          style: const TextStyle(fontSize: 13)),
                      trailing: Text('${a.count} animals',
                          style: const TextStyle(fontSize: 13)),
                    )),
                const SizedBox(height: 8),
              ],
              ListTile(
                dense: true,
                leading: const Icon(Icons.account_balance, size: 16),
                title:
                    const Text('Total Balance', style: TextStyle(fontSize: 13)),
                trailing: Text(
                  '\$${totalBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: totalBalance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          );
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, color: HavenColors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          summary,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: HavenColors.muted,
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: expandedBody,
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
