// lib/features/settings/widgets/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/services/app_state.dart';

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

          // Preferences Section
          const Text(
            'Preferences',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Child Mode'),
              subtitle: const Text('Enable simplified interface'),
              value: appState.isChildAccount,
              onChanged: (_) {
                _showSnackbar(context, 'Child mode toggle coming soon');
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

  // Helper to show snackbar
  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Reset confirmation dialog
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
        appState.resetAllData();
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
              content: Text('❌ Error resetting data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
