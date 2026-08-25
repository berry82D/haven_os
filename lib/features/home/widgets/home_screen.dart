// lib/features/home/widgets/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/domain/services/briefing_service.dart';
import 'package:haven_os/features/home/widgets/morning_briefing.dart';
import 'package:haven_os/features/home/widgets/timeline_widget.dart';
import 'package:haven_os/features/home/widgets/haven_assistant.dart';
import 'package:haven_os/features/scan/presentation/scan_screen.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/models/transaction.dart';
import 'package:haven_os/models/animal.dart';
import 'package:haven_os/models/task.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<String> _presetCategories = [
    'Food',
    'Groceries',
    'Dining Out',
    'Salary',
    'Freelance',
    'Bonus',
    'Farm',
    'Livestock',
    'Feed',
    'Rent',
    'Mortgage',
    'Utilities',
    'Electricity',
    'Water',
    'Gas',
    'Internet',
    'Insurance',
    'Health Insurance',
    'Car Insurance',
    'Loan',
    'Car Payment',
    'Student Loan',
    'Personal Loan',
    'Car',
    'Fuel',
    'Maintenance',
    'Repairs',
    'Shopping',
    'Clothing',
    'Electronics',
    'Entertainment',
    'Movies',
    'Games',
    'Hobbies',
    'Subscriptions',
    'Netflix',
    'Spotify',
    'Health',
    'Medical',
    'Pharmacy',
    'Education',
    'Tuition',
    'Books',
    'Gifts',
    'Charity',
    'Personal Care',
    'Beauty',
    'Gym',
    'Travel',
    'Hotel',
    'Transport',
    'Home Improvement',
    'Furniture',
    'Tools',
    'Taxes',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

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
              // ---- Date and notifications ----
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
                        icon: const Icon(Icons.notifications_none, size: 20),
                        onPressed: () {},
                        color: HavenColors.muted,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ---- Morning Briefing ----
              const MorningBriefing(),
              const SizedBox(height: 20),

              // ---- Timeline ----
              const TimelineWidget(),
              const SizedBox(height: 20),

              // ---- ⭐ LARGE INCOME / EXPENSE BUTTONS ⭐ ----
              Row(
                children: [
                  Expanded(
                    child: _buildLargeActionButton(
                      icon: Icons.arrow_upward,
                      label: 'Add Income',
                      color: Colors.green,
                      onTap: () => _showAddTransactionDialog(
                        context,
                        appState,
                        initialType: TransactionType.income,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLargeActionButton(
                      icon: Icons.arrow_downward,
                      label: 'Add Expense',
                      color: Colors.red,
                      onTap: () => _showAddTransactionDialog(
                        context,
                        appState,
                        initialType: TransactionType.expense,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---- Secondary actions (Scan, Tasks, Animals) ----
              Row(
                children: [
                  _buildSmallQuickAction(
                    icon: Icons.document_scanner,
                    label: 'Scan',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildSmallQuickAction(
                    icon: Icons.checklist_outlined,
                    label: 'Tasks',
                    color: Colors.blue,
                    onTap: () => _showAddTaskDialog(context, appState),
                  ),
                  const SizedBox(width: 12),
                  _buildSmallQuickAction(
                    icon: Icons.pets,
                    label: 'Animals',
                    color: Colors.orange,
                    onTap: () => _showAddAnimalDialog(context, appState),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Haven Assistant ----
              const HavenAssistant(),
              const SizedBox(height: 16),

              // ---- Daily Story ----
              _buildDailyStory(appState),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Large action button (Income / Expense) ──────────────────────────

  Widget _buildLargeActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Small quick action (Scan, Tasks, Animals) ──────────────────────

  Widget _buildSmallQuickAction({
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
                blurRadius: 6,
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
                  fontSize: 12,
                  color: HavenColors.muted,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers (unchanged) ─────────────────────────────────────────────

  String _getFormattedDate() {
    final now = DateTime.now();
    final day = _getDayOfWeek(now.weekday);
    return '$day, ${now.month}/${now.day}/${now.year}';
  }

  String _getDayOfWeek(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
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

  // ---- Add Transaction Dialog (unified) ----
  void _showAddTransactionDialog(
    BuildContext context,
    AppState appState, {
    TransactionType initialType = TransactionType.expense,
  }) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Other';
    Account selectedAccount = Account(id: 'default', name: 'Default');
    DateTime selectedDate = DateTime.now();
    TransactionType selectedType = initialType;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          final List<DropdownMenuItem<String>> categoryItems = [
            ..._presetCategories.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                )),
            const DropdownMenuItem(
              value: '__custom__',
              child:
                  Text('+ Add custom...', style: TextStyle(color: Colors.blue)),
            ),
          ];

          return AlertDialog(
            title: Text(initialType == TransactionType.income
                ? 'Add Income'
                : 'Add Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scan button inside dialog
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScanScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.document_scanner, size: 18),
                      label: const Text('Scan Receipt'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HavenColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: HavenColors.green),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Income'),
                      ),
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Expense'),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (selection) {
                      setState(() => selectedType = selection.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Groceries, Paycheck',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categoryItems,
                    onChanged: (value) {
                      if (value == '__custom__') {
                        // Keep 'Other'
                      } else {
                        setState(() => selectedCategory = value!);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Account>(
                    initialValue: selectedAccount,
                    decoration: const InputDecoration(labelText: 'Account'),
                    items: [
                      DropdownMenuItem(
                        value: Account(id: 'cash', name: 'Cash'),
                        child: Text('Cash'),
                      ),
                      DropdownMenuItem(
                        value: Account(id: 'bank', name: 'Bank'),
                        child: Text('Bank'),
                      ),
                      DropdownMenuItem(
                        value: Account(id: 'farm', name: 'Farm'),
                        child: Text('Farm'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => selectedAccount = value!),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Date: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        child: Text(
                            DateFormat('MMM d, yyyy').format(selectedDate)),
                      ),
                    ],
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
                  final desc = descriptionController.text.trim();
                  final amount = double.tryParse(amountController.text.trim());
                  if (desc.isNotEmpty && amount != null && amount > 0) {
                    final finalAmount = selectedType == TransactionType.income
                        ? amount
                        : -amount;
                    appState.addTransaction(
                      Transaction(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        description: desc,
                        amount: finalAmount,
                        date: selectedDate,
                        category: selectedCategory,
                        type: selectedType,
                        userId: appState.currentUser!.id,
                      ),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${selectedType == TransactionType.income ? 'Income' : 'Expense'} added!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields correctly'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---- Add Task Dialog ----
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

  // ---- Add Animal Dialog ----
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
                    healthStatus: selectedHealth ?? 'Good',
                    userId: appState.currentUser?.id ?? '',
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
