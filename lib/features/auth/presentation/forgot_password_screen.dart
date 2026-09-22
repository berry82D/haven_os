// lib/features/auth/presentation/forgot_password_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haven_os/core/constants/colors.dart';
import 'package:haven_os/services/firebase_auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  Future<bool> _existsInLegacyAccounts(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('registered_users');
      if (raw == null) return false;
      final List users = jsonDecode(raw);
      return users.any((u) =>
          (u['email']?.toString().toLowerCase() ?? '') == email.toLowerCase());
    } catch (_) {
      return false;
    }
  }

  Future<void> _sendResetLink() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuthService().sendPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _sent = true;
      });
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // No Firebase account yet — could be a real account that just
        // hasn't been migrated from the old local system (that happens
        // automatically the next time they sign in normally with their
        // existing username and password).
        final existsLocally = await _existsInLegacyAccounts(email);
        if (!mounted) return;
        setState(() => _isLoading = false);
        if (existsLocally) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "This account hasn't been activated for email recovery yet. "
                'Please sign in once with your username and password first, '
                'then try this again.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 6),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No account found for that email.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Reset Password'),
          backgroundColor: Colors.teal.shade700),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Icon(
              _sent ? Icons.mark_email_read : Icons.lock_reset,
              size: 64,
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            Text(
              _sent ? 'Check Your Email' : 'Forgot Password?',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _sent
                  ? 'We sent a password reset link to ${_emailCtrl.text.trim()}. '
                      'Open it on this device or any browser to set a new '
                      'password, then come back and sign in.'
                  : "Enter the email on your account and we'll send you a "
                      'link to reset your password.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (!_sent) ...[
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendResetLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Send Reset Link', style: TextStyle(fontSize: 18)),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HavenColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Sign In', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _sendResetLink,
                child: const Text("Didn't get it? Send again"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
