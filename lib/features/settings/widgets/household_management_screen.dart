// lib/features/settings/widgets/household_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/services/app_state.dart';

class HouseholdManagementScreen extends StatelessWidget {
  const HouseholdManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isParent = appState.isParentAccount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Household Management'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isParent ? '👑 Parent Controls' : '👤 Household Members',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.people),
                title: Text('Household Members'),
                subtitle: Text('Manage family members'),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.person_add),
                title: Text('Invite Member'),
                subtitle: Text('Send join request to someone'),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
            if (isParent) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('Promote to Parent'),
                  subtitle: const Text('Grant parent privileges'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _promoteToParent(context),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              '💡 Join requests will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Simple promote function
  Future<void> _promoteToParent(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote to Parent'),
        content:
            const Text('Are you sure you want to promote this user to Parent?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Promote', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      // Use the first household member (stub)
      final members = appState.getHouseholdMembers();
      if (members.isNotEmpty) {
        await appState.promoteToParent(members.first.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ User promoted successfully!')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No users found to promote.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }
}
