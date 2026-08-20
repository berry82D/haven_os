// lib/features/auth/presentation/create_account_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/services/auth_service.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/features/auth/widgets/password_strength_indicator.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  AccountType _selectedType = AccountType.adult;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late final Future<List<UserAccount>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _accountsFuture = AuthService.loadAccounts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  UserRole _roleForType(AccountType type, bool isFirst) {
    if (isFirst) return UserRole.administrator;
    switch (type) {
      case AccountType.parent:
        return UserRole.administrator;
      case AccountType.child:
        return UserRole.child;
      case AccountType.teen:
        return UserRole.teen;
      case AccountType.adult:
        return UserRole.adult;
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final existing = await _accountsFuture;
      final isFirst = existing.isEmpty;
      final role = _roleForType(_selectedType, isFirst);

      final user = await AuthService.createAccount(
        name: _nameController.text.trim(),
        householdId: 'default',
        type: isFirst ? AccountType.parent : _selectedType,
        role: role,
        hasPin: true,
        autoLogin: true,
      );

      await AuthService.setPin(user.id, _passwordController.text.trim());

      final appState = Provider.of<AppState>(context, listen: false);
      appState.setCurrentUser(user);
      appState.setPinVerified(true);

      // ✅ FIX: Replace the current route with /home so back button doesn't return to this screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HavenColors.cream,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: HavenColors.dark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Set up your account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a name and a strong password.',
                  style: TextStyle(color: HavenColors.muted),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<UserAccount>>(
                  future: _accountsFuture,
                  builder: (context, snapshot) {
                    final hasExisting =
                        snapshot.hasData && snapshot.data!.isNotEmpty;
                    final List<AccountType> allowedTypes = hasExisting
                        ? [
                            AccountType.adult,
                            AccountType.teen,
                            AccountType.child
                          ]
                        : [AccountType.parent];
                    return DropdownButtonFormField<AccountType>(
                      initialValue: allowedTypes.contains(_selectedType)
                          ? _selectedType
                          : allowedTypes.first,
                      decoration: const InputDecoration(
                        labelText: 'Account Type',
                        border: OutlineInputBorder(),
                      ),
                      items: allowedTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedType = val!),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText:
                        'Password (8+ chars, uppercase, number, special)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    final result =
                        PasswordStrengthIndicator.evaluatePassword(v);
                    if (result.rulesMet < 4) {
                      return 'Password must have:\n- 8+ characters\n- Uppercase\n- Number\n- Special character';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 4),
                PasswordStrengthIndicator(password: _passwordController.text),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Please confirm password';
                    if (v != _passwordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HavenColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Account',
                          style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
