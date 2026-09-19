import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haven_os/core/constants/colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _emailVerified = false;
  Map<String, dynamic>? _foundUser;
  int _foundUserIndex = -1;

  Future<void> _verifyEmail() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty ||!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid email'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('registered_users');
      if (raw == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No accounts found'), backgroundColor: Colors.red));
        return;
      }
      final List users = jsonDecode(raw);
      for (int i = 0; i < users.length; i++) {
        final u = users[i] as Map<String, dynamic>;
        if ((u['email']?.toString().toLowerCase()?? '') == email) {
          setState(() {
            _foundUser = u;
            _foundUserIndex = i;
            _emailVerified = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account found: ${u['username']} - Enter new password'), backgroundColor: HavenColors.green));
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No account with that email'), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_newPassCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 chars'), backgroundColor: Colors.red));
      return;
    }
    if (_newPassCtrl.text!= _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('registered_users')!;
      final List users = jsonDecode(raw);
      final salt = DateTime.now().millisecondsSinceEpoch.toString();
      final hash = sha256.convert(utf8.encode('${_newPassCtrl.text}$salt')).toString();
      users[_foundUserIndex]['passwordHash'] = hash;
      users[_foundUserIndex]['salt'] = salt;
      await prefs.setString('registered_users', jsonEncode(users));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset for ${_foundUser!['username']}'), backgroundColor: HavenColors.green));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password'), backgroundColor: Colors.teal.shade700),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.lock_reset, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            const Text('Forgot Password?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(_emailVerified? 'Set new password for ${_foundUser!['username']}' : 'Enter your email to find your account', style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 40),
            if (!_emailVerified)...[
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _isLoading? null : _verifyEmail, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Find Account', style: TextStyle(fontSize: 18))),
            ] else...[
              TextFormField(controller: _newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 16),
              TextFormField(controller: _confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline))),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _isLoading? null : _resetPassword, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Reset Password', style: TextStyle(fontSize: 18))),
            ],
          ],
        ),
      ),
    );
  }
}
