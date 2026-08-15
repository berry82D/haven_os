// lib/features/haven_central/haven_central_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'haven_central_viewmodel.dart';
import 'command_parser.dart';
import 'scan_service.dart';

class HavenCentralScreen extends StatefulWidget {
  const HavenCentralScreen({super.key});

  @override
  State<HavenCentralScreen> createState() => _HavenCentralScreenState();
}

class _HavenCentralScreenState extends State<HavenCentralScreen> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _feedback = '👋 Hello! Type "Help" to see what I can do.';

  bool _showScanButton = false;
  bool _isScanning = false;
  int _tapCount = 0;

  void _handleTitleTap() {
    _tapCount++;
    if (_tapCount >= 5) {
      setState(() {
        _showScanButton = !_showScanButton;
        _tapCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_showScanButton
              ? '🔍 Scan mode activated'
              : '🔍 Scan mode hidden'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _scanReceipt() async {
    setState(() => _isScanning = true);
    final service = ScanService();
    final text = await service.scanReceipt();
    setState(() => _isScanning = false);

    if (text == null) return;

    final parsed = ScanService.parseText(text);
    final amount = parsed['amount'];
    final date = parsed['date'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('📄 Scanned Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Amount: ${amount != null ? '\$${amount.toStringAsFixed(2)}' : 'Not found'}'),
            Text('Date: ${date ?? 'Not found'}'),
            const SizedBox(height: 8),
            Text(
                'Raw text:\n${text.substring(0, text.length > 100 ? 100 : text.length)}...',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (amount != null) {
                final model = context.read<HavenCentralViewModel>();
                model.addExpense(amount, 'Scanned Receipt');
                Navigator.pop(context);
                setState(() {
                  _feedback =
                      '✅ Added scanned expense of \$${amount.toStringAsFixed(2)}';
                });
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Could not find amount in receipt.')),
                );
              }
            },
            child: const Text('Add as Expense'),
          ),
        ],
      ),
    );
  }

  void _handleCommand() {
    final input = _commandController.text.trim();
    if (input.isEmpty) return;
    final model = context.read<HavenCentralViewModel>();
    final response = CommandParser.parse(input, model);
    setState(() => _feedback = response);
    _commandController.clear();
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleTitleTap,
          onLongPress: _handleTitleTap,
          child: const Text('🏡 Haven Central'),
        ),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🎤 Voice input coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Consumer<HavenCentralViewModel>(
        builder: (context, model, child) {
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHealthCard(model.healthScore),
                const SizedBox(height: 20),
                _buildCommandBar(),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_feedback, style: const TextStyle(fontSize: 15)),
                ),
                const SizedBox(height: 24),
                _buildCollapsibleSection(
                  title: '💰 Financial Overview',
                  icon: Icons.attach_money,
                  child: _buildFinanceSection(model),
                ),
                const SizedBox(height: 16),
                _buildCollapsibleSection(
                  title: '🌾 Farm Status',
                  icon: Icons.agriculture,
                  child: _buildFarmSection(model),
                ),
                const SizedBox(height: 16),
                _buildQuickActions(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _showScanButton
          ? FloatingActionButton.extended(
              onPressed: _isScanning ? null : _scanReceipt,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Icons.camera_alt),
              label: Text(_isScanning ? 'Scanning...' : 'Scan Receipt'),
              backgroundColor: Colors.teal.shade700,
            )
          : null,
    );
  }

  // --- UI Builder Methods ---

  Widget _buildHealthCard(int score) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.red, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Household Health',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey.shade300,
                    color: score > 70 ? Colors.green : Colors.orange,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('$score%',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commandController,
            decoration: InputDecoration(
              hintText: 'e.g. "Add \$50 to groceries"',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _handleCommand,
              ),
            ),
            onSubmitted: (_) => _handleCommand(),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.teal.shade700),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [Padding(padding: const EdgeInsets.all(12), child: child)],
      ),
    );
  }

  Widget _buildFinanceSection(HavenCentralViewModel model) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🛡️ Safe to Spend',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\$${model.safeToSpend.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: model.monthlyExpenses
                  .take(6)
                  .toList() // ✅ .toList() added here to fix asMap error
                  .asMap()
                  .entries
                  .map((e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value,
                            color: Colors.teal,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      ))
                  .toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = ['Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      return Text(months[value.toInt() % months.length],
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFarmSection(HavenCentralViewModel model) {
    return Column(
      children: [
        SizedBox(
          height: 70,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: model.animalCounts.entries.map((entry) {
              return Card(
                color: Colors.brown.shade50,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Text('${entry.value}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        ...model.feedInventory.entries.map((entry) {
          final isLow = entry.value < 100;
          return ListTile(
            leading: Icon(isLow ? Icons.warning_amber : Icons.check_circle,
                color: isLow ? Colors.orange : Colors.green),
            title: Text(entry.key),
            trailing: Text('${entry.value} kg',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLow ? Colors.orange : null)),
            dense: true,
          );
        }).toList(),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('➕ Feed delivery log coming soon!')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Log Feed Delivery'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(Icons.add_circle, 'Add Income', () {
          _showAddDialog(context, isIncome: true);
        }),
        _actionButton(Icons.remove_circle, 'Add Expense', () {
          _showAddDialog(context, isIncome: false);
        }),
        _actionButton(Icons.checklist, 'Tasks', () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📋 Tasks screen coming soon!')),
          );
        }),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.teal.shade700, size: 36),
          onPressed: onTap,
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showAddDialog(BuildContext context, {required bool isIncome}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isIncome ? 'Add Income' : 'Add Expense'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                final model = context.read<HavenCentralViewModel>();
                if (isIncome) {
                  model.addIncome(amount, 'Manual');
                } else {
                  model.addExpense(amount, 'Manual');
                }
                Navigator.pop(context);
                setState(() {
                  _feedback =
                      '✅ Added ${isIncome ? 'income' : 'expense'} of \$${amount.toStringAsFixed(2)}';
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
