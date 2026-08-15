import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/models/user_account.dart';
import 'package:haven_os/services/auth_service.dart';
import 'package:haven_os/services/app_state.dart';
import 'package:haven_os/features/auth/presentation/account_selector.dart';
import 'package:haven_os/features/auth/presentation/create_account_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String _error = '';
  bool _isLoading = true;
  UserAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialState() async {
    try {
      final accounts = await AuthService.loadAccounts();
      if (!mounted) return;

      if (accounts.isEmpty) {
        // No accounts → go to create account screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
        );
        return;
      }

      final currentUserId = await AuthService.loadCurrentUserId();
      if (currentUserId == null || currentUserId.isEmpty) {
        // No user selected → show account selector
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountSelector()),
        );
        return;
      }

      final user = await AuthService.getCurrentUser();
      if (user != null) {
        // User exists → show password field
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      } else {
        // User ID found but user not loaded (shouldn't happen) → show selector
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountSelector()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _verifyPassword(String password) async {
    final userId = await AuthService.loadCurrentUserId();
    if (userId == null || userId.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountSelector()),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    final isValid = await AuthService.verifyPin(userId, password);

    setState(() => _isLoading = false);

    if (isValid) {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setCurrentUser(user);
        appState.setPinVerified(true);
        _passwordController.clear();

        // ✅ Use pushReplacementNamed – ensure '/home' is defined in main.dart
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      final remaining = await AuthService.getRemainingAttempts(userId);
      final lockout = await AuthService.getLockoutRemaining(userId);
      String msg = 'Incorrect password.';
      if (lockout != null) {
        msg = 'Too many attempts. Try again in ${lockout.inMinutes} minutes.';
      } else if (remaining > 0) {
        msg += ' $remaining attempts remaining.';
      }
      setState(() {
        _error = msg;
        _passwordController.clear();
      });
    }
  }

  void _goToAccountSelector() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AccountSelector()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: HavenColors.cream,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return const SizedBox();
    }

    return Scaffold(
      backgroundColor: HavenColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: HavenColors.green.withValues(alpha: 0.12),
                    child: Text(
                      _currentUser!.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: HavenColors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome back, ${_currentUser!.name}!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: HavenColors.dark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your password to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: HavenColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: HavenColors.cream,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordController.text.isNotEmpty
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: HavenColors.muted,
                        ),
                        onPressed: () {
                          setState(() {});
                        },
                      ),
                      errorText: _error.isNotEmpty ? _error : null,
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _verifyPassword(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_passwordController.text.isNotEmpty) {
                                _verifyPassword(_passwordController.text);
                              } else {
                                setState(() =>
                                    _error = 'Please enter your password');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HavenColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _goToAccountSelector,
                        child: const Text('Switch account'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          // Use push so back button returns to sign-in
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreateAccountScreen()),
                          );
                        },
                        child: const Text('Create new account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
