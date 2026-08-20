// lib/features/settings/widgets/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/services/auth_service.dart';
import 'package:haven_os/services/backup_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Settings'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          const Text(
            'Account',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              subtitle: Text(appState.currentUser?.name ?? 'Guest'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showSnackbar(context, '👤 Profile settings coming soon');
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                appState.logout();
                Navigator.pushReplacementNamed(context, '/auth');
              },
            ),
          ),
          const SizedBox(height: 24),

          // Security Section
          const Text(
            'Security',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: FutureBuilder<bool>(
              future: AuthService.hasPin(appState.currentUser?.id ?? ''),
              builder: (context, snapshot) {
                final hasPin = snapshot.data ?? false;
                return SwitchListTile(
                  title: const Text('Enable Password Lock'),
                  subtitle: const Text('Require password to unlock the app'),
                  value: hasPin,
                  onChanged: (_) => _togglePassword(context, appState),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Data Section
          const Text(
            'Data',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // ---- Export Data ----
          Card(
            child: ListTile(
              leading: const Icon(Icons.save_alt, color: Colors.blue),
              title: const Text('Export Data'),
              subtitle: const Text('Save all data as JSON backup'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exportData(context, appState),
            ),
          ),
          const SizedBox(height: 8),

          // ---- Import Data ----
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('Import Data'),
              subtitle: const Text('Restore from JSON backup'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _importData(context, appState),
            ),
          ),
          const SizedBox(height: 8),

          // ---- Reset All Data ----
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text('Reset All Data'),
              subtitle: const Text('Delete all app data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _confirmReset(context),
            ),
          ),
          const SizedBox(height: 24),

          // App Info Section
          const Text(
            'App Info',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Version'),
              subtitle: Text('Haven_OS v1.0.0'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _togglePassword(BuildContext context, AppState appState) async {
    final hasPin = await AuthService.hasPin(appState.currentUser?.id ?? '');
    if (hasPin) {
      await appState.disablePin();
      _showSnackbar(context, 'Password lock disabled');
    } else {
      // Show dialog to set password
      final controller = TextEditingController();
      final confirmController = TextEditingController();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Set Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text == confirmController.text &&
                    controller.text.isNotEmpty) {
                  await appState.enablePin(controller.text);
                  Navigator.pop(context);
                  _showSnackbar(context, 'Password lock enabled');
                } else {
                  _showSnackbar(context, 'Passwords do not match or are empty');
                }
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Reset All Data'),
          content: const Text(
            'Are you sure you want to delete all app data? This cannot be undone.',
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
        );
      },
    );

    if (confirmed == true) {
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.resetAllData(); // ✅ Fixed 'await'
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ All data has been reset'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Backup exported!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export error: $e'), backgroundColor: Colors.red),
        );
      }
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data imported!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Import error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
