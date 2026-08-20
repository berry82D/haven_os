import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/services/auth_service.dart';
import 'package:haven_os/services/app_state.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  List<UserAccount> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final accounts = await AuthService.loadAccounts();
    setState(() {
      _accounts = accounts;
      _isLoading = false;
    });
  }

  bool _canDelete(UserAccount target, UserAccount currentUser) {
    if (target.id == currentUser.id) return true;
    if (currentUser.role == UserRole.administrator) return true;
    if (currentUser.role == UserRole.adult) {
      return target.role == UserRole.teen || target.role == UserRole.child;
    }
    return false;
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.administrator:
        return 'Admin';
      case UserRole.adult:
        return 'Adult';
      case UserRole.teen:
        return 'Teen';
      case UserRole.child:
        return 'Child';
    }
  }

  Future<void> _deleteAccount(
      UserAccount target, UserAccount currentUser) async {
    final isSelf = target.id == currentUser.id;

    bool confirmed = false;

    if (isSelf) {
      confirmed = await _showPinConfirmation(context);
    } else {
      confirmed = await _showDeleteConfirmation(context, target);
    }

    if (!confirmed) return;

    try {
      await AuthService.deleteAccount(target.id);

      if (isSelf) {
        // ✅ FIX: do NOT assign the result of logout() – it's void

        Navigator.pushReplacementNamed(context, '/auth');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account has been deleted.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${target.name} has been deleted.')),
      );
      _loadAccounts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<bool> _showDeleteConfirmation(
      BuildContext context, UserAccount target) async {
    final controller = TextEditingController();
    bool isConfirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('⚠️ Confirm Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to delete the account of "${target.name}" (${_getRoleName(target.role)}).',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'This action is permanent and cannot be undone.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text(
                'To confirm, type "DELETE" in the field below:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Type DELETE here',
                  suffixIcon: controller.text == 'DELETE'
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: controller.text == 'DELETE'
                  ? () {
                      Navigator.pop(context, true);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    return isConfirmed;
  }

  Future<bool> _showPinConfirmation(BuildContext context) async {
    final controller = TextEditingController();
    bool isError = false;
    bool confirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('🔒 Confirm Self-Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You are about to delete your own account.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text(
                'This action is permanent and cannot be undone.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your password to confirm:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Enter your password',
                  errorText: isError ? 'Incorrect password' : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final appState = Provider.of<AppState>(context, listen: false);
                final userId = appState.currentUser?.id ?? '';
                final isValid =
                    await AuthService.verifyPin(userId, controller.text);
                if (isValid) {
                  confirmed = true;
                  Navigator.pop(context, true);
                } else {
                  setState(() => isError = true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete My Account'),
            ),
          ],
        ),
      ),
    );

    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentUser = appState.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: HavenColors.dark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccounts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final user = _accounts[index];
                final canDelete = _canDelete(user, currentUser);
                final isSelf = user.id == currentUser.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelf
                          ? HavenColors.green.withValues(alpha: 0.15)
                          : Colors.grey.shade200,
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isSelf ? HavenColors.green : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Text(
                        '${_getRoleName(user.role)}${isSelf ? ' (You)' : ''}'),
                    trailing: canDelete
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteAccount(user, currentUser),
                          )
                        : const Icon(Icons.lock_outline,
                            color: Colors.grey, size: 18),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadAccounts,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
        backgroundColor: HavenColors.green,
      ),
    );
  }
}
