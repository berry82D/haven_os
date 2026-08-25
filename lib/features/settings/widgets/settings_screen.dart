// lib/features/settings/widgets/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/services/auth_service.dart';
import 'package:haven_os/features/settings/widgets/household_management_screen.dart';
import 'package:haven_os/features/settings/widgets/account_management_screen.dart';
import 'package:haven_os/models/user_account.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: HavenColors.cream,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: HavenColors.dark,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ========== ACCOUNT ==========
            _sectionHeader('Account'),
            _buildSettingTile(
              icon: Icons.person,
              title: 'Profile',
              subtitle: user?.name ?? 'Guest',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Profile details (optional)
              },
            ),
            _buildSettingTile(
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Log out of your account',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                appState.logout();
                Navigator.pushReplacementNamed(context, '/auth');
              },
            ),
            const SizedBox(height: 16),

            // ========== PREFERENCES ==========
            _sectionHeader('Preferences'),
            // Weight Unit
            _buildSettingTile(
              icon: Icons.scale,
              title: 'Weight Unit',
              subtitle: user?.weightUnit == 'kg' ? 'Kilograms' : 'Pounds',
              trailing: ToggleButtons(
                isSelected: [
                  user?.weightUnit == 'lb',
                  user?.weightUnit == 'kg',
                ],
                onPressed: (index) {
                  final newUnit = index == 0 ? 'lb' : 'kg';
                  _updatePreference(context, appState, 'weightUnit', newUnit);
                },
                children: const [
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('lb')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('kg')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Temperature Unit
            _buildSettingTile(
              icon: Icons.thermostat,
              title: 'Temperature',
              subtitle: user?.temperatureUnit == 'C' ? 'Celsius' : 'Fahrenheit',
              trailing: ToggleButtons(
                isSelected: [
                  user?.temperatureUnit == 'C',
                  user?.temperatureUnit == 'F',
                ],
                onPressed: (index) {
                  final newUnit = index == 0 ? 'C' : 'F';
                  _updatePreference(
                      context, appState, 'temperatureUnit', newUnit);
                },
                children: const [
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('°C')),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('°F')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Currency Symbol
            _buildSettingTile(
              icon: Icons.attach_money,
              title: 'Currency',
              subtitle: user?.currencySymbol ?? '\$',
              trailing: DropdownButton<String>(
                value: user?.currencySymbol,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: '\$', child: Text('\$ USD')),
                  DropdownMenuItem(value: '€', child: Text('€ EUR')),
                  DropdownMenuItem(value: '£', child: Text('£ GBP')),
                  DropdownMenuItem(value: '¥', child: Text('¥ JPY')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updatePreference(
                        context, appState, 'currencySymbol', value);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            // Date Format
            _buildSettingTile(
              icon: Icons.calendar_today,
              title: 'Date Format',
              subtitle: user?.dateFormat ?? 'MM/dd/yyyy',
              trailing: DropdownButton<String>(
                value: user?.dateFormat,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                      value: 'MM/dd/yyyy', child: Text('MM/DD/YYYY')),
                  DropdownMenuItem(
                      value: 'dd/MM/yyyy', child: Text('DD/MM/YYYY')),
                  DropdownMenuItem(
                      value: 'yyyy-MM-dd', child: Text('YYYY-MM-DD')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updatePreference(context, appState, 'dateFormat', value);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // ========== DATA ==========
            _sectionHeader('Data'),
            _buildSettingTile(
              icon: Icons.save_alt,
              title: 'Export Data',
              subtitle: 'Save all data as JSON backup',
              trailing: ElevatedButton(
                onPressed: () => _exportData(context, appState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Export'),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: Icons.restore,
              title: 'Import Data',
              subtitle: 'Restore from JSON backup',
              trailing: ElevatedButton(
                onPressed: () => _importData(context, appState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Import'),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: Icons.delete_sweep,
              title: 'Reset All Data',
              subtitle: 'Delete all app data (cannot be undone)',
              trailing: ElevatedButton(
                onPressed: () => _confirmReset(context, appState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(height: 16),

            // ========== HOUSEHOLD ==========
            if (appState.isParentAccount) ...[
              _sectionHeader('Household'),
              _buildSettingTile(
                icon: Icons.people,
                title: 'Household Management',
                subtitle: 'Approve join requests, view members',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HouseholdManagementScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // ========== SECURITY ==========
            _sectionHeader('Security'),
            _buildSettingTile(
              icon: Icons.lock,
              title: 'Password Lock',
              subtitle: 'Enabled – required to unlock the app',
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
            _buildSettingTile(
              icon: Icons.people_outline,
              title: 'Manage Accounts',
              subtitle: 'Add, delete, or change user accounts',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ========== ABOUT ==========
            _sectionHeader('About'),
            _buildSettingTile(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: 'Haven_OS v1.0.0',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAboutDialog(context),
            ),
            const SizedBox(height: 20),

            // Footer
            Center(
              child: Text(
                'All data stored locally on this device.',
                style: TextStyle(
                  fontSize: 12,
                  color: HavenColors.lightMuted,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: HavenColors.dark,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: HavenColors.green, size: 28),
        title: Text(title),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: HavenColors.muted)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  // ─── Update any user preference ──────────────────────────────────────

  Future<void> _updatePreference(
    BuildContext context,
    AppState appState,
    String key,
    dynamic value,
  ) async {
    final user = appState.currentUser;
    if (user == null) return;

    final updated = UserAccount(
      id: user.id,
      householdId: user.householdId,
      name: user.name,
      role: user.role,
      type: user.type,
      hasPin: user.hasPin,
      useBiometrics: user.useBiometrics,
      autoLogin: user.autoLogin,
      permissions: user.permissions,
      learningMode: user.learningMode,
      schoolAgeGroup: user.schoolAgeGroup,
      allowFinalAnswers: user.allowFinalAnswers,
      weightUnit: key == 'weightUnit' ? value : user.weightUnit,
      temperatureUnit: key == 'temperatureUnit' ? value : user.temperatureUnit,
      currencySymbol: key == 'currencySymbol' ? value : user.currencySymbol,
      dateFormat: key == 'dateFormat' ? value : user.dateFormat,
      languageCode: user.languageCode,
    );

    await AuthService.updateUser(updated);
    appState.setCurrentUser(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preference updated')),
    );
  }

  // ─── Export, Import, Reset (stubs – keep your existing implementations) ───

  Future<void> _exportData(BuildContext context, AppState appState) async {
    // Your existing export code
  }

  Future<void> _importData(BuildContext context, AppState appState) async {
    // Your existing import code
  }

  Future<void> _confirmReset(BuildContext context, AppState appState) async {
    // Your existing reset with confirmation
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🏡 Haven_OS'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
  }
}
