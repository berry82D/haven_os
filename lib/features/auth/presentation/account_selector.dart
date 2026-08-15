import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/services/auth_service.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/features/auth/presentation/sign_in_screen.dart';
import 'package:haven_os/features/auth/presentation/create_account_screen.dart';

class AccountSelector extends StatefulWidget {
  const AccountSelector({super.key});

  @override
  State<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends State<AccountSelector> {
  late Future<List<UserAccount>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _accountsFuture = AuthService.loadAccounts();
  }

  Future<void> _selectAccount(UserAccount account) async {
    // Record which account was picked.
    await AuthService.setCurrentUser(account.id);

    if (!mounted) return;

    if (account.hasPin) {
      // Go back to SignInScreen, which will detect the current user
      // has a PIN and show the password-entry form for them.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    } else {
      // No PIN on this account — log straight in.
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setCurrentUser(account);
      appState.setPinVerified(true);
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  String _roleLabel(UserAccount account) {
    switch (account.role) {
      case UserRole.administrator:
        return 'Parent';
      case UserRole.adult:
        return 'Parent';
      case UserRole.teen:
        return 'Teen';
      case UserRole.child:
        return 'Child';
    }
  }

  IconData _roleIcon(UserAccount account) {
    switch (account.role) {
      case UserRole.administrator:
      case UserRole.adult:
        return Icons.person;
      case UserRole.teen:
        return Icons.person_outline;
      case UserRole.child:
        return Icons.child_care;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HavenColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '👋 Choose Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: HavenColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select an account to continue',
                style: TextStyle(fontSize: 14, color: HavenColors.muted),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: FutureBuilder<List<UserAccount>>(
                  future: _accountsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final accounts = snapshot.data ?? [];
                    if (accounts.isEmpty) {
                      return Center(
                        child: Text(
                          'No accounts yet.',
                          style: TextStyle(color: HavenColors.muted),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        return _AccountTile(
                          account: account,
                          roleLabel: _roleLabel(account),
                          roleIcon: _roleIcon(account),
                          onTap: () => _selectAccount(account),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateAccountScreen()),
                    );
                  },
                  child: const Text(
                    '+ Add another account',
                    style: TextStyle(
                      color: HavenColors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final UserAccount account;
  final String roleLabel;
  final IconData roleIcon;
  final VoidCallback onTap;

  const _AccountTile({
    required this.account,
    required this.roleLabel,
    required this.roleIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            CircleAvatar(
              radius: 24,
              backgroundColor: HavenColors.green.withValues(alpha: 0.15),
              child: Text(
                account.name.isNotEmpty ? account.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: HavenColors.green,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: HavenColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(roleIcon, size: 14, color: HavenColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        roleLabel,
                        style:
                            TextStyle(fontSize: 13, color: HavenColors.muted),
                      ),
                      if (account.hasPin) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock,
                                  size: 12, color: Colors.amber.shade800),
                              const SizedBox(width: 3),
                              Text(
                                'PIN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: HavenColors.muted),
          ],
        ),
      ),
    );
  }
}
