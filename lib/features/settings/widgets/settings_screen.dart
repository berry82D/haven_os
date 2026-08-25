// lib/features/settings/widgets/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/services/auth_service.dart';
import 'package:haven_os/services/backup_service.dart';
import 'package:haven_os/features/settings/widgets/household_management_screen.dart';
import 'package:haven_os/features/settings/widgets/account_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: HavenColors.cream,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: HavenColors.dark,
      ),
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

              // ---- Export Data ----
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

              // ---- Import Data ----
              _buildSettingTile(
                icon: Icons.restore,
                title: 'Import Data',
                subtitle:
                    'Restore from a JSON backup file (replaces all current data)',
                trailing: ElevatedButton(
                  onPressed: () => _importData(context, appState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Import'),
                ),
              ),
              const SizedBox(height: 12),

              // ---- Reset All Data ----
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

              // ---- Household Management ----
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

              // ---- Manage Accounts ----
              _buildSettingTile(
                icon: Icons.people_outline,
                title: 'Manage Accounts',
                subtitle: 'View and delete user accounts',
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: HavenColors.muted),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ✅ NEW: PIN Security – static (no toggle, just info)
              _buildSettingTile(
                icon: Icons.lock,
                title: 'Password Lock',
                subtitle: 'Enabled – required to unlock the app',
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
              const SizedBox(height: 12),

              // ---- About ----
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
                          children: const [
                            Text('Version 1.0.0'),
                            SizedBox(height: 8),
                            Text('A local‑first Household Operating System.'),
                            SizedBox(height: 8),
                            Text('Your data stays on your device by default.'),
                            SizedBox(height: 8),
                            Text('Made with ❤️ for families and farms.'),
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
      final data = BackupService.buildBackupData(
        transactions: appState.transactions,
        animals: appState.animals,
        bills: appState.bills,
        tasks: appState.tasks,
        timelineEvents: appState.timelineEvents,
        loans: appState.loans,
        feedDeliveries: appState.feedDeliveries,
        budgets: appState.budgets,
        accounts: await AuthService.loadAccounts(),
        households: appState.households,
        joinRequests: appState.joinRequests,
        guardianRelationships: appState.guardianRelationships,
      );
      await BackupService.exportBackup(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Backup exported successfully!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Export error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importData(BuildContext context, AppState appState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Data?'),
        content: const Text(
          'This will REPLACE all current data with the backup file.\n\n'
          'Current accounts, transactions, animals, bills, tasks, loans, feed deliveries, budgets, '
          'and household data will be lost.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final data = await BackupService.importBackup();
      await appState.restoreFromBackup(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Data imported successfully!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Import error: $e'), backgroundColor: Colors.red),
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
}
