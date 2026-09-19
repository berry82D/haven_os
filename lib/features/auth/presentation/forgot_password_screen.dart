// lib/features/auth/presentation/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _userVerified = false;

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Must be at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value!= _newPasswordCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _verifyUser() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your username'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('registered_users');
    List<Map<String, dynamic>> users = [];
    if (usersJson!= null) {
      users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
    }
    final user = users.where((u) => u['username'] == username).toList();
    setState(() => _isLoading = false);
    if (user.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username not found'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      _userVerified = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User  found — enter new password')),
    );
  }

  Future<void> _resetPassword() async {
    final username = _usernameCtrl.text.trim();
    final newPass = _newPasswordCtrl.text.trim();

    if (_validatePassword(newPass)!= null || _validateConfirm(_confirmCtrl.text)!= null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix errors above'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('registered_users');
    List<Map<String, dynamic>> users = [];
    if (usersJson!= null) {
      users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
    }

    final idx = users.indexWhere((u) => u['username'] == username);
    if (idx == -1) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found'), backgroundColor: Colors.red),
      );
      return;
    }

    // Generate new salt + hash
    final newSalt = DateTime.now().millisecondsSinceEpoch.toString();
    final newHash = _hashPassword(newPass, newSalt);

    users[idx]['salt'] = newSalt;
    users[idx]['passwordHash'] = newHash;

    await prefs.setString('registered_users', jsonEncode(users));
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset! Please sign in.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.teal.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.lock_reset, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            const Text('Forgot Password?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Enter username to reset your password.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 40),
            TextFormField(
              controller: _usernameCtrl,
              enabled:!_userVerified,
              decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 16),
            if (!_userVerified)
              ElevatedButton(
                onPressed: _isLoading? null : _verifyUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                   ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify Username', style: TextStyle(fontSize: 18)),
              ),
            if (_userVerified)...[
              const Divider(height: 32),
              const Text('Set New Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordCtrl,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew =!_obscureNew),
                  ),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm =!_obscureConfirm),
                  ),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateConfirm,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                   ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Reset Password', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  _userVerified = false;
                  _usernameCtrl.clear();
                  _newPasswordCtrl.clear();
                  _confirmCtrl.clear();
                }),
                child: const Text('Start Over'),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
