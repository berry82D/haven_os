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

          // --- Security Section (NEW) ---
          const Text(
            'Security',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: FutureBuilder<bool>(
              future: appState.hasPin(),
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

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  // --- Password toggle with strong validation ---
  Future<void> _togglePassword(BuildContext context, AppState appState) async {
    final hasPin = await appState.hasPin();
    if (hasPin) {
      await appState.disablePin();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password disabled')),
        );
      }
    } else {
      final passwordController = TextEditingController();
      String? errorText;

      await showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Set Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      errorText: errorText,
                      helperText: 'Min 8 chars, 1 upper, 1 lower, 1 number',
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
                  onPressed: () async {
                    final password = passwordController.text.trim();
                    final error = AppState.validatePassword(password);
                    if (error != null) {
                      setStateDialog(() => errorText = error);
                      return;
                    }
                    await appState.enablePin(password);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password enabled')),
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
  }
}
