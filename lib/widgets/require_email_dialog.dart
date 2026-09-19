import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';

class RequireEmailDialog {
  static Future<void> checkAndPrompt(BuildContext context) async {
    try {
      final appState = context.read<AppState>();
      final currentUser = appState.currentUser;
      if (currentUser == null) return;

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('registered_users');
      if (raw == null) return;
      final List users = jsonDecode(raw);

      Map<String, dynamic>? matched;
      int idx = -1;
      for (int i = 0; i < users.length; i++) {
        final u = users[i] as Map<String, dynamic>;
        if ((u['username']?.toString().toLowerCase()?? '') == currentUser.name.toLowerCase() ||
            (u['id']?.toString()?? '') == currentUser.id) {
          matched = u;
          idx = i;
          break;
        }
      }
      if (matched == null) return;
      final email = (matched['email']?.toString()?? '').trim();
      if (email.isNotEmpty && email.contains('@')) return; // already has email

      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _RequireEmailPopup(userIndex: idx, username: matched!['username']?.toString()?? currentUser.name),
      );
    } catch (e) {
      debugPrint('RequireEmailDialog error: $e');
    }
  }
}

class _RequireEmailPopup extends StatefulWidget {
  final int userIndex;
  final String username;
  const _RequireEmailPopup({required this.userIndex, required this.username});
  @override
  State<_RequireEmailPopup> createState() => _RequireEmailPopupState();
}

class _RequireEmailPopupState extends State<_RequireEmailPopup> {
  final _emailController = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final email = _emailController.text.trim().toLowerCase();
    if (!email.contains('@') ||!email.contains('.')) {
      setState(() => _error = 'Enter valid email');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('registered_users')!;
      final List users = jsonDecode(raw);
      users[widget.userIndex]['email'] = email;
      users[widget.userIndex]['emailVerified'] = false;
      await prefs.setString('registered_users', jsonEncode(users));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email saved for ${widget.username} - Your data is now protected')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Secure Your Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Account "${widget.username}" has no email. Add email so you won\'t lose your data if you change phones.'),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: 'Email for recovery', errorText: _error, border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.email)),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _saving? null : () => Navigator.pop(context), child: const Text('Later')),
        ElevatedButton(onPressed: _saving? null : _save, child: _saving? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Save Email')),
      ],
    );
  }
}
