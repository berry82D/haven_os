import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/core/enums/learning_mode.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/features/auth/widgets/password_strength_indicator.dart';
import 'package:haven_os/features/settings/widgets/household_management_screen.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: HavenColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚙️ Settings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: HavenColors.dark,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingTile(
                icon: Icons.school,
                title: 'School Help Mode',
                subtitle: appState.learningMode == LearningMode.schoolHelp
                    ? 'Guiding questions – helps kids learn'
                    : 'Standard mode – answers questions directly',
                trailing: Switch(
                  value: appState.learningMode == LearningMode.schoolHelp,
                  onChanged: (value) {
                    appState.setLearningMode(
                      value ? LearningMode.schoolHelp : LearningMode.standard,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? '🎓 School Help enabled – I\'ll guide with questions!'
                              : 'Standard mode restored',
                        ),
                      ),
                    );
                  },
                  activeThumbColor: HavenColors.green,
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingTile(
                icon: Icons.save_alt,
                title: 'Export Data',
                subtitle: 'Save all your data as a JSON backup file',
                trailing: ElevatedButton(
                  onPressed: () => _exportData(context, appState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Export'),
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingTile(
                icon: Icons.delete_forever,
                title: 'Reset All Data',
                subtitle: 'Permanently erase all data (cannot be undone)',
                trailing: ElevatedButton(
                  onPressed: () => _resetAllData(context, appState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(height: 12),
              if (appState.isParentAccount) ...[
                _buildSettingTile(
                  icon: Icons.people,
                  title: 'Household Management',
                  subtitle: 'View and approve join requests',
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: HavenColors.muted),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HouseholdManagementScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildSettingTile(
                icon: Icons.lock_outline,
                title: 'PIN Security',
                subtitle: appState.isPinEnabled ? 'PIN enabled' : 'No PIN set',
                trailing: Switch(
                  value: appState.isPinEnabled,
                  onChanged: (value) {
                    if (value) {
                      _showSetPasswordDialog(context, appState);
                    } else {
                      appState.disablePin();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password disabled')),
                      );
                    }
                  },
                  activeThumbColor: HavenColors.green,
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingTile(
                icon: Icons.info_outline,
                title: 'About Haven_OS',
                subtitle: 'Version 1.0.0',
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: HavenColors.muted),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('🏡 Haven_OS'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Version 1.0.0'),
                            const SizedBox(height: 8),
                            const Text(
                                'A local‑first Household Operating System.'),
                            const SizedBox(height: 8),
                            const Text(
                                'Your data stays on your device by default.'),
                            const SizedBox(height: 8),
                            const Text('Made with ❤️ for families and farms.'),
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
                  },
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  'Haven_OS v1.0.0 • All data stored locally',
                  style: TextStyle(
                    fontSize: 12,
                    color: HavenColors.lightMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          Icon(icon, color: HavenColors.green, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: HavenColors.dark,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: HavenColors.muted,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, AppState appState) async {
    try {
      final data = {
        'transactions': appState.transactions.map((t) => t.toJson()).toList(),
        'animals': appState.animals.map((a) => a.toJson()).toList(),
        'bills': appState.bills.map((b) => b.toJson()).toList(),
        'tasks': appState.tasks.map((t) => t.toJson()).toList(),
        'loans': appState.loans.map((l) => l.toJson()).toList(),
        'feedDeliveries':
            appState.feedDeliveries.map((f) => f.toJson()).toList(),
        'timelineEvents':
            appState.timelineEvents.map((e) => e.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
      final jsonString = jsonEncode(data);

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/haven_os_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported to: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetAllData(BuildContext context, AppState appState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all your transactions, animals, bills, tasks, loans, feed deliveries, and timeline events.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await appState.resetAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data has been reset.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSetPasswordDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create a strong password with:\n'
                '• 6+ characters\n'
                '• 1 uppercase letter\n'
                '• 1 number\n'
                '• 1 special character (!@#\$%^&*...)',
                style: TextStyle(fontSize: 12, color: HavenColors.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              PasswordStrengthIndicator(password: controller.text),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
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
                final password = controller.text.trim();
                final confirm = confirmController.text.trim();
                if (password != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }
                final result =
                    PasswordStrengthIndicator.evaluatePassword(password);
                if (result.rulesMet < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password does not meet requirements')),
                  );
                  return;
                }
                appState.enablePin(password);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password enabled!')),
                );
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      ),
    );
  }
}
