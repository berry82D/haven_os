import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class AddEmailRecoveryDialog extends StatefulWidget {
  final Map<String, dynamic> legacyUser;
  final String password;
  final String username;
  const AddEmailRecoveryDialog({required this.legacyUser, required this.password, required this.username, super.key});
  @override
  State<AddEmailRecoveryDialog> createState() => _AddEmailRecoveryDialogState();
}

class _AddEmailRecoveryDialogState extends State<AddEmailRecoveryDialog> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _upgrade() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@') ||!email.contains('.')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final fbUser = await FirebaseAuthService().createAccount(email, widget.password, widget.username, signOutAfter: false);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('registered_users')?? '[]';
      final List list = List<Map<String, dynamic>>.from(jsonDecode(raw));
      final idx = list.indexWhere((u) => (u['username']??'').toString().toLowerCase() == widget.username.toLowerCase());
      if (idx!= -1) {
        list[idx]['email'] = email;
        list[idx]['firebaseUid'] = fbUser.uid;
        list[idx]['emailVerified'] = false;
        await prefs.setString('registered_users', jsonEncode(list));
      }
      if (mounted) Navigator.pop(context, fbUser);
    } on fb.FirebaseAuthException catch (e) {
      setState(() => _error = e.message?? e.code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add email for recovery'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your account was created before email recovery was available.'),
            const SizedBox(height: 8),
            Text('Add an email now to enable password reset and keep your farm data safe.', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: InputDecoration(labelText: 'Email for recovery', hintText: 'you@example.com', prefixIcon: const Icon(Icons.email_outlined), errorText: _error, border: const OutlineInputBorder()),
              onSubmitted: (_) => _upgrade(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _loading? null : () => Navigator.pop(context), child: const Text('Later')),
        ElevatedButton(onPressed: _loading? null : _upgrade, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white), child: _loading? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add & Verify')),
      ],
    );
  }
}
